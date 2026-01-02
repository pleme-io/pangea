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

require 'json'

module Pangea
  module Components
    module SiemSecurityPlatform
      module Ingestion
        # IAM role and policy creation for ingestion resources
        module IamPolicies
          def create_firehose_role(role_name, attrs, resources)
            role = aws_iam_role(role_name, {
              name: role_name.to_s,
              assume_role_policy: firehose_assume_role_policy,
              tags: component_tags('siem_security_platform', role_name, attrs.tags)
            })

            aws_iam_role_policy(:"#{role_name}_policy", {
              role: role.id,
              policy: firehose_role_policy(resources)
            })

            role
          end

          def firehose_assume_role_policy
            JSON.pretty_generate({
              Version: "2012-10-17",
              Statement: [{
                Action: "sts:AssumeRole",
                Effect: "Allow",
                Principal: { Service: "firehose.amazonaws.com" }
              }]
            })
          end

          def firehose_role_policy(resources)
            JSON.pretty_generate({
              Version: "2012-10-17",
              Statement: [
                { Effect: "Allow", Action: %w[es:ESHttpPost es:ESHttpPut],
                  Resource: [resources[:opensearch_domain].arn, "#{resources[:opensearch_domain].arn}/*"] },
                { Effect: "Allow", Action: %w[s3:GetObject s3:PutObject],
                  Resource: "#{resources[:s3_buckets][:backup].arn}/*" },
                { Effect: "Allow", Action: %w[kms:Decrypt kms:GenerateDataKey],
                  Resource: resources[:kms_keys][:main].arn },
                { Effect: "Allow", Action: %w[logs:CreateLogGroup logs:CreateLogStream logs:PutLogEvents],
                  Resource: "*" },
                { Effect: "Allow", Action: ["lambda:InvokeFunction"],
                  Resource: "arn:aws:lambda:*:*:function:siem-*" }
              ]
            })
          end

          def create_logs_role(name, source_name, attrs, resources)
            role_name = component_resource_name(name, :logs_role, source_name)
            role = aws_iam_role(role_name, {
              name: role_name.to_s,
              assume_role_policy: logs_assume_role_policy,
              tags: component_tags('siem_security_platform', name, attrs.tags)
            })

            aws_iam_role_policy(:"#{role_name}_policy", {
              role: role.id,
              policy: logs_role_policy(resources, source_name)
            })

            role.arn
          end

          def logs_assume_role_policy
            JSON.pretty_generate({
              Version: "2012-10-17",
              Statement: [{
                Action: "sts:AssumeRole",
                Effect: "Allow",
                Principal: { Service: "logs.amazonaws.com" }
              }]
            })
          end

          def logs_role_policy(resources, source_name)
            JSON.pretty_generate({
              Version: "2012-10-17",
              Statement: [{
                Effect: "Allow",
                Action: %w[firehose:PutRecord firehose:PutRecordBatch],
                Resource: resources[:firehose_streams][source_name].arn
              }]
            })
          end
        end
      end
    end
  end
end
