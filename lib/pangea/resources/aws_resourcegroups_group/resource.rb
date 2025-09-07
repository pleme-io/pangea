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
      # Type-safe resource function for AWS Resource Groups Group
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Resource attributes following AWS provider schema
      # @return [Pangea::Resources::Reference] Resource reference for chaining
      # 
      # @see https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/resourcegroups_group
      #
      # @example Tag-based resource group for application resources
      #   aws_resourcegroups_group(:app_resources, {
      #     name: "MyApplication-Production",
      #     description: "All resources for MyApplication in production environment",
      #     resource_query: {
      #       query: jsonencode({
      #         "ResourceTypeFilters": [
      #           "AWS::AllSupported"
      #         ],
      #         "TagFilters": [
      #           {
      #             "Key": "Application",
      #             "Values": ["MyApplication"]
      #           },
      #           {
      #             "Key": "Environment",
      #             "Values": ["production"]
      #           }
      #         ]
      #       })
      #     },
      #     tags: {
      #       "Purpose" => "resource-organization",
      #       "ManagedBy" => "platform-team"
      #     }
      #   })
      #
      # @example CloudFormation stack-based resource group
      #   aws_resourcegroups_group(:stack_resources, {
      #     name: "CloudFormationStack-Resources",
      #     description: "Resources from specific CloudFormation stacks",
      #     resource_query: {
      #       query: jsonencode({
      #         "ResourceTypeFilters": ["AWS::AllSupported"],
      #         "StackIdentifier": cloudformation_stack.name
      #       })
      #     },
      #     configuration: [
      #       {
      #         type: "AWS::ResourceGroups::Generic",
      #         parameters: [
      #           {
      #             name: "allowed-resource-types",
      #             values: ["AWS::EC2::Instance", "AWS::RDS::DBInstance"]
      #           }
      #         ]
      #       }
      #     ]
      #   })
      def aws_resourcegroups_group(name, attributes)
        transformed = Base.transform_attributes(attributes, {
          name: {
            description: "Name of the resource group",
            type: :string,
            required: true
          },
          description: {
            description: "Description of the resource group",
            type: :string
          },
          resource_query: {
            description: "Resource query configuration",
            type: :hash,
            required: true,
            properties: {
              query: {
                description: "Query string in JSON format",
                type: :string,
                required: true
              },
              type: {
                description: "Type of query (TAG_FILTERS_1_0 or CLOUDFORMATION_STACK_1_0)",
                type: :string,
                default: "TAG_FILTERS_1_0",
                enum: ["TAG_FILTERS_1_0", "CLOUDFORMATION_STACK_1_0"]
              }
            }
          },
          configuration: {
            description: "Configuration for the resource group",
            type: :array,
            items: {
              type: :hash,
              properties: {
                type: {
                  description: "Configuration type",
                  type: :string,
                  required: true
                },
                parameters: {
                  description: "Configuration parameters",
                  type: :array,
                  items: {
                    type: :hash,
                    properties: {
                      name: {
                        description: "Parameter name",
                        type: :string,
                        required: true
                      },
                      values: {
                        description: "Parameter values",
                        type: :array,
                        required: true
                      }
                    }
                  }
                }
              }
            }
          },
          tags: {
            description: "Resource tags",
            type: :map
          }
        })

        resource_block = resource(:aws_resourcegroups_group, name, transformed)
        
        Reference.new(
          type: :aws_resourcegroups_group,
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