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
      # IAM roles for sustainable ML training
      module Roles
        def create_sagemaker_role(input)
          aws_iam_role(:"#{input.name}-sagemaker-role", {
            assume_role_policy: JSON.pretty_generate({
              Version: "2012-10-17",
              Statement: [{
                Effect: "Allow",
                Principal: { Service: "sagemaker.amazonaws.com" },
                Action: "sts:AssumeRole"
              }]
            }),
            managed_policy_arns: [
              "arn:aws:iam::aws:policy/AmazonSageMakerFullAccess"
            ],
            inline_policy: [{
              name: "sustainable-ml-training-policy",
              policy: JSON.pretty_generate(sagemaker_inline_policy(input))
            }],
            tags: input.tags.merge("Component" => "sustainable-ml-training")
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
              name: "ml-optimization-policy",
              policy: JSON.pretty_generate(lambda_inline_policy)
            }],
            tags: input.tags.merge("Component" => "sustainable-ml-training")
          })
        end

        private

        def sagemaker_inline_policy(input)
          {
            Version: "2012-10-17",
            Statement: [
              {
                Effect: "Allow",
                Action: %w[
                  s3:GetObject
                  s3:PutObject
                  s3:DeleteObject
                  s3:ListBucket
                ],
                Resource: [
                  "arn:aws:s3:::#{input.s3_bucket_name}",
                  "arn:aws:s3:::#{input.s3_bucket_name}/*"
                ]
              },
              {
                Effect: "Allow",
                Action: %w[
                  ec2:CreateNetworkInterface
                  ec2:DeleteNetworkInterface
                  ec2:DescribeNetworkInterfaces
                  ec2:DescribeVpcs
                  ec2:DescribeSubnets
                  ec2:DescribeSecurityGroups
                ],
                Resource: "*"
              },
              {
                Effect: "Allow",
                Action: %w[
                  fsx:DescribeFileSystems
                  fsx:CreateFileSystem
                ],
                Resource: "*"
              }
            ]
          }
        end

        def lambda_inline_policy
          {
            Version: "2012-10-17",
            Statement: [
              {
                Effect: "Allow",
                Action: %w[sagemaker:* ec2:* cloudwatch:* dynamodb:* s3:*],
                Resource: "*"
              },
              {
                Effect: "Allow",
                Action: %w[
                  logs:CreateLogGroup
                  logs:CreateLogStream
                  logs:PutLogEvents
                ],
                Resource: "*"
              }
            ]
          }
        end
      end
    end
  end
end
