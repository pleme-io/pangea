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
      # IAM role resources for Green Data Lifecycle component
      module Roles
        private

        def create_lifecycle_role(input)
          aws_iam_role(:"#{input.name}-lifecycle-role", {
            assume_role_policy: JSON.pretty_generate({
              Version: "2012-10-17",
              Statement: [{
                Effect: "Allow",
                Principal: { Service: "s3.amazonaws.com" },
                Action: "sts:AssumeRole"
              }]
            }),
            inline_policy: [{
              name: "lifecycle-transition-policy",
              policy: JSON.pretty_generate({
                Version: "2012-10-17",
                Statement: [{
                  Effect: "Allow",
                  Action: [
                    "s3:GetObject",
                    "s3:PutObject",
                    "s3:DeleteObject",
                    "glacier:UploadArchive",
                    "glacier:DeleteArchive"
                  ],
                  Resource: "*"
                }]
              })
            }],
            tags: component_tags(input)
          })
        end

        def create_analyzer_role(input)
          aws_iam_role(:"#{input.name}-analyzer-role", {
            assume_role_policy: JSON.pretty_generate({
              Version: "2012-10-17",
              Statement: [{
                Effect: "Allow",
                Principal: { Service: "lambda.amazonaws.com" },
                Action: "sts:AssumeRole"
              }]
            }),
            inline_policy: [{
              name: "analyzer-policy",
              policy: JSON.pretty_generate({
                Version: "2012-10-17",
                Statement: [
                  {
                    Effect: "Allow",
                    Action: [
                      "s3:GetObject",
                      "s3:ListBucket",
                      "s3:GetObjectTagging",
                      "s3:PutObjectTagging",
                      "s3:GetBucketInventoryConfiguration",
                      "s3:GetMetricsConfiguration"
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
            tags: component_tags(input)
          })
        end
      end
    end
  end
end
