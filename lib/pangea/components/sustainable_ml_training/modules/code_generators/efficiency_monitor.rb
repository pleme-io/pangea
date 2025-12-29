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
      # Efficiency monitor Lambda code generator
      module EfficiencyMonitorCode
        def generate_efficiency_monitor_code(_input)
          <<~PYTHON
            import json
            import boto3
            import os
            from datetime import datetime

            cloudwatch = boto3.client('cloudwatch')
            dynamodb = boto3.resource('dynamodb')

            CARBON_TABLE = os.environ['CARBON_TABLE']
            TRACK_CARBON = os.environ['TRACK_CARBON'] == 'True'
            TRACK_ENERGY = os.environ['TRACK_ENERGY'] == 'True'
            MODEL_TYPE = os.environ['MODEL_TYPE']

            def handler(event, context):
                carbon_table = dynamodb.Table(CARBON_TABLE)
                metrics = collect_efficiency_metrics()
                if TRACK_CARBON:
                    carbon_metrics = calculate_carbon_emissions(metrics)
                    metrics.update(carbon_metrics)
                    store_carbon_data(carbon_table, carbon_metrics)
                if TRACK_ENERGY:
                    metrics.update(calculate_energy_usage(metrics))
                metrics.update(analyze_model_efficiency(metrics))
                emit_efficiency_metrics(metrics)
                return {'statusCode': 200, 'body': json.dumps({'metrics_collected': len(metrics), 'carbon_tracked': TRACK_CARBON, 'energy_tracked': TRACK_ENERGY})}

            def collect_efficiency_metrics():
                metrics = {'cpu_utilization': 50.0, 'memory_utilization': 60.0}
                metrics.update(get_training_metrics())
                metrics.update(get_model_metrics())
                return metrics

            def get_training_metrics():
                return {'epochs_completed': int(os.environ.get('EPOCH', 0)), 'batch_size': int(os.environ.get('BATCH_SIZE', 32)), 'learning_rate': float(os.environ.get('LR', 0.001)), 'training_samples_per_second': float(os.environ.get('SAMPLES_PER_SEC', 0))}

            def get_model_metrics():
                params = {'computer_vision': 25_000_000, 'natural_language': 110_000_000, 'generative_ai': 1_500_000_000}
                flops = {'computer_vision': 4_000_000_000, 'natural_language': 20_000_000_000, 'generative_ai': 100_000_000_000}
                return {'model_parameters': params.get(MODEL_TYPE, 10_000_000), 'flops_per_sample': flops.get(MODEL_TYPE, 1_000_000_000)}

            def calculate_carbon_emissions(metrics):
                power = estimate_gpu_power()
                region = os.environ.get('AWS_REGION', 'us-east-1')
                intensity = get_carbon_intensity(region)
                hours = metrics.get('epochs_completed', 1) * 0.1
                emissions = (power * hours * intensity) / 1000
                result = {'carbon_emissions_gco2': emissions, 'carbon_intensity': intensity, 'power_consumption_watts': power}
                if metrics.get('model_parameters', 0) > 0:
                    result['gco2_per_million_parameters'] = emissions / (metrics['model_parameters'] / 1_000_000)
                return result

            def estimate_gpu_power():
                power_map = {'ml.p4d.24xlarge': 400, 'ml.p3.16xlarge': 300, 'ml.p3.8xlarge': 250, 'ml.g5.48xlarge': 350, 'ml.g4dn.12xlarge': 200, 'ml.trn1.32xlarge': 300}
                return power_map.get(os.environ.get('INSTANCE_TYPE', 'ml.p3.8xlarge'), 250)

            def get_carbon_intensity(region):
                carbon_map = {'us-west-2': 50, 'eu-north-1': 40, 'ca-central-1': 30, 'eu-west-1': 80, 'us-east-1': 400, 'us-east-2': 450, 'eu-central-1': 350, 'ap-southeast-1': 600}
                return carbon_map.get(region, 400)

            def calculate_energy_usage(metrics):
                power = metrics.get('power_consumption_watts', 250)
                hours = metrics.get('epochs_completed', 1) * 0.1
                energy = (power * hours) / 1000
                result = {'energy_consumption_kwh': energy}
                if metrics.get('model_parameters', 0) > 0:
                    result['kwh_per_billion_parameters'] = energy / (metrics['model_parameters'] / 1_000_000_000)
                baseline = hours * 300 / 1000
                result['energy_efficiency_vs_baseline'] = (baseline - energy) / baseline * 100 if baseline > 0 else 0
                return result

            def analyze_model_efficiency(metrics):
                analysis = {}
                if 'gpu_utilization' in metrics:
                    analysis['gpu_efficiency_score'] = metrics['gpu_utilization']
                    if metrics['gpu_utilization'] < 70:
                        analysis['gpu_bottleneck'] = 'underutilized'
                    elif metrics.get('gpu_memory_used', 0) / max(metrics.get('gpu_memory_total', 1), 1) > 0.9:
                        analysis['gpu_bottleneck'] = 'memory_bound'
                    else:
                        analysis['gpu_bottleneck'] = 'none'
                analysis['model_efficiency_rating'] = rate_model_efficiency(metrics)
                analysis['recommendations'] = generate_recommendations(metrics, analysis)
                return analysis

            def rate_model_efficiency(metrics):
                score = 100
                if metrics.get('gpu_utilization', 100) < 80:
                    score -= 20
                if metrics.get('energy_efficiency_vs_baseline', 0) < 0:
                    score -= 10
                if MODEL_TYPE == 'generative_ai' and metrics.get('model_parameters', 0) > 1e9:
                    score -= 10
                return max(0, score)

            def generate_recommendations(metrics, analysis):
                recs = []
                if analysis.get('gpu_bottleneck') == 'underutilized':
                    recs.append({'issue': 'GPU underutilized', 'suggestion': 'Increase batch size or use gradient accumulation', 'potential_improvement': '20-30%'})
                if analysis.get('gpu_bottleneck') == 'memory_bound':
                    recs.append({'issue': 'GPU memory saturated', 'suggestion': 'Enable gradient checkpointing or use model parallelism', 'potential_improvement': '15-25%'})
                if metrics.get('carbon_intensity', 0) > 200:
                    recs.append({'issue': 'High carbon region', 'suggestion': 'Consider migrating to cleaner region like us-west-2', 'potential_improvement': '60-80% carbon reduction'})
                return recs

            def store_carbon_data(table, carbon_metrics):
                ts = int(datetime.now().timestamp())
                table.put_item(Item={'metric_id': f"training-{ts}", 'timestamp': ts, 'carbon_emissions': carbon_metrics['carbon_emissions_gco2'], 'carbon_intensity': carbon_metrics['carbon_intensity'], 'power_consumption': carbon_metrics['power_consumption_watts'], 'efficiency_metrics': json.dumps(carbon_metrics), 'expiration': ts + 86400 * 30})

            def emit_efficiency_metrics(metrics):
                namespace = f"SustainableML/{os.environ.get('COMPONENT_NAME', 'default')}"
                data = [{'MetricName': k, 'Value': v, 'Unit': 'None'} for k, v in metrics.items() if isinstance(v, (int, float))]
                for i in range(0, len(data), 20):
                    cloudwatch.put_metric_data(Namespace=namespace, MetricData=data[i:i+20])
          PYTHON
        end
      end
    end
  end
end
