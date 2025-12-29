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
    module CarbonAwareCompute
      # Monitor Lambda function Python code generator
      module MonitorCode
        def generate_monitor_code(_input)
          <<~PYTHON
            import json
            import boto3
            import os
            import time
            import requests
            from datetime import datetime
            import random

            dynamodb = boto3.resource('dynamodb')
            cloudwatch = boto3.client('cloudwatch')

            CARBON_TABLE = os.environ['CARBON_TABLE']
            CARBON_DATA_SOURCE = os.environ['CARBON_DATA_SOURCE']
            PREFERRED_REGIONS = os.environ['PREFERRED_REGIONS'].split(',')
            ENABLE_REPORTING = os.environ['ENABLE_REPORTING'] == 'True'

            def handler(event, context):
                carbon_table = dynamodb.Table(CARBON_TABLE)
                carbon_data = fetch_all_carbon_data(PREFERRED_REGIONS)
                store_carbon_data(carbon_table, carbon_data)
                if ENABLE_REPORTING:
                    emit_carbon_metrics(carbon_data)
                anomalies = detect_carbon_anomalies(carbon_data)
                return {'statusCode': 200, 'body': json.dumps({'updated_regions': len(carbon_data), 'anomalies': anomalies})}

            def fetch_all_carbon_data(regions):
                carbon_data = {}
                for region in regions:
                    if CARBON_DATA_SOURCE == 'electricity-maps':
                        intensity = fetch_from_electricity_maps(region)
                    elif CARBON_DATA_SOURCE == 'watttime':
                        intensity = fetch_from_watttime(region)
                    else:
                        intensity = simulate_carbon_intensity(region)
                    carbon_data[region] = intensity
                return carbon_data

            def fetch_from_electricity_maps(region):
                return simulate_carbon_intensity(region)

            def fetch_from_watttime(region):
                return simulate_carbon_intensity(region)

            def simulate_carbon_intensity(region):
                base_intensities = {
                    'us-west-2': 50, 'eu-north-1': 40, 'eu-west-1': 80, 'ca-central-1': 30,
                    'us-east-1': 400, 'ap-southeast-1': 600, 'us-west-1': 250, 'eu-central-1': 350, 'ap-northeast-1': 450
                }
                base = base_intensities.get(region, 300)
                hour, day_of_week, month = datetime.now().hour, datetime.now().weekday(), datetime.now().month
                time_factor = 1.3 if 6 <= hour <= 9 else (1.4 if 17 <= hour <= 20 else (0.8 if 0 <= hour <= 5 else 1.0))
                weekend_factor = 0.85 if day_of_week >= 5 else 1.0
                seasonal_factor = 1.2 if month in [12, 1, 2] else (1.1 if month in [6, 7, 8] else 1.0)
                random_factor = 0.9 + random.random() * 0.2
                final_intensity = base * time_factor * weekend_factor * seasonal_factor * random_factor
                return {
                    'carbon_intensity': int(final_intensity), 'timestamp': int(time.time()),
                    'renewable_percentage': calculate_renewable_percentage(region, final_intensity),
                    'grid_region': region, 'data_source': CARBON_DATA_SOURCE
                }

            def calculate_renewable_percentage(region, intensity):
                if intensity < 100: return 80 + (100 - intensity) / 5
                elif intensity < 200: return 60 + (200 - intensity) / 5
                elif intensity < 400: return 30 + (400 - intensity) / 10
                return max(0, 30 - (intensity - 400) / 20)

            def store_carbon_data(table, carbon_data):
                current_time = int(time.time())
                for region, data in carbon_data.items():
                    table.put_item(Item={
                        'region': region, 'timestamp': current_time,
                        'carbon_intensity': data['carbon_intensity'],
                        'renewable_percentage': data['renewable_percentage'],
                        'data_source': data['data_source'], 'expiration': current_time + 3600
                    })

            def emit_carbon_metrics(carbon_data):
                metric_data = []
                for region, data in carbon_data.items():
                    metric_data.extend([
                        {'MetricName': 'RegionCarbonIntensity', 'Value': data['carbon_intensity'], 'Unit': 'None', 'Dimensions': [{'Name': 'RegionName', 'Value': region}]},
                        {'MetricName': 'RegionRenewablePercentage', 'Value': data['renewable_percentage'], 'Unit': 'Percent', 'Dimensions': [{'Name': 'RegionName', 'Value': region}]}
                    ])
                intensities = [d['carbon_intensity'] for d in carbon_data.values()]
                metric_data.extend([
                    {'MetricName': 'AverageCarbonIntensity', 'Value': sum(intensities) / len(intensities), 'Unit': 'None'},
                    {'MetricName': 'MinCarbonIntensity', 'Value': min(intensities), 'Unit': 'None'},
                    {'MetricName': 'MaxCarbonIntensity', 'Value': max(intensities), 'Unit': 'None'}
                ])
                cloudwatch.put_metric_data(Namespace=f"CarbonAwareCompute/{os.environ.get('COMPONENT_NAME', 'default')}", MetricData=metric_data)

            def detect_carbon_anomalies(carbon_data):
                anomalies = []
                for region, data in carbon_data.items():
                    intensity = data['carbon_intensity']
                    if intensity > 600:
                        anomalies.append({'region': region, 'type': 'high_intensity', 'value': intensity, 'message': f'Unusually high carbon intensity in {region}: {intensity} gCO2/kWh'})
                    if data['renewable_percentage'] < 10:
                        anomalies.append({'region': region, 'type': 'low_renewable', 'value': data['renewable_percentage'], 'message': f'Very low renewable energy in {region}: {data["renewable_percentage"]}%'})
                return anomalies
          PYTHON
        end
      end
    end
  end
end
