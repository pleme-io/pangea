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
      # Type-safe resource function for AWS Resource Explorer View
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Resource attributes following AWS provider schema
      # @return [Pangea::Resources::Reference] Resource reference for chaining
      # 
      # @see https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/resource_explorer_view
      #
      # @example Application-specific resource view
      #   aws_resource_explorer_view(:app_resources_view, {
      #     name: "ApplicationResources",
      #     filters: {
      #       filter_string: "tag:Application=MyApp"
      #     },
      #     included_properties: [
      #       {
      #         name: "tags"
      #       },
      #       {
      #         name: "region"
      #       }
      #     ],
      #     tags: {
      #       "Application" => "MyApp",
      #       "ViewType" => "application-specific"
      #     }
      #   })
      #
      # @example Production environment view
      #   aws_resource_explorer_view(:production_view, {
      #     name: "ProductionEnvironment",
      #     filters: {
      #       filter_string: "tag:Environment=production AND (resourcetype:ec2:instance OR resourcetype:rds:db-instance)"
      #     },
      #     included_properties: [
      #       {
      #         name: "tags"
      #       },
      #       {
      #         name: "resourceType"
      #       },
      #       {
      #         name: "region"
      #       }
      #     ]
      #   })
      def aws_resource_explorer_view(name, attributes)
        transformed = Base.transform_attributes(attributes, {
          name: {
            description: "Name of the resource view",
            type: :string,
            required: true
          },
          filters: {
            description: "Filters for the resource view",
            type: :hash,
            properties: {
              filter_string: {
                description: "Filter string for resources",
                type: :string,
                required: true
              }
            }
          },
          included_properties: {
            description: "Properties to include in search results",
            type: :array,
            items: {
              type: :hash,
              properties: {
                name: {
                  description: "Name of the property to include",
                  type: :string,
                  required: true
                }
              }
            }
          },
          tags: {
            description: "Resource tags",
            type: :map
          }
        })

        resource_block = resource(:aws_resourceexplorer2_view, name, transformed)
        
        Reference.new(
          type: :aws_resourceexplorer2_view,
          name: name,
          attributes: {
            arn: "#{resource_block}.arn",
            id: "#{resource_block}.id",
            name: "#{resource_block}.name",
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