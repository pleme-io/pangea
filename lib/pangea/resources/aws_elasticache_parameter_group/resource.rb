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
require 'pangea/resources/aws_elasticache_parameter_group/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS ElastiCache Parameter Group with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] ElastiCache parameter group attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_elasticache_parameter_group(name, attributes = {})
        # Validate attributes using dry-struct
        param_group_attrs = Types::ElastiCacheParameterGroupAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_elasticache_parameter_group, name) do
          name param_group_attrs.name
          family param_group_attrs.family
          description param_group_attrs.description if param_group_attrs.description
          
          # Add parameters if any are specified
          if param_group_attrs.parameters.any?
            param_group_attrs.parameters.each do |param|
              parameter do
                name param[:name]
                value param[:value]
              end
            end
          end
          
          # Apply tags if present
          if param_group_attrs.tags.any?
            tags do
              param_group_attrs.tags.each do |key, value|
                public_send(key, value)
              end
            end
          end
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_elasticache_parameter_group',
          name: name,
          resource_attributes: param_group_attrs.to_h,
          outputs: {
            id: "${aws_elasticache_parameter_group.#{name}.id}",
            name: "${aws_elasticache_parameter_group.#{name}.name}",
            arn: "${aws_elasticache_parameter_group.#{name}.arn}",
            family: "${aws_elasticache_parameter_group.#{name}.family}",
            description: "${aws_elasticache_parameter_group.#{name}.description}",
            tags_all: "${aws_elasticache_parameter_group.#{name}.tags_all}"
          },
          computed_properties: {
            engine_type: param_group_attrs.engine_type_from_family,
            is_redis_family: param_group_attrs.is_redis_family?,
            is_memcached_family: param_group_attrs.is_memcached_family?,
            family_version: param_group_attrs.family_version,
            parameter_count: param_group_attrs.parameter_count,
            is_default_group: param_group_attrs.is_default_group?,
            parameter_validation_errors: param_group_attrs.validate_parameter_values,
            memory_parameters: param_group_attrs.get_parameters_by_type(:memory),
            performance_parameters: param_group_attrs.get_parameters_by_type(:performance),
            persistence_parameters: param_group_attrs.get_parameters_by_type(:persistence),
            has_cost_implications: param_group_attrs.has_cost_implications?,
            estimated_monthly_cost: param_group_attrs.estimated_monthly_cost
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)