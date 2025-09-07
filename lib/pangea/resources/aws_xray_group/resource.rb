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
      # Type-safe resource function for AWS X-Ray Group
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Resource attributes following AWS provider schema
      # @return [Pangea::Resources::Reference] Resource reference for chaining
      # 
      # @see https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/xray_group
      #
      # @example Basic X-Ray group for service filtering
      #   aws_xray_group(:api_service_group, {
      #     group_name: "ApiServiceGroup",
      #     filter_expression: 'service("my-api-service")'
      #   })
      #
      # @example Error-focused X-Ray group
      #   aws_xray_group(:error_analysis_group, {
      #     group_name: "ErrorAnalysisGroup",
      #     filter_expression: 'error = true AND responsetime > 5',
      #     insights_configuration: {
      #       insights_enabled: true,
      #       notifications_enabled: true
      #     },
      #     tags: {
      #       Purpose: "error-monitoring",
      #       Team: "platform"
      #     }
      #   })
      #
      # @example Regional service analysis group
      #   aws_xray_group(:regional_services, {
      #     group_name: "RegionalServicesGroup",
      #     filter_expression: 'service("payment-service") OR service("user-service")',
      #     insights_configuration: {
      #       insights_enabled: true,
      #       notifications_enabled: false
      #     }
      #   })
      def aws_xray_group(name, attributes)
        transformed = Base.transform_attributes(attributes, {
          group_name: {
            description: "Name of the X-Ray group",
            type: :string,
            required: true
          },
          filter_expression: {
            description: "Expression to filter traces for this group",
            type: :string,
            required: true
          },
          insights_configuration: {
            description: "Configuration for X-Ray insights",
            type: :hash,
            properties: {
              insights_enabled: {
                description: "Enable insights for this group",
                type: :boolean,
                default: false
              },
              notifications_enabled: {
                description: "Enable notifications for insights",
                type: :boolean,
                default: false
              }
            }
          },
          tags: {
            description: "Resource tags",
            type: :map
          }
        })

        resource_block = resource(:aws_xray_group, name, transformed)
        
        Reference.new(
          type: :aws_xray_group,
          name: name,
          attributes: {
            arn: "#{resource_block}.arn",
            id: "#{resource_block}.id",
            group_name: "#{resource_block}.group_name",
            tags_all: "#{resource_block}.tags_all"
          },
          resource: resource_block
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)