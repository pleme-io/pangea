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
      # Security resources: KMS keys, security groups, IAM roles
      module Security
        def create_security_resources(name, attrs, resources)
          create_kms_key(name, attrs, resources)
          create_opensearch_security_group(name, attrs, resources)
        end

        private

        def create_kms_key(name, attrs, resources)
          kms_key_name = component_resource_name(name, :kms_key)
          resources[:kms_keys][:main] = aws_kms_key(kms_key_name, {
            description: "SIEM encryption key for #{name}",
            key_policy: generate_kms_policy(name),
            tags: component_tags('siem_security_platform', name, attrs.tags)
          })

          aws_kms_alias(:"#{kms_key_name}_alias", {
            name: "alias/siem-#{name}",
            target_key_id: resources[:kms_keys][:main].id
          })
        end

        def create_opensearch_security_group(name, attrs, resources)
          sg_name = component_resource_name(name, :opensearch_sg)
          resources[:security_groups][:opensearch] = aws_security_group(sg_name, {
            name: "siem-opensearch-#{name}",
            description: "Security group for SIEM OpenSearch domain",
            vpc_id: attrs.vpc_ref,
            tags: component_tags('siem_security_platform', name, attrs.tags)
          })

          aws_vpc_security_group_ingress_rule(:"#{sg_name}_https", {
            security_group_id: resources[:security_groups][:opensearch].id,
            description: "Allow HTTPS for OpenSearch",
            from_port: 443,
            to_port: 443,
            ip_protocol: 'tcp',
            cidr_ipv4: '10.0.0.0/8'
          })
        end

        def generate_kms_policy(name)
          JSON.pretty_generate({
            Version: "2012-10-17",
            Statement: [
              {
                Sid: "Enable IAM User Permissions",
                Effect: "Allow",
                Principal: { AWS: "arn:aws:iam::#{aws_account_id}:root" },
                Action: "kms:*",
                Resource: "*"
              },
              {
                Sid: "Allow use of the key for SIEM services",
                Effect: "Allow",
                Principal: {
                  Service: %w[
                    es.amazonaws.com
                    firehose.amazonaws.com
                    lambda.amazonaws.com
                    logs.amazonaws.com
                  ]
                },
                Action: %w[kms:Decrypt kms:GenerateDataKey],
                Resource: "*"
              }
            ]
          })
        end

        def create_log_group(name, type, attrs, resources)
          log_group_name = component_resource_name(name, :log_group, type)
          log_group = aws_cloudwatch_log_group(log_group_name, {
            name: "/aws/siem/#{name}/#{type}",
            retention_in_days: attrs.incident_response[:retention_days],
            kms_key_id: resources[:kms_keys][:main].arn,
            tags: component_tags('siem_security_platform', name, attrs.tags)
          })

          resources[:cloudwatch_logs][type] = log_group
          log_group.arn
        end
      end
    end
  end
end
