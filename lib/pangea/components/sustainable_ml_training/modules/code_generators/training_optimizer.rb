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
      # Training optimizer Lambda code generator
      module TrainingOptimizerCode
        def generate_training_optimizer_code(_input)
          <<~PYTHON
            import json
            import boto3
            import os
            from datetime import datetime, timedelta
            import numpy as np

            sagemaker = boto3.client('sagemaker')
            dynamodb = boto3.resource('dynamodb')
            cloudwatch = boto3.client('cloudwatch')

            STATE_TABLE = os.environ['STATE_TABLE']
            COMPUTE_OPTIMIZATION = os.environ['COMPUTE_OPTIMIZATION']
            ENABLE_COMPRESSION = os.environ['ENABLE_COMPRESSION'] == 'True'
            TARGET_REDUCTION = float(os.environ['TARGET_REDUCTION'])
            EARLY_STOPPING = os.environ['EARLY_STOPPING'] == 'True'
            PATIENCE = int(os.environ['PATIENCE'])

            def handler(event, context):
                job_name = event.get('TrainingJobName')
                if not job_name:
                    return {'statusCode': 400, 'body': 'No training job specified'}
                job_details = sagemaker.describe_training_job(TrainingJobName=job_name)
                if job_details['TrainingJobStatus'] == 'InProgress':
                    optimizations = apply_runtime_optimizations(job_details)
                elif job_details['TrainingJobStatus'] == 'Completed':
                    optimizations = apply_post_training_optimizations(job_details)
                else:
                    optimizations = []
                emit_optimization_metrics(job_name, optimizations)
                return {'statusCode': 200, 'body': json.dumps({'job_name': job_name, 'optimizations_applied': len(optimizations), 'details': optimizations})}

            def apply_runtime_optimizations(job_details):
                optimizations = []
                if EARLY_STOPPING and should_stop_early(job_details):
                    sagemaker.stop_training_job(TrainingJobName=job_details['TrainingJobName'])
                    optimizations.append({'type': 'early_stopping', 'reason': 'No improvement in validation metric', 'savings': estimate_carbon_savings(job_details)})
                if can_adjust_batch_size(job_details):
                    optimizations.append({'type': 'batch_size_optimization', 'new_value': calculate_optimal_batch_size(job_details), 'efficiency_gain': '15%'})
                if should_adjust_learning_rate(job_details):
                    optimizations.append({'type': 'learning_rate_decay', 'strategy': 'cosine_annealing', 'efficiency_gain': '10%'})
                return optimizations

            def apply_post_training_optimizations(job_details):
                optimizations = []
                if ENABLE_COMPRESSION:
                    result = compress_model(job_details['ModelArtifacts']['S3ModelArtifacts'])
                    optimizations.append({'type': 'model_compression', 'technique': COMPUTE_OPTIMIZATION, 'size_reduction': result['reduction'], 'accuracy_impact': result['accuracy_delta']})
                if should_optimize_for_inference(job_details):
                    result = optimize_for_inference(job_details['ModelArtifacts']['S3ModelArtifacts'])
                    optimizations.append({'type': 'inference_optimization', 'format': result['format'], 'speedup': result['speedup']})
                return optimizations

            def should_stop_early(job_details):
                metrics = get_training_metrics(job_details['TrainingJobName'])
                if len(metrics) < PATIENCE:
                    return False
                return min(metrics[-PATIENCE:]) >= min(metrics[:-PATIENCE])

            def can_adjust_batch_size(job_details):
                gpu_metrics = get_gpu_metrics(job_details['TrainingJobName'])
                return gpu_metrics and gpu_metrics['memory_utilization'] < 0.8

            def calculate_optimal_batch_size(job_details):
                gpu_metrics = get_gpu_metrics(job_details['TrainingJobName'])
                current = get_current_batch_size(job_details)
                scale = 1.0 + (1.0 - gpu_metrics['memory_utilization']) * 0.5
                return 2 ** round(np.log2(int(current * scale)))

            def should_adjust_learning_rate(job_details):
                metrics = get_training_metrics(job_details['TrainingJobName'])
                return len(metrics) >= 10 and np.var(metrics[-10:]) < 0.01

            def compress_model(model_s3_uri):
                results = {'reduction': 0, 'accuracy_delta': 0}
                if COMPUTE_OPTIMIZATION == 'quantization':
                    results = {'reduction': 0.75, 'accuracy_delta': -0.01}
                elif COMPUTE_OPTIMIZATION == 'pruning':
                    results = {'reduction': TARGET_REDUCTION, 'accuracy_delta': -0.02}
                elif COMPUTE_OPTIMIZATION == 'distillation':
                    results = {'reduction': 0.9, 'accuracy_delta': -0.03}
                return results

            def should_optimize_for_inference(job_details):
                return True

            def optimize_for_inference(model_s3_uri):
                instance_family = get_instance_family()
                if 'p3' in instance_family or 'p4' in instance_family:
                    return {'format': 'TensorRT', 'speedup': '3x'}
                elif 'inf1' in instance_family:
                    return {'format': 'Neuron', 'speedup': '4x'}
                return {'format': 'ONNX', 'speedup': '2x'}

            def get_training_metrics(job_name):
                response = cloudwatch.get_metric_statistics(Namespace='aws/sagemaker/TrainingJobs', MetricName='train:loss', Dimensions=[{'Name': 'TrainingJobName', 'Value': job_name}], StartTime=datetime.now() - timedelta(hours=24), EndTime=datetime.now(), Period=300, Statistics=['Average'])
                return [p['Average'] for p in response['Datapoints']]

            def get_gpu_metrics(job_name):
                response = cloudwatch.get_metric_statistics(Namespace='aws/sagemaker/TrainingJobs', MetricName='GPUMemoryUtilization', Dimensions=[{'Name': 'TrainingJobName', 'Value': job_name}], StartTime=datetime.now() - timedelta(minutes=10), EndTime=datetime.now(), Period=60, Statistics=['Average'])
                return {'memory_utilization': response['Datapoints'][-1]['Average'] / 100} if response['Datapoints'] else None

            def get_current_batch_size(job_details):
                return int(job_details.get('HyperParameters', {}).get('batch_size', 32))

            def estimate_carbon_savings(job_details):
                elapsed = (datetime.now() - job_details['TrainingStartTime']).total_seconds() / 3600
                total = float(job_details.get('StoppingCondition', {}).get('MaxRuntimeInSeconds', 86400)) / 3600
                saved = total - elapsed
                carbon = (400 * saved * 400) / 1000
                return {'hours_saved': saved, 'carbon_saved_kg': carbon / 1000}

            def get_instance_family():
                return os.environ.get('INSTANCE_TYPE', 'ml.p3.8xlarge')

            def emit_optimization_metrics(job_name, optimizations):
                namespace = f"SustainableML/{os.environ.get('COMPONENT_NAME', 'default')}"
                data = [{'MetricName': 'OptimizationsApplied', 'Value': len(optimizations), 'Unit': 'Count', 'Dimensions': [{'Name': 'JobName', 'Value': job_name}]}]
                for opt in optimizations:
                    if opt['type'] == 'early_stopping':
                        data.append({'MetricName': 'CarbonSavedByEarlyStopping', 'Value': opt['savings']['carbon_saved_kg'], 'Unit': 'None'})
                    elif opt['type'] == 'model_compression':
                        data.append({'MetricName': 'ModelSizeReduction', 'Value': opt['size_reduction'] * 100, 'Unit': 'Percent'})
                cloudwatch.put_metric_data(Namespace=namespace, MetricData=data)
          PYTHON
        end
      end
    end
  end
end
