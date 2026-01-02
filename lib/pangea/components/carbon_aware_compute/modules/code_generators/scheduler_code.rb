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
      # Scheduler Lambda function Python code generator
      module SchedulerCode
        def generate_scheduler_code(_input)
          <<~PYTHON
            import json
            import boto3
            import os
            import time
            from datetime import datetime, timedelta
            import requests

            dynamodb = boto3.resource('dynamodb')
            cloudwatch = boto3.client('cloudwatch')

            WORKLOAD_TABLE = os.environ['WORKLOAD_TABLE']
            CARBON_TABLE = os.environ['CARBON_TABLE']
            OPTIMIZATION_STRATEGY = os.environ['OPTIMIZATION_STRATEGY']
            CARBON_THRESHOLD = int(os.environ['CARBON_THRESHOLD'])
            PREFERRED_REGIONS = os.environ['PREFERRED_REGIONS'].split(',')
            MIN_WINDOW = int(os.environ['MIN_WINDOW_HOURS'])
            MAX_WINDOW = int(os.environ['MAX_WINDOW_HOURS'])

            def handler(event, context):
                workload_table = dynamodb.Table(WORKLOAD_TABLE)
                carbon_table = dynamodb.Table(CARBON_TABLE)
                pending_workloads = get_pending_workloads(workload_table)
                for workload in pending_workloads:
                    carbon_data = get_carbon_intensity(carbon_table, PREFERRED_REGIONS)
                    optimal_schedule = optimize_schedule(
                        workload, carbon_data, OPTIMIZATION_STRATEGY, CARBON_THRESHOLD
                    )
                    update_workload_schedule(workload_table, workload['workload_id'], optimal_schedule)
                    emit_scheduling_metrics(workload, optimal_schedule, carbon_data)
                return {'statusCode': 200, 'body': json.dumps(f'Scheduled {len(pending_workloads)} workloads')}

            def get_pending_workloads(table):
                response = table.query(
                    IndexName='region-status-index',
                    KeyConditionExpression='#status = :status',
                    ExpressionAttributeNames={'#status': 'status'},
                    ExpressionAttributeValues={':status': 'pending'}
                )
                return response.get('Items', [])

            def get_carbon_intensity(table, regions):
                carbon_data = {}
                current_time = int(time.time())
                for region in regions:
                    response = table.query(
                        KeyConditionExpression='region = :region AND #ts > :ts',
                        ExpressionAttributeNames={'#ts': 'timestamp'},
                        ExpressionAttributeValues={':region': region, ':ts': current_time - 900},
                        ScanIndexForward=False, Limit=1
                    )
                    if response['Items']:
                        carbon_data[region] = response['Items'][0]['carbon_intensity']
                    else:
                        intensity = fetch_carbon_intensity(region)
                        carbon_data[region] = intensity
                        table.put_item(Item={
                            'region': region, 'timestamp': current_time,
                            'carbon_intensity': intensity, 'expiration': current_time + 3600
                        })
                return carbon_data

            def fetch_carbon_intensity(region):
                region_base = {'us-west-2': 50, 'eu-north-1': 40, 'eu-west-1': 80,
                              'ca-central-1': 30, 'us-east-1': 400, 'ap-southeast-1': 600}
                hour = datetime.now().hour
                multiplier = 1.3 if 9 <= hour <= 17 else (0.7 if 0 <= hour <= 6 else 1.0)
                return int(region_base.get(region, 300) * multiplier)

            def optimize_schedule(workload, carbon_data, strategy, threshold):
                best_region, best_time, min_carbon = None, None, float('inf')
                if strategy in ['time_shifting', 'combined']:
                    for hours_ahead in range(MIN_WINDOW, MAX_WINDOW + 1):
                        future_time = datetime.now() + timedelta(hours=hours_ahead)
                        for region, current_intensity in carbon_data.items():
                            estimated = estimate_future_intensity(region, current_intensity, future_time)
                            if estimated < min_carbon:
                                min_carbon, best_region, best_time = estimated, region, future_time
                if strategy in ['location_shifting', 'combined']:
                    for region, intensity in carbon_data.items():
                        if intensity < min_carbon:
                            min_carbon, best_region, best_time = intensity, region, datetime.now()
                if min_carbon > threshold and best_region is None:
                    best_region = PREFERRED_REGIONS[0]
                    best_time = datetime.now() + timedelta(hours=MIN_WINDOW)
                return {
                    'region': best_region, 'scheduled_time': int(best_time.timestamp()),
                    'estimated_carbon_intensity': min_carbon,
                    'optimization_type': 'time_shift' if best_time > datetime.now() else 'location_shift'
                }

            def estimate_future_intensity(region, current, future_time):
                hour = future_time.hour
                if 0 <= hour <= 6: return current * 0.7
                elif 9 <= hour <= 17: return current * 1.3
                return current

            def update_workload_schedule(table, workload_id, schedule):
                table.update_item(
                    Key={'workload_id': workload_id, 'scheduled_time': schedule['scheduled_time']},
                    UpdateExpression='SET #region = :region, #status = :status, optimization_type = :opt_type, estimated_carbon = :carbon',
                    ExpressionAttributeNames={'#region': 'region', '#status': 'status'},
                    ExpressionAttributeValues={
                        ':region': schedule['region'], ':status': 'scheduled',
                        ':opt_type': schedule['optimization_type'],
                        ':carbon': schedule['estimated_carbon_intensity']
                    }
                )

            def emit_scheduling_metrics(workload, schedule, carbon_data):
                cloudwatch.put_metric_data(
                    Namespace=f"CarbonAwareCompute/{os.environ.get('COMPONENT_NAME', 'default')}",
                    MetricData=[
                        {'MetricName': 'WorkloadsScheduled', 'Value': 1, 'Unit': 'Count'},
                        {'MetricName': 'WorkloadsShifted', 'Value': 1 if schedule['optimization_type'] in ['time_shift', 'location_shift'] else 0, 'Unit': 'Count'},
                        {'MetricName': 'EstimatedCarbonIntensity', 'Value': schedule['estimated_carbon_intensity'], 'Unit': 'None', 'Dimensions': [{'Name': 'Region', 'Value': schedule['region']}]}
                    ]
                )
          PYTHON
        end
      end
    end
  end
end
