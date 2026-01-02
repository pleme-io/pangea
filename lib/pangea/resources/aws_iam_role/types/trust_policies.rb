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
  module Resources
    module AWS
      module Types
        # Pre-defined trust policies for common scenarios
        module TrustPolicies
          # EC2 instance service role
          def self.ec2_service
            {
              Version: "2012-10-17",
              Statement: [{
                Effect: "Allow",
                Principal: { Service: "ec2.amazonaws.com" },
                Action: "sts:AssumeRole"
              }]
            }
          end

          # Lambda function service role
          def self.lambda_service
            {
              Version: "2012-10-17",
              Statement: [{
                Effect: "Allow",
                Principal: { Service: "lambda.amazonaws.com" },
                Action: "sts:AssumeRole"
              }]
            }
          end

          # ECS task service role
          def self.ecs_task_service
            {
              Version: "2012-10-17",
              Statement: [{
                Effect: "Allow",
                Principal: { Service: "ecs-tasks.amazonaws.com" },
                Action: "sts:AssumeRole"
              }]
            }
          end

          # Cross-account trust policy
          def self.cross_account(account_id)
            {
              Version: "2012-10-17",
              Statement: [{
                Effect: "Allow",
                Principal: { AWS: "arn:aws:iam::#{account_id}:root" },
                Action: "sts:AssumeRole"
              }]
            }
          end

          # SAML federated access
          def self.saml_federated(provider_arn)
            {
              Version: "2012-10-17",
              Statement: [{
                Effect: "Allow",
                Principal: { Federated: provider_arn },
                Action: "sts:AssumeRoleWithSAML",
                Condition: {
                  StringEquals: {
                    "SAML:aud": "https://signin.aws.amazon.com/saml"
                  }
                }
              }]
            }
          end
        end
      end
    end
  end
end
