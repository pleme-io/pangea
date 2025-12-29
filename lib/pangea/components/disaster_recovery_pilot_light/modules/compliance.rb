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
      # Compliance and audit resources
      module Compliance
        def create_compliance_resources(name, attrs, resources, tags)
          compliance_resources = {}

          compliance_resources[:trail] = create_audit_trail(name, tags)
          compliance_resources[:config_rules] = create_config_rules(name, tags)

          compliance_resources
        end

        private

        def create_audit_trail(name, tags)
          aws_cloudtrail(
            component_resource_name(name, :audit_trail),
            {
              name: "#{name}-dr-audit-trail",
              s3_bucket_name: "#{name}-audit-logs",
              event_selector: [build_event_selector(name)],
              insight_selector: [{ insight_type: "ApiCallRateInsight" }],
              tags: tags
            }
          )
        end

        def build_event_selector(name)
          {
            read_write_type: "All",
            include_management_events: true,
            data_resource: [
              {
                type: "AWS::S3::Object",
                values: ["arn:aws:s3:::#{name}-*/*"]
              },
              {
                type: "AWS::RDS::DBCluster",
                values: ["arn:aws:rds:*:*:cluster:#{name}-*"]
              }
            ]
          }
        end

        def create_config_rules(name, tags)
          [create_rto_compliance_rule(name, tags)]
        end

        def create_rto_compliance_rule(name, tags)
          aws_config_config_rule(
            component_resource_name(name, :rto_compliance_rule),
            {
              name: "#{name}-rto-compliance",
              description: "Verify RTO compliance",
              source: {
                owner: "AWS",
                source_identifier: "BACKUP_RECOVERY_POINT_CREATED"
              },
              scope: {
                compliance_resource_types: ["AWS::RDS::DBCluster", "AWS::EC2::Instance"]
              },
              tags: tags
            }
          )
        end
      end
    end
  end
end
