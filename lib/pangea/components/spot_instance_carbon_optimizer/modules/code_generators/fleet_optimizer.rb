# frozen_string_literal: true
# Copyright 2025 The Pangea Authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

module Pangea
  module Components
    module SpotInstanceCarbonOptimizer
      module CodeGenerators
        # Fleet optimizer Lambda function code generator
        module FleetOptimizer
          def generate_fleet_optimizer_code(input)
            <<~PYTHON
              import json, boto3, os
              from datetime import datetime, timedelta
              ec2, dynamodb, cloudwatch = boto3.client('ec2'), boto3.resource('dynamodb'), boto3.client('cloudwatch')
              FLEET_STATE_TABLE, CARBON_TABLE = os.environ['FLEET_STATE_TABLE'], os.environ['CARBON_TABLE']
              OPTIMIZATION_STRATEGY, CARBON_THRESHOLD = os.environ['OPTIMIZATION_STRATEGY'], int(os.environ['CARBON_THRESHOLD'])
              TARGET_CAPACITY, ALLOWED_REGIONS = int(os.environ['TARGET_CAPACITY']), os.environ['ALLOWED_REGIONS'].split(',')
              PREFERRED_REGIONS = os.environ['PREFERRED_REGIONS'].split(',')

              def handler(event, context):
                  fleet_table, carbon_table = dynamodb.Table(FLEET_STATE_TABLE), dynamodb.Table(CARBON_TABLE)
                  fleet_state, carbon_data = get_fleet_state(fleet_table), get_latest_carbon_data(carbon_table)
                  optimal_distribution = calculate_optimal_distribution(fleet_state, carbon_data)
                  applied_changes = apply_fleet_optimizations(fleet_state, optimal_distribution)
                  update_fleet_state(fleet_table, applied_changes)
                  emit_optimization_metrics(applied_changes)
                  return {'statusCode': 200, 'body': json.dumps({'optimizations_applied': len(applied_changes), 'new_distribution': optimal_distribution})}

              def get_fleet_state(table):
                  fleet_state = {}
                  for region in ALLOWED_REGIONS:
                      try:
                          ec2_regional = boto3.client('ec2', region_name=region)
                          response = ec2_regional.describe_spot_fleet_requests(Filters=[{'Name': 'tag:Component', 'Values': ['spot-carbon-optimizer']}])
                          for fleet in response['SpotFleetRequestConfigs']:
                              if fleet['SpotFleetRequestState'] == 'active':
                                  fleet_state[region] = {'fleet_id': fleet['SpotFleetRequestId'], 'current_capacity': fleet['SpotFleetRequestConfig']['TargetCapacity'],
                                      'fulfilled_capacity': fleet.get('FulfilledCapacity', 0), 'instances': get_fleet_instances(ec2_regional, fleet['SpotFleetRequestId'])}
                      except Exception as e: print(f"Error getting fleet state for {region}: {str(e)}")
                  return fleet_state

              def get_fleet_instances(ec2_client, fleet_id):
                  try: return ec2_client.describe_spot_fleet_instances(SpotFleetRequestId=fleet_id).get('ActiveInstances', [])
                  except: return []

              def get_latest_carbon_data(table):
                  carbon_data, current_time, lookback = {}, int(datetime.now().timestamp()), int(datetime.now().timestamp()) - 900
                  for region in ALLOWED_REGIONS:
                      try:
                          response = table.query(KeyConditionExpression='region = :region AND #ts > :ts', ExpressionAttributeNames={'#ts': 'timestamp'},
                              ExpressionAttributeValues={':region': region, ':ts': lookback}, ScanIndexForward=False, Limit=1)
                          if response['Items']:
                              item = response['Items'][0]
                              carbon_data[region] = {'carbon_intensity': item['carbon_intensity'], 'renewable_percentage': item['renewable_percentage'], 'spot_price': float(item.get('spot_price', 0.05))}
                      except Exception as e:
                          print(f"Error getting carbon data for {region}: {str(e)}")
                          carbon_data[region] = {'carbon_intensity': 400, 'renewable_percentage': 30, 'spot_price': 0.05}
                  return carbon_data

              def calculate_optimal_distribution(fleet_state, carbon_data):
                  strategies = {'carbon_first': optimize_for_carbon, 'cost_first': optimize_for_cost, 'renewable_only': optimize_for_renewable, 'follow_the_sun': optimize_follow_sun}
                  return strategies.get(OPTIMIZATION_STRATEGY, optimize_balanced)(carbon_data)

              def optimize_for_carbon(carbon_data):
                  sorted_regions, distribution, remaining = sorted(carbon_data.items(), key=lambda x: x[1]['carbon_intensity']), {}, TARGET_CAPACITY
                  for region, data in sorted_regions:
                      if data['carbon_intensity'] <= CARBON_THRESHOLD:
                          allocation = min(int(TARGET_CAPACITY * (1000 / data['carbon_intensity']) / 100), remaining)
                          distribution[region], remaining = allocation, remaining - allocation
                  if remaining > 0:
                      for region in PREFERRED_REGIONS:
                          if region in distribution: distribution[region] += remaining; break
                  return distribution

              def optimize_for_cost(carbon_data):
                  sorted_regions, distribution, remaining = sorted(carbon_data.items(), key=lambda x: x[1]['spot_price']), {}, TARGET_CAPACITY
                  for region, data in sorted_regions:
                      if data['carbon_intensity'] <= CARBON_THRESHOLD * 2:
                          allocation = min(int(TARGET_CAPACITY / len(ALLOWED_REGIONS)), remaining)
                          distribution[region], remaining = allocation, remaining - allocation
                  return distribution

              def optimize_for_renewable(carbon_data):
                  return {region: int(TARGET_CAPACITY / 3) for region, data in carbon_data.items() if data['renewable_percentage'] >= 70}

              def optimize_follow_sun(carbon_data):
                  current_hour = datetime.now().hour
                  tz = {'us-west-2': -8, 'us-west-1': -8, 'us-east-1': -5, 'us-east-2': -5, 'eu-west-1': 0, 'eu-central-1': 1, 'eu-north-1': 1, 'ap-southeast-1': 8, 'ap-southeast-2': 10, 'sa-east-1': -3, 'ca-central-1': -5}
                  distribution = {}
                  for region, data in carbon_data.items():
                      local_hour = (current_hour + tz.get(region, 0)) % 24
                      if data['renewable_percentage'] > 40: distribution[region] = int(TARGET_CAPACITY * (2 if 8 <= local_hour <= 18 else 1) / 10)
                  return distribution

              def optimize_balanced(carbon_data):
                  distribution = {}
                  for region, data in carbon_data.items():
                      score = (1000 / data['carbon_intensity']) * 0.5 + (1 / data['spot_price']) * 0.3 + (data['renewable_percentage'] / 100) * 0.2
                      if score > 5: distribution[region] = int(TARGET_CAPACITY * score / 50)
                  if sum(distribution.values()) < TARGET_CAPACITY:
                      for region in PREFERRED_REGIONS:
                          if region in distribution: distribution[region] += TARGET_CAPACITY - sum(distribution.values()); break
                  return distribution

              def apply_fleet_optimizations(fleet_state, optimal_distribution):
                  changes = []
                  for region, target in optimal_distribution.items():
                      current = fleet_state.get(region, {}).get('current_capacity', 0)
                      if target != current:
                          try:
                              ec2_regional = boto3.client('ec2', region_name=region)
                              if region in fleet_state and fleet_state[region]['fleet_id']:
                                  fleet_id = fleet_state[region]['fleet_id']
                                  ec2_regional.modify_spot_fleet_request(SpotFleetRequestId=fleet_id, TargetCapacity=target)
                                  changes.append({'region': region, 'action': 'modified', 'fleet_id': fleet_id, 'old_capacity': current, 'new_capacity': target})
                              else: changes.append({'region': region, 'action': 'would_create', 'new_capacity': target})
                          except Exception as e: print(f"Error optimizing fleet in {region}: {str(e)}")
                  return changes

              def update_fleet_state(table, changes):
                  for c in changes:
                      if c['action'] in ['modified', 'created']:
                          table.put_item(Item={'fleet_id': c.get('fleet_id', f"pending-{c['region']}"), 'region': c['region'], 'capacity': c['new_capacity'], 'last_updated': int(datetime.now().timestamp()), 'optimization_strategy': OPTIMIZATION_STRATEGY})

              def emit_optimization_metrics(changes):
                  ns = f"SpotCarbonOptimizer/{os.environ.get('COMPONENT_NAME', 'default')}"
                  added = sum(c['new_capacity'] - c.get('old_capacity', 0) for c in changes if c['new_capacity'] > c.get('old_capacity', 0))
                  removed = sum(c.get('old_capacity', 0) - c['new_capacity'] for c in changes if c.get('old_capacity', 0) > c['new_capacity'])
                  cloudwatch.put_metric_data(Namespace=ns, MetricData=[{'MetricName': 'OptimizationRuns', 'Value': 1, 'Unit': 'Count'}, {'MetricName': 'FleetModifications', 'Value': len(changes), 'Unit': 'Count'}, {'MetricName': 'CapacityAdded', 'Value': added, 'Unit': 'Count'}, {'MetricName': 'CapacityRemoved', 'Value': removed, 'Unit': 'Count'}])
            PYTHON
          end
        end
      end
    end
  end
end
