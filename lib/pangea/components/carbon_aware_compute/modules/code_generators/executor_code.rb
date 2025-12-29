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
      # Executor Lambda function Python code generator
      module ExecutorCode
        def generate_executor_code(_input)
          <<~PYTHON
            import json
            import boto3
            import os
            import time
            from datetime import datetime

            dynamodb = boto3.resource('dynamodb')
            cloudwatch = boto3.client('cloudwatch')

            WORKLOAD_TABLE = os.environ['WORKLOAD_TABLE']
            WORKLOAD_TYPE = os.environ['WORKLOAD_TYPE']
            USE_SPOT = os.environ['USE_SPOT'] == 'True'
            ENABLE_REPORTING = os.environ['ENABLE_CARBON_REPORTING'] == 'True'

            def handler(event, context):
                workload_table = dynamodb.Table(WORKLOAD_TABLE)
                current_time = int(time.time())
                scheduled_workloads = get_scheduled_workloads(workload_table, current_time)
                execution_results, total_carbon_saved = [], 0
                for workload in scheduled_workloads:
                    result = execute_workload(workload)
                    carbon_metrics = calculate_carbon_metrics(workload, result)
                    total_carbon_saved += carbon_metrics['carbon_saved']
                    update_workload_status(workload_table, workload['workload_id'], 'completed', result, carbon_metrics)
                    if ENABLE_REPORTING:
                        emit_execution_metrics(workload, result, carbon_metrics)
                    execution_results.append({'workload_id': workload['workload_id'], 'status': 'completed', 'carbon_saved': carbon_metrics['carbon_saved']})
                return {'statusCode': 200, 'body': json.dumps({'executed': len(execution_results), 'total_carbon_saved': total_carbon_saved, 'results': execution_results})}

            def get_scheduled_workloads(table, current_time):
                response = table.query(
                    IndexName='region-status-index',
                    KeyConditionExpression='#status = :status',
                    FilterExpression='scheduled_time <= :current_time',
                    ExpressionAttributeNames={'#status': 'status'},
                    ExpressionAttributeValues={':status': 'scheduled', ':current_time': current_time}
                )
                return response.get('Items', [])

            def execute_workload(workload):
                start_time = time.time()
                if WORKLOAD_TYPE == 'batch': result = execute_batch_job(workload)
                elif WORKLOAD_TYPE == 'ml_training': result = execute_ml_training(workload)
                elif WORKLOAD_TYPE == 'data_pipeline': result = execute_data_pipeline(workload)
                else: result = execute_generic_workload(workload)
                execution_time = time.time() - start_time
                return {
                    'execution_time': execution_time, 'compute_units': calculate_compute_units(execution_time),
                    'success': True, 'instance_type': 'graviton' if workload.get('use_graviton') else 'x86',
                    'spot_used': USE_SPOT
                }

            def execute_batch_job(workload):
                time.sleep(2)
                return {'records_processed': 1000}

            def execute_ml_training(workload):
                time.sleep(5)
                return {'model_accuracy': 0.95}

            def execute_data_pipeline(workload):
                time.sleep(3)
                return {'data_processed_gb': 10}

            def execute_generic_workload(workload):
                time.sleep(1)
                return {'tasks_completed': 50}

            def calculate_compute_units(execution_time):
                cpu_units = int(os.environ.get('CPU_UNITS', 256))
                return (execution_time / 3600) * (cpu_units / 1024)

            def calculate_carbon_metrics(workload, result):
                compute_units = result['compute_units']
                actual_intensity = workload.get('estimated_carbon', 300)
                baseline_intensity = 400
                actual_emissions = compute_units * actual_intensity
                baseline_emissions = compute_units * baseline_intensity
                carbon_saved = baseline_emissions - actual_emissions
                if result.get('instance_type') == 'graviton': carbon_saved *= 1.2
                if result.get('spot_used'): carbon_saved *= 1.1
                return {
                    'actual_emissions': actual_emissions, 'baseline_emissions': baseline_emissions,
                    'carbon_saved': max(0, carbon_saved), 'carbon_intensity': actual_intensity,
                    'efficiency_score': (carbon_saved / baseline_emissions) * 100 if baseline_emissions > 0 else 0
                }

            def update_workload_status(table, workload_id, status, result, carbon_metrics):
                table.update_item(
                    Key={'workload_id': workload_id},
                    UpdateExpression='SET #status = :status, execution_result = :result, carbon_metrics = :metrics, completed_time = :time',
                    ExpressionAttributeNames={'#status': 'status'},
                    ExpressionAttributeValues={
                        ':status': status, ':result': json.dumps(result),
                        ':metrics': json.dumps(carbon_metrics), ':time': int(time.time())
                    }
                )

            def emit_execution_metrics(workload, result, carbon_metrics):
                cloudwatch.put_metric_data(
                    Namespace=f"CarbonAwareCompute/{os.environ.get('COMPONENT_NAME', 'default')}",
                    MetricData=[
                        {'MetricName': 'WorkloadsExecuted', 'Value': 1, 'Unit': 'Count'},
                        {'MetricName': 'CarbonEmissions', 'Value': carbon_metrics['actual_emissions'], 'Unit': 'None', 'Dimensions': [{'Name': 'WorkloadType', 'Value': WORKLOAD_TYPE}, {'Name': 'Region', 'Value': workload.get('region', 'unknown')}]},
                        {'MetricName': 'CarbonSaved', 'Value': carbon_metrics['carbon_saved'], 'Unit': 'None'},
                        {'MetricName': 'ComputeEfficiency', 'Value': carbon_metrics['efficiency_score'], 'Unit': 'Percent'},
                        {'MetricName': 'ComputeUnits', 'Value': result['compute_units'], 'Unit': 'None'}
                    ]
                )
          PYTHON
        end
      end
    end
  end
end
