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
    module GreenDataLifecycle
      module CodeGenerators
        # Carbon optimizer Lambda function code generator
        module CarbonOptimizerCode
          private

          def generate_carbon_optimizer_code(_input)
            <<~PYTHON
              import json
              import boto3
              import os
              from datetime import datetime

              s3 = boto3.client('s3')
              cloudwatch = boto3.client('cloudwatch')

              BUCKET_NAME = os.environ['BUCKET_NAME']
              CARBON_THRESHOLD = float(os.environ['CARBON_THRESHOLD'])
              PREFER_RENEWABLE = os.environ['PREFER_RENEWABLE'] == 'True'
              LIFECYCLE_STRATEGY = os.environ['LIFECYCLE_STRATEGY']

              STORAGE_CARBON_INTENSITY = {
                  'STANDARD': 0.55, 'INTELLIGENT_TIERING': 0.45, 'STANDARD_IA': 0.35,
                  'ONEZONE_IA': 0.30, 'GLACIER_IR': 0.15, 'GLACIER_FLEXIBLE': 0.10, 'DEEP_ARCHIVE': 0.05
              }

              def handler(event, context):
                  current_footprint = calculate_bucket_carbon_footprint()
                  optimizations = generate_carbon_optimizations(current_footprint)
                  applied = apply_carbon_optimizations(optimizations)
                  emit_carbon_metrics(current_footprint, optimizations, applied)
                  return {
                      'statusCode': 200,
                      'body': json.dumps({
                          'current_carbon_footprint': current_footprint['total_gco2'],
                          'potential_reduction': optimizations['total_reduction'],
                          'optimizations_applied': len(applied)
                      })
                  }

              def calculate_bucket_carbon_footprint():
                  footprint = {'by_storage_class': {}, 'total_size_gb': 0, 'total_gco2': 0}
                  for storage_class, carbon_intensity in STORAGE_CARBON_INTENSITY.items():
                      try:
                          response = cloudwatch.get_metric_statistics(
                              Namespace='AWS/S3', MetricName='BucketSizeBytes',
                              Dimensions=[{'Name': 'BucketName', 'Value': BUCKET_NAME}, {'Name': 'StorageType', 'Value': storage_class}],
                              StartTime=datetime.now().replace(hour=0, minute=0, second=0),
                              EndTime=datetime.now(), Period=86400, Statistics=['Average']
                          )
                          if response['Datapoints']:
                              size_bytes = response['Datapoints'][0]['Average']
                              size_gb = size_bytes / (1024 ** 3)
                              carbon_gco2 = size_gb * carbon_intensity
                              footprint['by_storage_class'][storage_class] = {'size_gb': size_gb, 'carbon_gco2': carbon_gco2, 'carbon_intensity': carbon_intensity}
                              footprint['total_size_gb'] += size_gb
                              footprint['total_gco2'] += carbon_gco2
                      except Exception as e:
                          print(f"Error getting metrics for {storage_class}: {str(e)}")
                  footprint['avg_carbon_intensity'] = footprint['total_gco2'] / footprint['total_size_gb'] if footprint['total_size_gb'] > 0 else 0
                  return footprint

              def generate_carbon_optimizations(footprint):
                  optimizations = {'recommendations': [], 'total_reduction': 0}
                  for storage_class, data in footprint['by_storage_class'].items():
                      if data['size_gb'] == 0:
                          continue
                      for target_class, target_intensity in STORAGE_CARBON_INTENSITY.items():
                          if target_intensity < data['carbon_intensity']:
                              reduction = data['size_gb'] * (data['carbon_intensity'] - target_intensity)
                              if reduction > data['size_gb'] * 0.1:
                                  optimizations['recommendations'].append({
                                      'from_class': storage_class, 'to_class': target_class, 'size_gb': data['size_gb'],
                                      'carbon_reduction': reduction, 'percentage_reduction': (reduction / data['carbon_gco2']) * 100
                                  })
                                  optimizations['total_reduction'] += reduction
                  optimizations['recommendations'].sort(key=lambda x: x['carbon_reduction'], reverse=True)
                  if LIFECYCLE_STRATEGY == 'cost_optimized':
                      optimizations['recommendations'] = [r for r in optimizations['recommendations'] if not is_cost_prohibitive(r['from_class'], r['to_class'])]
                  return optimizations

              def is_cost_prohibitive(from_class, to_class):
                  cost_order = ['DEEP_ARCHIVE', 'GLACIER_FLEXIBLE', 'GLACIER_IR', 'ONEZONE_IA', 'STANDARD_IA', 'INTELLIGENT_TIERING', 'STANDARD']
                  from_index = cost_order.index(from_class) if from_class in cost_order else 0
                  to_index = cost_order.index(to_class) if to_class in cost_order else 0
                  return to_index > from_index

              def apply_carbon_optimizations(optimizations):
                  applied = []
                  for recommendation in optimizations['recommendations']:
                      if recommendation['carbon_reduction'] > CARBON_THRESHOLD * recommendation['size_gb']:
                          tag_objects_for_transition(recommendation['from_class'], recommendation['to_class'])
                          applied.append(recommendation)
                          if len(applied) >= 5:
                              break
                  return applied

              def tag_objects_for_transition(from_class, to_class):
                  paginator = s3.get_paginator('list_objects_v2')
                  for page in paginator.paginate(Bucket=BUCKET_NAME):
                      if 'Contents' not in page:
                          continue
                      for obj in page['Contents']:
                          try:
                              response = s3.head_object(Bucket=BUCKET_NAME, Key=obj['Key'])
                              if response.get('StorageClass', 'STANDARD') == from_class:
                                  s3.put_object_tagging(Bucket=BUCKET_NAME, Key=obj['Key'], Tagging={
                                      'TagSet': [
                                          {'Key': 'CarbonOptimizationTarget', 'Value': to_class},
                                          {'Key': 'CarbonOptimizationDate', 'Value': datetime.now().isoformat()}
                                      ]
                                  })
                          except Exception as e:
                              print(f"Error tagging object {obj['Key']}: {str(e)}")

              def emit_carbon_metrics(footprint, optimizations, applied):
                  cloudwatch.put_metric_data(
                      Namespace=f"GreenDataLifecycle/{os.environ.get('COMPONENT_NAME', BUCKET_NAME)}",
                      MetricData=[
                          {'MetricName': 'TotalCarbonFootprint', 'Value': footprint['total_gco2'], 'Unit': 'None'},
                          {'MetricName': 'CarbonPerGB', 'Value': footprint['avg_carbon_intensity'], 'Unit': 'None'},
                          {'MetricName': 'PotentialCarbonReduction', 'Value': optimizations['total_reduction'], 'Unit': 'None'},
                          {'MetricName': 'CarbonOptimizationsApplied', 'Value': len(applied), 'Unit': 'Count'},
                          {'MetricName': 'StorageEfficiency', 'Value': calculate_storage_efficiency(footprint), 'Unit': 'Percent'},
                          {'MetricName': 'CarbonEfficiency', 'Value': calculate_carbon_efficiency(footprint), 'Unit': 'Percent'}
                      ]
                  )
                  for storage_class, data in footprint['by_storage_class'].items():
                      if data['size_gb'] > 0:
                          cloudwatch.put_metric_data(
                              Namespace=f"GreenDataLifecycle/{os.environ.get('COMPONENT_NAME', BUCKET_NAME)}",
                              MetricData=[{'MetricName': 'StorageClassCarbon', 'Value': data['carbon_gco2'], 'Unit': 'None', 'Dimensions': [{'Name': 'StorageClass', 'Value': storage_class}]}]
                          )

              def calculate_storage_efficiency(footprint):
                  if footprint['total_size_gb'] == 0:
                      return 100
                  best_possible = STORAGE_CARBON_INTENSITY['DEEP_ARCHIVE']
                  worst_possible = STORAGE_CARBON_INTENSITY['STANDARD']
                  return max(0, min(100, 100 * (worst_possible - footprint['avg_carbon_intensity']) / (worst_possible - best_possible)))

              def calculate_carbon_efficiency(footprint):
                  if footprint['total_size_gb'] == 0:
                      return 100
                  all_standard_carbon = footprint['total_size_gb'] * STORAGE_CARBON_INTENSITY['STANDARD']
                  return max(0, min(100, ((all_standard_carbon - footprint['total_gco2']) / all_standard_carbon) * 100))
            PYTHON
          end
        end
      end
    end
  end
end
