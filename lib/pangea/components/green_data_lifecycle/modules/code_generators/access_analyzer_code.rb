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
        # Access analyzer Lambda function code generator
        module AccessAnalyzerCode
          private

          def generate_access_analyzer_code(_input)
            <<~PYTHON
              import json
              import boto3
              import os
              from datetime import datetime, timedelta
              from collections import defaultdict

              s3 = boto3.client('s3')
              cloudwatch = boto3.client('cloudwatch')

              BUCKET_NAME = os.environ['BUCKET_NAME']
              ANALYSIS_WINDOW = int(os.environ['ANALYSIS_WINDOW_DAYS'])
              OPTIMIZE_READ_HEAVY = os.environ['OPTIMIZE_READ_HEAVY'] == 'True'

              def handler(event, context):
                  access_patterns = analyze_bucket_access_patterns()
                  recommendations = generate_storage_recommendations(access_patterns)
                  apply_access_pattern_tags(recommendations)
                  emit_access_metrics(access_patterns, recommendations)
                  return {
                      'statusCode': 200,
                      'body': json.dumps({
                          'analyzed_objects': len(access_patterns),
                          'recommendations': len(recommendations)
                      })
                  }

              def analyze_bucket_access_patterns():
                  patterns = defaultdict(lambda: {
                      'access_count': 0, 'last_accessed': None,
                      'size': 0, 'storage_class': 'STANDARD'
                  })
                  paginator = s3.get_paginator('list_objects_v2')
                  for page in paginator.paginate(Bucket=BUCKET_NAME):
                      if 'Contents' not in page:
                          continue
                      for obj in page['Contents']:
                          key = obj['Key']
                          try:
                              response = s3.head_object(Bucket=BUCKET_NAME, Key=key)
                              patterns[key]['size'] = obj['Size']
                              patterns[key]['storage_class'] = response.get('StorageClass', 'STANDARD')
                              patterns[key]['last_modified'] = obj['LastModified']
                              patterns[key]['access_count'] = estimate_access_count(key, obj['LastModified'])
                              patterns[key]['last_accessed'] = obj['LastModified']
                          except Exception as e:
                              print(f"Error analyzing {key}: {str(e)}")
                  return patterns

              def estimate_access_count(key, last_modified):
                  age_days = (datetime.now(last_modified.tzinfo) - last_modified).days
                  if age_days < 7:
                      return 50
                  elif age_days < 30:
                      return 10
                  elif age_days < 90:
                      return 2
                  else:
                      return 0

              def generate_storage_recommendations(patterns):
                  recommendations = {}
                  for key, pattern in patterns.items():
                      age_days = (datetime.now() - pattern['last_modified'].replace(tzinfo=None)).days
                      access_frequency = pattern['access_count'] / max(age_days, 1)
                      if access_frequency > 1:
                          recommended_class, classification = 'STANDARD', 'hot'
                      elif access_frequency > 0.1:
                          recommended_class, classification = 'INTELLIGENT_TIERING', 'warm'
                      elif access_frequency > 0.01:
                          recommended_class, classification = 'STANDARD_IA', 'cool'
                      elif age_days > 180:
                          recommended_class, classification = 'GLACIER_FLEXIBLE', 'cold'
                      else:
                          recommended_class, classification = 'GLACIER_IR', 'cold'
                      if OPTIMIZE_READ_HEAVY and classification in ['cool', 'cold']:
                          recommended_class, classification = 'STANDARD_IA', 'cool'
                      if recommended_class != pattern['storage_class']:
                          recommendations[key] = {
                              'current_class': pattern['storage_class'],
                              'recommended_class': recommended_class,
                              'classification': classification,
                              'potential_savings': calculate_savings(
                                  pattern['size'], pattern['storage_class'], recommended_class
                              )
                          }
                  return recommendations

              def calculate_savings(size_bytes, current_class, recommended_class):
                  costs = {
                      'STANDARD': 0.023, 'INTELLIGENT_TIERING': 0.023, 'STANDARD_IA': 0.0125,
                      'GLACIER_IR': 0.004, 'GLACIER_FLEXIBLE': 0.0036, 'DEEP_ARCHIVE': 0.00099
                  }
                  size_gb = size_bytes / (1024 ** 3)
                  return max(0, size_gb * costs.get(current_class, 0.023) - size_gb * costs.get(recommended_class, 0.023))

              def apply_access_pattern_tags(recommendations):
                  for key, recommendation in recommendations.items():
                      try:
                          s3.put_object_tagging(Bucket=BUCKET_NAME, Key=key, Tagging={
                              'TagSet': [
                                  {'Key': 'DataClassification', 'Value': recommendation['classification']},
                                  {'Key': 'RecommendedStorageClass', 'Value': recommendation['recommended_class']},
                                  {'Key': 'LastAnalyzed', 'Value': datetime.now().isoformat()}
                              ]
                          })
                      except Exception as e:
                          print(f"Error tagging {key}: {str(e)}")

              def emit_access_metrics(patterns, recommendations):
                  total_objects = len(patterns)
                  hot_objects = sum(1 for r in recommendations.values() if r['classification'] == 'hot')
                  warm_objects = sum(1 for r in recommendations.values() if r['classification'] == 'warm')
                  cool_objects = sum(1 for r in recommendations.values() if r['classification'] == 'cool')
                  cold_objects = sum(1 for r in recommendations.values() if r['classification'] == 'cold')
                  total_savings = sum(r['potential_savings'] for r in recommendations.values())
                  access_pattern_score = ((total_objects - len(recommendations)) / total_objects * 100) if total_objects > 0 else 100
                  cloudwatch.put_metric_data(
                      Namespace=f"GreenDataLifecycle/{os.environ.get('COMPONENT_NAME', BUCKET_NAME)}",
                      MetricData=[
                          {'MetricName': 'AccessPatternScore', 'Value': access_pattern_score, 'Unit': 'Percent'},
                          {'MetricName': 'HotDataObjects', 'Value': hot_objects, 'Unit': 'Count'},
                          {'MetricName': 'WarmDataObjects', 'Value': warm_objects, 'Unit': 'Count'},
                          {'MetricName': 'CoolDataObjects', 'Value': cool_objects, 'Unit': 'Count'},
                          {'MetricName': 'ColdDataObjects', 'Value': cold_objects, 'Unit': 'Count'},
                          {'MetricName': 'PotentialMonthlySavings', 'Value': total_savings, 'Unit': 'None'}
                      ]
                  )
            PYTHON
          end
        end
      end
    end
  end
end
