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
    module SpotInstanceCarbonOptimizer
      # IAM role creation methods
      module Roles
        def create_fleet_role(input)
          aws_iam_role(:"#{input.name}-fleet-role", {
            assume_role_policy: JSON.pretty_generate({
              Version: "2012-10-17",
              Statement: [{
                Effect: "Allow",
                Principal: { Service: "spotfleet.amazonaws.com" },
                Action: "sts:AssumeRole"
              }]
            }),
            managed_policy_arns: [
              "arn:aws:iam::aws:policy/service-role/AmazonEC2SpotFleetTaggingRole"
            ],
            inline_policy: [{
              name: "spot-fleet-policy",
              policy: JSON.pretty_generate({
                Version: "2012-10-17",
                Statement: [
                  {
                    Effect: "Allow",
                    Action: [
                      "ec2:*",
                      "iam:PassRole",
                      "sns:Publish"
                    ],
                    Resource: "*"
                  }
                ]
              })
            }],
            tags: input.tags.merge("Component" => "spot-carbon-optimizer")
          })
        end

        def create_lambda_role(input)
          aws_iam_role(:"#{input.name}-lambda-role", {
            assume_role_policy: JSON.pretty_generate({
              Version: "2012-10-17",
              Statement: [{
                Effect: "Allow",
                Principal: { Service: "lambda.amazonaws.com" },
                Action: "sts:AssumeRole"
              }]
            }),
            inline_policy: [{
              name: "carbon-optimizer-policy",
              policy: JSON.pretty_generate({
                Version: "2012-10-17",
                Statement: [
                  {
                    Effect: "Allow",
                    Action: [
                      "ec2:*SpotFleet*",
                      "ec2:*SpotInstance*",
                      "ec2:Describe*",
                      "ec2:CreateTags",
                      "ec2:ModifyInstanceAttribute"
                    ],
                    Resource: "*"
                  },
                  {
                    Effect: "Allow",
                    Action: [
                      "dynamodb:*"
                    ],
                    Resource: "*"
                  },
                  {
                    Effect: "Allow",
                    Action: [
                      "cloudwatch:PutMetricData",
                      "cloudwatch:GetMetricStatistics"
                    ],
                    Resource: "*"
                  },
                  {
                    Effect: "Allow",
                    Action: [
                      "logs:CreateLogGroup",
                      "logs:CreateLogStream",
                      "logs:PutLogEvents"
                    ],
                    Resource: "*"
                  }
                ]
              })
            }],
            tags: input.tags.merge("Component" => "spot-carbon-optimizer")
          })
        end
      end
    end
  end
end
