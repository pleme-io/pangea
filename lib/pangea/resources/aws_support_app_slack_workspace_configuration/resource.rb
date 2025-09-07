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
      # Type-safe resource function for AWS Support App Slack Workspace Configuration
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Resource attributes following AWS provider schema
      # @return [Pangea::Resources::Reference] Resource reference for chaining
      # 
      # @see https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/support_app_slack_workspace_configuration
      #
      # @example Basic Slack workspace configuration
      #   aws_support_app_slack_workspace_configuration(:main_workspace, {
      #     team_id: "T1234567890",
      #     version_id: "v1"
      #   })
      #
      # @example Slack workspace with specific version
      #   aws_support_app_slack_workspace_configuration(:workspace_config, {
      #     team_id: slack_team_id_ref,
      #     version_id: "v2024.1"
      #   })
      def aws_support_app_slack_workspace_configuration(name, attributes)
        transformed = Base.transform_attributes(attributes, {
          team_id: {
            description: "Slack team ID",
            type: :string,
            required: true
          },
          version_id: {
            description: "Version ID for the workspace configuration",
            type: :string
          }
        })

        resource_block = resource(:aws_supportapp_slack_workspace_configuration, name, transformed)
        
        Reference.new(
          type: :aws_supportapp_slack_workspace_configuration,
          name: name,
          attributes: {
            id: "#{resource_block}.id",
            team_id: "#{resource_block}.team_id",
            version_id: "#{resource_block}.version_id"
          },
          resource: resource_block
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)