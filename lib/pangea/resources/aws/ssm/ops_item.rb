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


require 'pangea/resources/base'
require 'pangea/resources/reference'

module Pangea
  module Resources
    module AWS
      module SSM
        # AWS Systems Manager OpsItem resource
        # Creates operational issues for tracking and managing incidents,
        # change requests, and other operational activities in OpsCenter.
        module OpsItem
          # Creates an AWS Systems Manager OpsItem
          #
          # @param name [Symbol] The unique name for this resource instance
          # @param attributes [Hash] The configuration options for the OpsItem
          # @option attributes [String] :title Title of the OpsItem (required)
          # @option attributes [String] :description Description of the OpsItem (required)
          # @option attributes [String] :source Source system creating the OpsItem (required)
          # @option attributes [String] :category Category of the OpsItem
          # @option attributes [String] :severity Severity level (Critical, High, Medium, Low)
          # @option attributes [Integer] :priority Priority level (1-5)
          # @option attributes [Hash] :operational_data Additional structured data
          # @option attributes [Array<Hash>] :notifications SNS topic configurations
          # @option attributes [Array<Hash>] :related_ops_items Related OpsItem IDs
          # @option attributes [Hash] :tags Tags to apply to the OpsItem
          #
          # @example Critical security incident OpsItem
          #   security_incident = aws_ssm_ops_item(:security_breach, {
          #     title: "Critical Security Incident - Unauthorized Access Detected",
          #     description: "Suspicious login activity detected from multiple IP addresses",
          #     source: "SecurityMonitoring",
          #     category: "Security",
          #     severity: "Critical",
          #     priority: 1,
          #     operational_data: {
          #       "/aws/ssm/incident/type" => {
          #         "Value" => "Security Breach",
          #         "Type" => "SearchableString"
          #       },
          #       "/aws/ssm/incident/affected_systems" => {
          #         "Value" => "Web Application, Database",
          #         "Type" => "SearchableString"
          #       },
          #       "/aws/ssm/incident/detection_time" => {
          #         "Value" => Time.now.iso8601,
          #         "Type" => "String"
          #       }
          #     },
          #     notifications: [
          #       {
          #         arn: ref(:aws_sns_topic, :security_alerts, :arn),
          #         type: "Command"
          #       },
          #       {
          #         arn: ref(:aws_sns_topic, :incident_response, :arn),
          #         type: "Invocation"
          #       }
          #     ],
          #     tags: {
          #       "Severity" => "Critical",
          #       "Team" => "Security",
          #       "IncidentType" => "Breach"
          #     }
          #   })
          #
          # @example Planned maintenance OpsItem
          #   maintenance_ops = aws_ssm_ops_item(:database_maintenance, {
          #     title: "Database Maintenance Window - Patch Installation",
          #     description: "Apply security patches to production database servers",
          #     source: "ChangeManagement",
          #     category: "ChangeRequest",
          #     severity: "Medium",
          #     priority: 3,
          #     operational_data: {
          #       "/aws/ssm/change/type" => {
          #         "Value" => "Planned Maintenance",
          #         "Type" => "SearchableString"
          #       },
          #       "/aws/ssm/change/window" => {
          #         "Value" => "2024-01-15T02:00:00Z to 2024-01-15T06:00:00Z",
          #         "Type" => "String"
          #       },
          #       "/aws/ssm/change/approval_required" => {
          #         "Value" => "true",
          #         "Type" => "String"
          #       }
          #     },
          #     notifications: [
          #       {
          #         arn: ref(:aws_sns_topic, :maintenance_notifications, :arn),
          #         type: "Command"
          #       }
          #     ],
          #     tags: {
          #       "MaintenanceType" => "DatabasePatching",
          #       "Environment" => "Production"
          #     }
          #   })
          #
          # @return [ResourceReference] The OpsItem resource reference
          def aws_ssm_ops_item(name, attributes = {})
            resource(:aws_ssm_ops_item, name) do
              title attributes[:title] if attributes[:title]
              description attributes[:description] if attributes[:description]
              source attributes[:source] if attributes[:source]
              category attributes[:category] if attributes[:category]
              severity attributes[:severity] if attributes[:severity]
              priority attributes[:priority] if attributes[:priority]
              
              # Operational data
              if attributes[:operational_data]
                operational_data attributes[:operational_data]
              end
              
              # Notifications
              if attributes[:notifications]
                attributes[:notifications].each do |notification|
                  notifications do
                    arn notification[:arn]
                    type notification[:type] if notification[:type]
                  end
                end
              end
              
              # Related OpsItems
              if attributes[:related_ops_items]
                attributes[:related_ops_items].each do |related|
                  related_ops_items do
                    ops_item_id related[:ops_item_id]
                  end
                end
              end
              
              # Tags
              if attributes[:tags]
                tags attributes[:tags]
              end
            end
            
            ResourceReference.new(
              type: 'aws_ssm_ops_item',
              name: name,
              resource_attributes: attributes,
              outputs: {
                id: "${aws_ssm_ops_item.#{name}.id}",
                ops_item_id: "${aws_ssm_ops_item.#{name}.ops_item_id}",
                arn: "${aws_ssm_ops_item.#{name}.arn}"
              },
              computed_properties: {
                is_critical: attributes[:severity] == 'Critical',
                is_high_priority: attributes[:priority] && attributes[:priority] <= 2,
                has_notifications: attributes[:notifications]&.any? || false,
                category_type: attributes[:category]&.downcase&.to_sym
              }
            )
          end
        end
      end
    end
  end
end