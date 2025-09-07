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
      # Type-safe resource function for AWS Support App Slack Channel Configuration
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Resource attributes following AWS provider schema
      # @return [Pangea::Resources::Reference] Resource reference for chaining
      # 
      # @see https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/support_app_slack_channel_configuration
      #
      # @example Production support channel configuration
      #   aws_support_app_slack_channel_configuration(:production_support, {
      #     channel_id: "C1234567890",
      #     channel_name: "#production-support",
      #     team_id: "T1234567890",
      #     channel_role_arn: support_role.arn,
      #     notify_on_add_correspondence_to_case: true,
      #     notify_on_case_severity: "high",
      #     notify_on_create_or_reopen_case: true,
      #     notify_on_resolve_case: true
      #   })
      #
      # @example Critical issues only channel
      #   aws_support_app_slack_channel_configuration(:critical_issues, {
      #     channel_id: "C0987654321",
      #     channel_name: "#critical-alerts",
      #     team_id: team_id_ref,
      #     channel_role_arn: critical_support_role.arn,
      #     notify_on_case_severity: "critical",
      #     notify_on_create_or_reopen_case: true
      #   })
      def aws_support_app_slack_channel_configuration(name, attributes)
        transformed = Base.transform_attributes(attributes, {
          channel_id: {
            description: "Slack channel ID",
            type: :string,
            required: true
          },
          channel_name: {
            description: "Slack channel name",
            type: :string
          },
          team_id: {
            description: "Slack team ID",
            type: :string,
            required: true
          },
          channel_role_arn: {
            description: "ARN of IAM role for the channel",
            type: :string,
            required: true
          },
          notify_on_add_correspondence_to_case: {
            description: "Whether to notify when correspondence is added to case",
            type: :boolean,
            default: false
          },
          notify_on_case_severity: {
            description: "Case severity level to notify on (none, all, high, critical)",
            type: :string,
            default: "none",
            enum: ["none", "all", "high", "critical"]
          },
          notify_on_create_or_reopen_case: {
            description: "Whether to notify when case is created or reopened",
            type: :boolean,
            default: false
          },
          notify_on_resolve_case: {
            description: "Whether to notify when case is resolved",
            type: :boolean,
            default: false
          }
        })

        resource_block = resource(:aws_supportapp_slack_channel_configuration, name, transformed)
        
        Reference.new(
          type: :aws_supportapp_slack_channel_configuration,
          name: name,
          attributes: {
            id: "#{resource_block}.id",
            channel_id: "#{resource_block}.channel_id",
            team_id: "#{resource_block}.team_id"
          },
          resource: resource_block
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)