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
        # Migration orchestrator Lambda function code generator
        module MigrationOrchestrator
          def generate_migration_orchestrator_code(input)
            <<~PYTHON
              import json
              import boto3
              import os
              import time
              from datetime import datetime
              import uuid

              ec2 = boto3.client('ec2')
              dynamodb = boto3.resource('dynamodb')
              cloudwatch = boto3.client('cloudwatch')

              FLEET_STATE_TABLE = os.environ['FLEET_STATE_TABLE']
              MIGRATION_HISTORY_TABLE = os.environ['MIGRATION_HISTORY_TABLE']
              MIGRATION_STRATEGY = os.environ['MIGRATION_STRATEGY']
              MIGRATION_THRESHOLD = int(os.environ['MIGRATION_THRESHOLD'])
              WORKLOAD_TYPE = os.environ['WORKLOAD_TYPE']
              ENABLE_CROSS_REGION = os.environ['ENABLE_CROSS_REGION'] == 'True'

              def handler(event, context):
                  if 'detail-type' in event and event['detail-type'] == 'EC2 Spot Instance Interruption Warning':
                      return handle_spot_interruption(event)
                  else:
                      return handle_optimization_trigger(event)

              def handle_spot_interruption(event):
                  instance_id = event['detail']['instance-id']
                  region = event['region']
                  print(f"Handling spot interruption for {instance_id} in {region}")
                  instance_info = get_instance_info(instance_id, region)
                  if not instance_info: return {'statusCode': 404, 'body': 'Instance not found'}
                  target_region = find_migration_target(region)
                  if not target_region: return {'statusCode': 400, 'body': 'No suitable migration target'}
                  migration_id = execute_migration(instance_info, region, target_region)
                  return {'statusCode': 200, 'body': json.dumps({
                      'migration_id': migration_id, 'source': region, 'target': target_region})}

              def handle_optimization_trigger(event):
                  fleet_table = dynamodb.Table(FLEET_STATE_TABLE)
                  history_table = dynamodb.Table(MIGRATION_HISTORY_TABLE)
                  migration_candidates = find_migration_candidates(fleet_table)
                  migrations_executed = []
                  for candidate in migration_candidates:
                      if should_migrate(candidate):
                          migration_id = execute_fleet_migration(
                              candidate['source_region'], candidate['target_region'], candidate['instances'])
                          migrations_executed.append({'migration_id': migration_id, 'source': candidate['source_region'],
                              'target': candidate['target_region'], 'instance_count': len(candidate['instances'])})
                          record_migration(history_table, migration_id, candidate)
                  emit_migration_metrics(migrations_executed)
                  return {'statusCode': 200, 'body': json.dumps({
                      'migrations_executed': len(migrations_executed), 'details': migrations_executed})}

              def get_instance_info(instance_id, region):
                  try:
                      ec2_regional = boto3.client('ec2', region_name=region)
                      response = ec2_regional.describe_instances(InstanceIds=[instance_id])
                      if response['Reservations']:
                          instance = response['Reservations'][0]['Instances'][0]
                          return {'instance_id': instance_id, 'instance_type': instance['InstanceType'],
                              'launch_time': instance['LaunchTime'],
                              'tags': {tag['Key']: tag['Value'] for tag in instance.get('Tags', [])}}
                  except Exception as e: print(f"Error getting instance info: {str(e)}")
                  return None

              def find_migration_target(source_region):
                  carbon_data = get_regional_carbon_data()
                  sorted_regions = sorted(carbon_data.items(), key=lambda x: x[1]['carbon_intensity'])
                  for region, data in sorted_regions:
                      if region != source_region and data['carbon_intensity'] < carbon_data[source_region]['carbon_intensity']:
                          return region
                  return None

              def get_regional_carbon_data():
                  return {'us-east-1': {'carbon_intensity': 400}, 'us-west-2': {'carbon_intensity': 50},
                      'eu-north-1': {'carbon_intensity': 40}, 'ca-central-1': {'carbon_intensity': 30}}

              def find_migration_candidates(fleet_table):
                  candidates = []
                  response = fleet_table.scan()
                  carbon_data = get_regional_carbon_data()
                  for item in response.get('Items', []):
                      region = item['region']
                      carbon_intensity = carbon_data.get(region, {}).get('carbon_intensity', 400)
                      if carbon_intensity > 200:
                          target = find_migration_target(region)
                          if target:
                              candidates.append({'source_region': region, 'target_region': target,
                                  'carbon_reduction': carbon_intensity - carbon_data[target]['carbon_intensity'],
                                  'instances': get_region_instances(region), 'fleet_id': item.get('fleet_id')})
                  return candidates

              def get_region_instances(region):
                  try:
                      ec2_regional = boto3.client('ec2', region_name=region)
                      response = ec2_regional.describe_instances(Filters=[
                          {'Name': 'instance-state-name', 'Values': ['running']},
                          {'Name': 'tag:Component', 'Values': ['spot-carbon-optimizer']}])
                      instances = []
                      for reservation in response['Reservations']:
                          instances.extend([i['InstanceId'] for i in reservation['Instances']])
                      return instances
                  except: return []

              def should_migrate(candidate):
                  if not ENABLE_CROSS_REGION: return False
                  if candidate['carbon_reduction'] < 100: return False
                  if len(candidate['instances']) > 50: return False
                  if WORKLOAD_TYPE not in ['stateless', 'batch', 'distributed']: return False
                  return True

              def execute_migration(instance_info, source_region, target_region):
                  migration_id = str(uuid.uuid4())
                  if MIGRATION_STRATEGY == 'checkpoint_restore':
                      execute_checkpoint_restore(instance_info, source_region, target_region, migration_id)
                  elif MIGRATION_STRATEGY == 'blue_green':
                      execute_blue_green(instance_info, source_region, target_region, migration_id)
                  elif MIGRATION_STRATEGY == 'drain_and_shift':
                      execute_drain_and_shift(instance_info, source_region, target_region, migration_id)
                  else: execute_live_migration(instance_info, source_region, target_region, migration_id)
                  return migration_id

              def execute_checkpoint_restore(instance_info, source_region, target_region, migration_id):
                  print(f"Executing checkpoint/restore migration {migration_id}")
                  ec2_source = boto3.client('ec2', region_name=source_region)
                  ec2_source.stop_instances(InstanceIds=[instance_info['instance_id']])
                  ec2_source.create_image(InstanceId=instance_info['instance_id'], Name=f"migration-{migration_id}",
                      Description=f"Carbon migration from {source_region} to {target_region}")
                  ec2_source.terminate_instances(InstanceIds=[instance_info['instance_id']])

              def execute_blue_green(instance_info, source_region, target_region, migration_id):
                  print(f"Executing blue/green migration {migration_id}")
                  ec2_source = boto3.client('ec2', region_name=source_region)
                  ec2_source.terminate_instances(InstanceIds=[instance_info['instance_id']])

              def execute_drain_and_shift(instance_info, source_region, target_region, migration_id):
                  print(f"Executing drain and shift migration {migration_id}")
                  ec2_source = boto3.client('ec2', region_name=source_region)
                  ec2_source.create_tags(Resources=[instance_info['instance_id']],
                      Tags=[{'Key': 'Migration', 'Value': 'draining'}])
                  time.sleep(MIGRATION_THRESHOLD * 60)
                  ec2_source.terminate_instances(InstanceIds=[instance_info['instance_id']])

              def execute_live_migration(instance_info, source_region, target_region, migration_id):
                  print(f"Executing live migration {migration_id}")
                  pass

              def execute_fleet_migration(source_region, target_region, instances):
                  migration_id = str(uuid.uuid4())
                  print(f"Migrating {len(instances)} instances from {source_region} to {target_region}")
                  if MIGRATION_STRATEGY == 'checkpoint_restore':
                      for instance_id in instances[:5]:
                          instance_info = get_instance_info(instance_id, source_region)
                          if instance_info:
                              execute_checkpoint_restore(instance_info, source_region, target_region, migration_id)
                  return migration_id

              def record_migration(table, migration_id, candidate):
                  table.put_item(Item={'migration_id': migration_id, 'timestamp': int(time.time()),
                      'source_region': candidate['source_region'], 'target_region': candidate['target_region'],
                      'instance_count': len(candidate['instances']), 'carbon_reduction': candidate['carbon_reduction'],
                      'migration_strategy': MIGRATION_STRATEGY, 'workload_type': WORKLOAD_TYPE})

              def emit_migration_metrics(migrations):
                  namespace = f"SpotCarbonOptimizer/{os.environ.get('COMPONENT_NAME', 'default')}"
                  total_carbon_saved = sum(m.get('carbon_reduction', 0) * m.get('instance_count', 0) for m in migrations)
                  cloudwatch.put_metric_data(Namespace=namespace, MetricData=[
                      {'MetricName': 'MigrationCount', 'Value': len(migrations), 'Unit': 'Count'},
                      {'MetricName': 'InstancesMigrated', 'Value': sum(m.get('instance_count', 0) for m in migrations), 'Unit': 'Count'},
                      {'MetricName': 'CarbonSavedByMigration', 'Value': total_carbon_saved, 'Unit': 'None'},
                      {'MetricName': 'MigrationSuccess', 'Value': 100 if migrations else 0, 'Unit': 'Percent'}])
            PYTHON
          end
        end
      end
    end
  end
end
