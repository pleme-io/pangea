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
require 'pangea/resources/aws_elasticache_subnet_group/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS ElastiCache Subnet Group with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] ElastiCache subnet group attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_elasticache_subnet_group(name, attributes = {})
        # Validate attributes using dry-struct
        subnet_group_attrs = Types::ElastiCacheSubnetGroupAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_elasticache_subnet_group, name) do
          name subnet_group_attrs.name
          subnet_ids subnet_group_attrs.subnet_ids
          description subnet_group_attrs.description if subnet_group_attrs.description
          
          # Apply tags if present
          if subnet_group_attrs.tags.any?
            tags do
              subnet_group_attrs.tags.each do |key, value|
                public_send(key, value)
              end
            end
          end
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_elasticache_subnet_group',
          name: name,
          resource_attributes: subnet_group_attrs.to_h,
          outputs: {
            id: "${aws_elasticache_subnet_group.#{name}.id}",
            name: "${aws_elasticache_subnet_group.#{name}.name}",
            arn: "${aws_elasticache_subnet_group.#{name}.arn}",
            description: "${aws_elasticache_subnet_group.#{name}.description}",
            subnet_ids: "${aws_elasticache_subnet_group.#{name}.subnet_ids}",
            vpc_id: "${aws_elasticache_subnet_group.#{name}.vpc_id}",
            tags_all: "${aws_elasticache_subnet_group.#{name}.tags_all}"
          },
          computed_properties: {
            subnet_count: subnet_group_attrs.subnet_count,
            supports_multi_az: subnet_group_attrs.supports_multi_az?,
            is_single_az: subnet_group_attrs.is_single_az?,
            configuration_warnings: subnet_group_attrs.validate_configuration,
            has_cost_implications: subnet_group_attrs.has_cost_implications?,
            estimated_monthly_cost: subnet_group_attrs.estimated_monthly_cost
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)