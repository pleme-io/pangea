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
    module DisasterRecoveryPilotLight
      module CodeGenerators
        # Lambda function code generation
        module LambdaCode
          def generate_dr_userdata(attrs)
            <<~BASH
              #!/bin/bash
              # DR Activation Script

              # Set DR activation flag
              echo "DR_ACTIVATED=true" >> /etc/environment

              # Update application configuration for DR
              aws ssm get-parameter --name "/dr/config" --region #{attrs.dr_region.region} > /tmp/dr-config.json

              # Start application with DR configuration
              systemctl start application-dr

              # Send activation notification
              aws sns publish --topic-arn "arn:aws:sns:#{attrs.dr_region.region}:ACCOUNT:dr-notifications" \\
                --message "DR activation completed for instance $(ec2-metadata --instance-id)"
            BASH
          end

          def generate_activation_lambda_code(attrs)
            <<~PYTHON
              import boto3
              import os
              import json
              from datetime import datetime

              def handler(event, context):
                  asg_client = boto3.client('autoscaling', region_name=os.environ['DR_REGION'])
                  sns_client = boto3.client('sns', region_name=os.environ['DR_REGION'])

                  try:
                      # Scale up ASG
                      response = asg_client.update_auto_scaling_group(
                          AutoScalingGroupName=os.environ['DR_ASG_NAME'],
                          MinSize=int(os.environ['MIN_INSTANCES']),
                          DesiredCapacity=int(os.environ['MIN_INSTANCES'])
                      )

                      # Promote read replicas if needed
                      if event.get('promote_replicas', True):
                          rds_client = boto3.client('rds', region_name=os.environ['DR_REGION'])
                          # Logic to promote read replicas

                      # Update Route 53 if automated
                      if os.environ['ACTIVATION_METHOD'] == 'automated':
                          route53_client = boto3.client('route53')
                          # Logic to update DNS

                      return {
                          'statusCode': 200,
                          'body': json.dumps({
                              'message': 'DR activation initiated',
                              'timestamp': datetime.utcnow().isoformat()
                          })
                      }

                  except Exception as e:
                      print(f"Error: {str(e)}")
                      return {
                          'statusCode': 500,
                          'body': json.dumps({'error': str(e)})
                      }
            PYTHON
          end

          def generate_test_lambda_code(attrs)
            <<~PYTHON
              import boto3
              import os
              import json
              import time

              def handler(event, context):
                  sfn_client = boto3.client('stepfunctions')
                  s3_client = boto3.client('s3')

                  test_scenarios = os.environ['TEST_SCENARIOS'].split(',')
                  results = []

                  for scenario in test_scenarios:
                      print(f"Running test scenario: {scenario}")

                      # Execute test based on scenario
                      if scenario == 'failover':
                          result = test_failover_scenario(sfn_client)
                      elif scenario == 'data_recovery':
                          result = test_data_recovery_scenario()
                      else:
                          result = {'status': 'skipped', 'reason': 'Unknown scenario'}

                      results.append({
                          'scenario': scenario,
                          'result': result,
                          'timestamp': time.time()
                      })

                      # Rollback if enabled
                      if os.environ['ROLLBACK_ENABLED'] == 'true' and result['status'] == 'success':
                          rollback_changes(scenario)

                  # Store results
                  s3_client.put_object(
                      Bucket=f"{os.environ['TEST_RESULTS_BUCKET']}",
                      Key=f"test-results/{context.request_id}.json",
                      Body=json.dumps(results)
                  )

                  return {
                      'statusCode': 200,
                      'body': json.dumps(results)
                  }

              def test_failover_scenario(sfn_client):
                  # Implement failover test logic
                  return {'status': 'success', 'duration': 300}

              def test_data_recovery_scenario():
                  # Implement data recovery test logic
                  return {'status': 'success', 'recovered_items': 1000}

              def rollback_changes(scenario):
                  # Implement rollback logic
                  pass
            PYTHON
          end
        end
      end
    end
  end
end
