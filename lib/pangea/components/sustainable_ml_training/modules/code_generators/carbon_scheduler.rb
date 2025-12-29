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
    module SustainableMLTraining
      # Carbon scheduler Lambda code generator
      module CarbonSchedulerCode
        def generate_carbon_scheduler_code(_input)
          <<~PYTHON
            import json
            import boto3
            import os
            from datetime import datetime, timedelta

            sagemaker = boto3.client('sagemaker')
            dynamodb = boto3.resource('dynamodb')
            cloudwatch = boto3.client('cloudwatch')

            STATE_TABLE = os.environ['STATE_TABLE']
            CARBON_TABLE = os.environ['CARBON_TABLE']
            CARBON_THRESHOLD = int(os.environ['CARBON_THRESHOLD'])
            PREFERRED_REGIONS = os.environ['PREFERRED_REGIONS'].split(',')
            TRAINING_STRATEGY = os.environ['TRAINING_STRATEGY']

            def handler(event, context):
                state_table = dynamodb.Table(STATE_TABLE)
                carbon_table = dynamodb.Table(CARBON_TABLE)
                pending_jobs = get_pending_training_jobs(state_table)

                for job in pending_jobs:
                    carbon_data = get_regional_carbon_data(carbon_table)
                    optimal_config = find_optimal_training_config(job, carbon_data, TRAINING_STRATEGY)

                    if optimal_config['start_now']:
                        start_training_job(job, optimal_config['region'])
                        update_job_state(state_table, job['job_id'], 'training', optimal_config)
                    else:
                        schedule_training_job(job, optimal_config['start_time'], optimal_config['region'])

                return {'statusCode': 200, 'body': json.dumps(f'Processed {len(pending_jobs)} jobs')}

            def get_pending_training_jobs(table):
                response = table.query(
                    IndexName='status-index',
                    KeyConditionExpression='#status = :status',
                    ExpressionAttributeNames={'#status': 'status'},
                    ExpressionAttributeValues={':status': 'pending'}
                )
                return response.get('Items', [])

            def get_regional_carbon_data(table):
                carbon_data = {}
                current_time = int(datetime.now().timestamp())
                for region in PREFERRED_REGIONS:
                    response = table.query(
                        KeyConditionExpression='region = :region AND #ts > :ts',
                        ExpressionAttributeNames={'#ts': 'timestamp'},
                        ExpressionAttributeValues={':region': region, ':ts': current_time - 900},
                        ScanIndexForward=False, Limit=1
                    )
                    carbon_data[region] = response['Items'][0] if response['Items'] else estimate_carbon_intensity(region)
                return carbon_data

            def estimate_carbon_intensity(region):
                baselines = {'us-west-2': 50, 'eu-north-1': 40, 'ca-central-1': 30, 'eu-west-1': 80, 'us-east-1': 400}
                base = baselines.get(region, 300)
                hour = datetime.now().hour
                multiplier = 1.3 if 9 <= hour <= 17 else (0.7 if 0 <= hour <= 6 else 1.0)
                return {'carbon_intensity': int(base * multiplier), 'renewable_percentage': 100 - (base / 5), 'timestamp': int(datetime.now().timestamp())}

            def find_optimal_training_config(job, carbon_data, strategy):
                strategies = {'carbon_aware_scheduling': carbon_aware_scheduling, 'efficient_architecture': efficient_architecture_scheduling,
                              'mixed_precision': mixed_precision_scheduling, 'federated_learning': federated_learning_config}
                return strategies.get(strategy, default_scheduling)(job, carbon_data)

            def carbon_aware_scheduling(job, carbon_data):
                best_region, min_carbon = min(carbon_data.items(), key=lambda x: x[1]['carbon_intensity'])
                if min_carbon['carbon_intensity'] <= CARBON_THRESHOLD:
                    return {'start_now': True, 'region': best_region, 'carbon_intensity': min_carbon['carbon_intensity'], 'strategy': 'immediate_low_carbon'}
                return {'start_now': False, 'start_time': predict_low_carbon_window(best_region), 'region': best_region, 'carbon_intensity': min_carbon['carbon_intensity'], 'strategy': 'delayed_optimization'}

            def efficient_architecture_scheduling(job, carbon_data):
                for region in ['us-west-2', 'eu-north-1']:
                    if region in carbon_data:
                        return {'start_now': True, 'region': region, 'carbon_intensity': carbon_data[region]['carbon_intensity'], 'hardware_efficiency': 'optimized', 'strategy': 'efficient_hardware'}
                return {'start_now': True, 'region': PREFERRED_REGIONS[0], 'carbon_intensity': 0, 'strategy': 'efficient_hardware'}

            def mixed_precision_scheduling(job, carbon_data):
                adjusted_threshold = CARBON_THRESHOLD * 1.4
                for region, data in carbon_data.items():
                    effective_carbon = data['carbon_intensity'] * 0.6
                    if effective_carbon <= adjusted_threshold:
                        return {'start_now': True, 'region': region, 'carbon_intensity': data['carbon_intensity'], 'effective_carbon': effective_carbon, 'optimization': 'mixed_precision', 'strategy': 'compute_optimized'}
                return {'start_now': False, 'start_time': datetime.now() + timedelta(hours=2), 'region': PREFERRED_REGIONS[0], 'strategy': 'wait_for_cleaner_grid'}

            def federated_learning_config(job, carbon_data):
                eligible_regions = [r for r, d in carbon_data.items() if d['carbon_intensity'] < CARBON_THRESHOLD * 1.5]
                if len(eligible_regions) >= 2:
                    return {'start_now': True, 'regions': eligible_regions[:3], 'strategy': 'federated_distribution', 'carbon_intensity': sum(carbon_data[r]['carbon_intensity'] for r in eligible_regions[:3]) / 3}
                return default_scheduling(job, carbon_data)

            def default_scheduling(job, carbon_data):
                best_region = min(carbon_data.items(), key=lambda x: x[1]['carbon_intensity'])[0]
                return {'start_now': True, 'region': best_region, 'carbon_intensity': carbon_data[best_region]['carbon_intensity'], 'strategy': 'default'}

            def predict_low_carbon_window(region):
                current_hour = datetime.now().hour
                hours_until_low = 24 - current_hour + 2 if current_hour >= 17 else max(20 - current_hour, 1)
                return datetime.now() + timedelta(hours=hours_until_low)

            def start_training_job(job, region):
                job_config = job['training_config']
                job_config['ResourceConfig']['InstanceType'] = select_regional_instance(region)
                job_config['Environment'] = {'CARBON_REGION': region, 'CARBON_TRACKING': 'enabled', 'MODEL_OPTIMIZATION': job.get('optimization', 'mixed_precision')}
                response = sagemaker.create_training_job(**job_config)
                emit_scheduling_metrics(job, region)
                return response['TrainingJobArn']

            def select_regional_instance(region):
                availability = {'us-west-2': ['ml.p4d.24xlarge'], 'eu-north-1': ['ml.p3.16xlarge'], 'ca-central-1': ['ml.g5.48xlarge'], 'eu-west-1': ['ml.p3.16xlarge'], 'us-east-1': ['ml.p4d.24xlarge']}
                return availability.get(region, ['ml.p3.8xlarge'])[0]

            def schedule_training_job(job, start_time, region):
                events = boto3.client('events')
                rule_name = f"training-{job['job_id']}-{int(start_time.timestamp())}"
                events.put_rule(Name=rule_name, ScheduleExpression=f"at({start_time.strftime('%Y-%m-%dT%H:%M:%S')})", State='ENABLED')

            def update_job_state(table, job_id, status, config):
                table.put_item(Item={'job_id': job_id, 'timestamp': int(datetime.now().timestamp()), 'status': status, 'region': config.get('region', 'multi'), 'carbon_intensity': config.get('carbon_intensity', 0), 'optimization_strategy': config.get('strategy', 'default'), 'config': json.dumps(config)})

            def emit_scheduling_metrics(job, region):
                cloudwatch.put_metric_data(Namespace=f"SustainableML/{os.environ.get('COMPONENT_NAME', 'default')}", MetricData=[{'MetricName': 'TrainingJobsScheduled', 'Value': 1, 'Unit': 'Count', 'Dimensions': [{'Name': 'Region', 'Value': region}, {'Name': 'Strategy', 'Value': TRAINING_STRATEGY}]}])
          PYTHON
        end
      end
    end
  end
end
