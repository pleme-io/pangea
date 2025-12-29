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
      # IAM role resources for Carbon Aware Compute
      module Roles
        def create_execution_role(input)
          aws_iam_role(:"#{input.name}-execution-role", {
            assume_role_policy: base_assume_role_policy("lambda.amazonaws.com"),
            inline_policy: generate_inline_policy(
              "carbon-aware-execution-policy",
              execution_role_statements
            ),
            tags: component_tags(input)
          })
        end

        def create_scheduler_role(input)
          aws_iam_role(:"#{input.name}-scheduler-role", {
            assume_role_policy: base_assume_role_policy("scheduler.amazonaws.com"),
            inline_policy: generate_inline_policy(
              "invoke-lambda-policy",
              scheduler_role_statements
            ),
            tags: component_tags(input)
          })
        end

        private

        def execution_role_statements
          [
            dynamodb_statement,
            cloudwatch_statement,
            ec2_statement,
            logs_statement
          ]
        end

        def dynamodb_statement
          {
            Effect: "Allow",
            Action: %w[
              dynamodb:GetItem
              dynamodb:PutItem
              dynamodb:UpdateItem
              dynamodb:Query
              dynamodb:Scan
            ],
            Resource: ["*"]
          }
        end

        def cloudwatch_statement
          {
            Effect: "Allow",
            Action: %w[
              cloudwatch:PutMetricData
              cloudwatch:GetMetricStatistics
            ],
            Resource: ["*"]
          }
        end

        def ec2_statement
          {
            Effect: "Allow",
            Action: %w[
              ec2:DescribeRegions
              ec2:DescribeInstances
              ec2:DescribeSpotPriceHistory
            ],
            Resource: ["*"]
          }
        end

        def logs_statement
          {
            Effect: "Allow",
            Action: %w[
              logs:CreateLogGroup
              logs:CreateLogStream
              logs:PutLogEvents
            ],
            Resource: ["*"]
          }
        end

        def scheduler_role_statements
          [{
            Effect: "Allow",
            Action: "lambda:InvokeFunction",
            Resource: "*"
          }]
        end
      end
    end
  end
end
