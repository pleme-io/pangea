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
        # Carbon monitor Lambda function code generator
        module CarbonMonitor
          def generate_carbon_monitor_code(input)
            <<~PYTHON
              import json
              import boto3
              import os
              import time
              from datetime import datetime
              import requests

              dynamodb = boto3.resource('dynamodb')
              cloudwatch = boto3.client('cloudwatch')
              ec2 = boto3.client('ec2')

              CARBON_TABLE = os.environ['CARBON_TABLE']
              ALLOWED_REGIONS = os.environ['ALLOWED_REGIONS'].split(',')
              RENEWABLE_MINIMUM = int(os.environ['RENEWABLE_MINIMUM'])

              # Regional carbon data (gCO2/kWh)
              CARBON_BASELINE = {
                  'us-east-1': 400, 'us-east-2': 450, 'us-west-1': 250, 'us-west-2': 50,
                  'eu-central-1': 350, 'eu-west-1': 80, 'eu-north-1': 40, 'ca-central-1': 30,
                  'ap-southeast-1': 600, 'ap-southeast-2': 700, 'sa-east-1': 100
              }

              def handler(event, context):
                  carbon_table = dynamodb.Table(CARBON_TABLE)
                  carbon_data = collect_regional_carbon_data()
                  store_carbon_data(carbon_table, carbon_data)
                  fleet_metrics = calculate_fleet_carbon_metrics(carbon_data)
                  emit_carbon_metrics(fleet_metrics)
                  return {
                      'statusCode': 200,
                      'body': json.dumps({
                          'regions_monitored': len(carbon_data),
                          'average_carbon_intensity': fleet_metrics['average_intensity'],
                          'renewable_percentage': fleet_metrics['renewable_percentage']
                      })
                  }

              def collect_regional_carbon_data():
                  carbon_data = {}
                  current_time = int(time.time())
                  for region in ALLOWED_REGIONS:
                      intensity = get_carbon_intensity(region)
                      renewable_pct = get_renewable_percentage(region, intensity)
                      carbon_data[region] = {
                          'carbon_intensity': intensity, 'renewable_percentage': renewable_pct,
                          'timestamp': current_time, 'spot_price': get_spot_price(region),
                          'instance_count': count_instances(region)
                      }
                  return carbon_data

              def get_carbon_intensity(region):
                  hour = datetime.now().hour
                  base = CARBON_BASELINE.get(region, 400)
                  multiplier = 1.3 if 9 <= hour <= 17 else (0.7 if 0 <= hour <= 6 else 1.0)
                  month = datetime.now().month
                  seasonal = 1.2 if month in [12, 1, 2] else (1.1 if month in [6, 7, 8] else 1.0)
                  return int(base * multiplier * seasonal)

              def get_renewable_percentage(region, intensity):
                  if intensity < 100: return 85 + (100 - intensity) / 10
                  elif intensity < 200: return 60 + (200 - intensity) / 5
                  elif intensity < 400: return 30 + (400 - intensity) / 10
                  else: return max(5, 30 - (intensity - 400) / 20)

              def get_spot_price(region):
                  try:
                      ec2_regional = boto3.client('ec2', region_name=region)
                      response = ec2_regional.describe_spot_price_history(
                          InstanceTypes=['t3.large'], MaxResults=1, ProductDescriptions=['Linux/UNIX'])
                      if response['SpotPriceHistory']:
                          return float(response['SpotPriceHistory'][0]['SpotPrice'])
                  except: pass
                  return 0.05

              def count_instances(region):
                  try:
                      ec2_regional = boto3.client('ec2', region_name=region)
                      response = ec2_regional.describe_instances(Filters=[
                          {'Name': 'instance-state-name', 'Values': ['running']},
                          {'Name': 'tag:Component', 'Values': ['spot-carbon-optimizer']}])
                      return sum(len(r['Instances']) for r in response['Reservations'])
                  except: return 0

              def store_carbon_data(table, carbon_data):
                  current_time = int(time.time())
                  expiration = current_time + 86400
                  for region, data in carbon_data.items():
                      table.put_item(Item={
                          'region': region, 'timestamp': current_time,
                          'carbon_intensity': data['carbon_intensity'],
                          'renewable_percentage': data['renewable_percentage'],
                          'spot_price': str(data['spot_price']),
                          'instance_count': data['instance_count'], 'expiration': expiration})

              def calculate_fleet_carbon_metrics(carbon_data):
                  total_instances = sum(d['instance_count'] for d in carbon_data.values())
                  if total_instances == 0:
                      return {'average_intensity': 0, 'renewable_percentage': 0,
                              'carbon_emissions': 0, 'low_carbon_instances': 0}
                  weighted_intensity = sum(
                      d['carbon_intensity'] * d['instance_count'] for d in carbon_data.values()) / total_instances
                  weighted_renewable = sum(
                      d['renewable_percentage'] * d['instance_count'] for d in carbon_data.values()) / total_instances
                  low_carbon_instances = sum(
                      d['instance_count'] for d in carbon_data.values() if d['carbon_intensity'] < 200)
                  carbon_emissions = (50 * 1 * weighted_intensity) / 1000
                  return {'average_intensity': weighted_intensity, 'renewable_percentage': weighted_renewable,
                          'carbon_emissions': carbon_emissions, 'low_carbon_instances': low_carbon_instances,
                          'total_instances': total_instances}

              def emit_carbon_metrics(metrics):
                  namespace = f"SpotCarbonOptimizer/{os.environ.get('COMPONENT_NAME', 'default')}"
                  metric_data = [
                      {'MetricName': 'AverageCarbonIntensity', 'Value': metrics['average_intensity'], 'Unit': 'None'},
                      {'MetricName': 'RenewablePercentage', 'Value': metrics['renewable_percentage'], 'Unit': 'Percent'},
                      {'MetricName': 'CarbonEmissions', 'Value': metrics['carbon_emissions'], 'Unit': 'None'},
                      {'MetricName': 'LowCarbonInstances', 'Value': metrics['low_carbon_instances'], 'Unit': 'Count'},
                      {'MetricName': 'TotalFleetCapacity', 'Value': metrics['total_instances'], 'Unit': 'Count'}]
                  carbon_data = collect_regional_carbon_data()
                  for region, data in carbon_data.items():
                      metric_data.extend([
                          {'MetricName': 'RegionalCarbonIntensity', 'Value': data['carbon_intensity'],
                           'Unit': 'None', 'Dimensions': [{'Name': 'Region', 'Value': region}]},
                          {'MetricName': 'RegionalInstanceCount', 'Value': data['instance_count'],
                           'Unit': 'Count', 'Dimensions': [{'Name': 'Region', 'Value': region}]}])
                  cloudwatch.put_metric_data(Namespace=namespace, MetricData=metric_data)
            PYTHON
          end
        end
      end
    end
  end
end
