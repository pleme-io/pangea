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
        # Lifecycle manager Lambda function code generator
        module LifecycleManagerCode
          private

          def generate_lifecycle_manager_code(_input)
            <<~PYTHON
              import json
              import boto3
              import os
              from datetime import datetime, timedelta

              s3 = boto3.client('s3')
              cloudwatch = boto3.client('cloudwatch')

              BUCKET_NAME = os.environ['BUCKET_NAME']
              COMPLIANCE_MODE = os.environ['COMPLIANCE_MODE'] == 'True'
              DELETION_PROTECTION = os.environ['DELETION_PROTECTION'] == 'True'
              LEGAL_HOLD_TAGS = os.environ['LEGAL_HOLD_TAGS'].split(',') if os.environ['LEGAL_HOLD_TAGS'] else []

              def handler(event, context):
                  transitions = process_lifecycle_transitions()
                  deletions = process_deletions()
                  compliance_issues = validate_compliance()
                  emit_lifecycle_metrics(transitions, deletions, compliance_issues)
                  return {'statusCode': 200, 'body': json.dumps({'transitions': len(transitions), 'deletions': len(deletions), 'compliance_issues': len(compliance_issues)})}

              def process_lifecycle_transitions():
                  transitions = []
                  paginator = s3.get_paginator('list_objects_v2')
                  for page in paginator.paginate(Bucket=BUCKET_NAME):
                      if 'Contents' not in page:
                          continue
                      for obj in page['Contents']:
                          try:
                              response = s3.get_object_tagging(Bucket=BUCKET_NAME, Key=obj['Key'])
                              tags = {tag['Key']: tag['Value'] for tag in response.get('TagSet', [])}
                              if 'CarbonOptimizationTarget' in tags:
                                  target_class = tags['CarbonOptimizationTarget']
                                  if is_transition_allowed(obj, target_class, tags):
                                      transitions.append({'key': obj['Key'], 'target_class': target_class, 'size': obj['Size']})
                                      log_transition(obj['Key'], target_class)
                              elif 'RecommendedStorageClass' in tags:
                                  target_class = tags['RecommendedStorageClass']
                                  if is_transition_allowed(obj, target_class, tags):
                                      transitions.append({'key': obj['Key'], 'target_class': target_class, 'size': obj['Size']})
                          except Exception as e:
                              print(f"Error processing {obj['Key']}: {str(e)}")
                  return transitions

              def is_transition_allowed(obj, target_class, tags):
                  if COMPLIANCE_MODE:
                      if any(tag in tags for tag in LEGAL_HOLD_TAGS):
                          return False
                      age_days = (datetime.now() - obj['LastModified'].replace(tzinfo=None)).days
                      if age_days < 90:
                          return False
                  return get_storage_class(obj) != target_class

              def get_storage_class(obj):
                  try:
                      response = s3.head_object(Bucket=BUCKET_NAME, Key=obj['Key'])
                      return response.get('StorageClass', 'STANDARD')
                  except:
                      return 'STANDARD'

              def process_deletions():
                  deletions = []
                  if DELETION_PROTECTION:
                      return deletions
                  paginator = s3.get_paginator('list_objects_v2')
                  for page in paginator.paginate(Bucket=BUCKET_NAME):
                      if 'Contents' not in page:
                          continue
                      for obj in page['Contents']:
                          if is_object_expired(obj) and not has_legal_hold(obj['Key']):
                              deletions.append({'key': obj['Key'], 'size': obj['Size'], 'age_days': (datetime.now() - obj['LastModified'].replace(tzinfo=None)).days})
                  return deletions

              def is_object_expired(obj):
                  age_days = (datetime.now() - obj['LastModified'].replace(tzinfo=None)).days
                  storage_class = get_storage_class(obj)
                  if storage_class == 'DEEP_ARCHIVE' and age_days > 2555:
                      return True
                  elif storage_class == 'GLACIER_FLEXIBLE' and age_days > 1825:
                      return True
                  return False

              def has_legal_hold(key):
                  try:
                      response = s3.get_object_tagging(Bucket=BUCKET_NAME, Key=key)
                      tags = {tag['Key']: tag['Value'] for tag in response.get('TagSet', [])}
                      return any(tag in tags for tag in LEGAL_HOLD_TAGS)
                  except:
                      return False

              def validate_compliance():
                  issues = []
                  if not COMPLIANCE_MODE:
                      return issues
                  sample_size, checked = 100, 0
                  paginator = s3.get_paginator('list_objects_v2')
                  for page in paginator.paginate(Bucket=BUCKET_NAME):
                      if 'Contents' not in page:
                          continue
                      for obj in page['Contents']:
                          if checked >= sample_size:
                              break
                          try:
                              response = s3.get_object_tagging(Bucket=BUCKET_NAME, Key=obj['Key'])
                              tags = {tag['Key']: tag['Value'] for tag in response.get('TagSet', [])}
                              if 'DataClassification' not in tags:
                                  issues.append({'type': 'missing_classification', 'key': obj['Key']})
                              if 'RetentionDate' in tags:
                                  if datetime.now() > datetime.fromisoformat(tags['RetentionDate']):
                                      issues.append({'type': 'retention_expired', 'key': obj['Key']})
                              checked += 1
                          except Exception as e:
                              print(f"Compliance check error for {obj['Key']}: {str(e)}")
                  return issues

              def log_transition(key, target_class):
                  print(f"Transition logged: {key} -> {target_class}")

              def emit_lifecycle_metrics(transitions, deletions, compliance_issues):
                  cloudwatch.put_metric_data(
                      Namespace=f"GreenDataLifecycle/{os.environ.get('COMPONENT_NAME', BUCKET_NAME)}",
                      MetricData=[
                          {'MetricName': 'ObjectsTransitioned', 'Value': len(transitions), 'Unit': 'Count'},
                          {'MetricName': 'ObjectsDeleted', 'Value': len(deletions), 'Unit': 'Count'},
                          {'MetricName': 'ComplianceIssues', 'Value': len(compliance_issues), 'Unit': 'Count'},
                          {'MetricName': 'ObjectsArchived', 'Value': sum(1 for t in transitions if 'GLACIER' in t['target_class']), 'Unit': 'Count'}
                      ]
                  )
                  if transitions:
                      cloudwatch.put_metric_data(
                          Namespace=f"GreenDataLifecycle/{os.environ.get('COMPONENT_NAME', BUCKET_NAME)}",
                          MetricData=[{'MetricName': 'DataTransitionedGB', 'Value': sum(t['size'] for t in transitions) / (1024 ** 3), 'Unit': 'None'}]
                      )
                  if deletions:
                      cloudwatch.put_metric_data(
                          Namespace=f"GreenDataLifecycle/{os.environ.get('COMPONENT_NAME', BUCKET_NAME)}",
                          MetricData=[{'MetricName': 'DataDeletedGB', 'Value': sum(d['size'] for d in deletions) / (1024 ** 3), 'Unit': 'None'}]
                      )
            PYTHON
          end
        end
      end
    end
  end
end
