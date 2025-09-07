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
      # Type-safe resource function for AWS Resource Explorer Index
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Resource attributes following AWS provider schema
      # @return [Pangea::Resources::Reference] Resource reference for chaining
      # 
      # @see https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/resource_explorer_index
      #
      # @example Regional Resource Explorer index
      #   aws_resource_explorer_index(:regional_index, {
      #     type: "LOCAL",
      #     tags: {
      #       "Purpose" => "resource-discovery",
      #       "Region" => "us-east-1"
      #     }
      #   })
      #
      # @example Aggregator Resource Explorer index
      #   aws_resource_explorer_index(:aggregator_index, {
      #     type: "AGGREGATOR",
      #     tags: {
      #       "Purpose" => "central-resource-discovery",
      #       "Role" => "aggregator"
      #     }
      #   })
      def aws_resource_explorer_index(name, attributes)
        transformed = Base.transform_attributes(attributes, {
          type: {
            description: "Type of the index (LOCAL or AGGREGATOR)",
            type: :string,
            required: true,
            enum: ["LOCAL", "AGGREGATOR"]
          },
          tags: {
            description: "Resource tags",
            type: :map
          }
        })

        resource_block = resource(:aws_resourceexplorer2_index, name, transformed)
        
        Reference.new(
          type: :aws_resourceexplorer2_index,
          name: name,
          attributes: {
            arn: "#{resource_block}.arn",
            id: "#{resource_block}.id",
            type: "#{resource_block}.type",
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