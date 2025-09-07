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
require 'pangea/resources/aws_db_parameter_group/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS RDS DB Parameter Group with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] DB parameter group attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_db_parameter_group(name, attributes = {})
        # Validate attributes using dry-struct
        param_group_attrs = Types::DbParameterGroupAttributes.new(attributes)
        
        # Validate parameters for the specific engine family
        param_group_attrs.validate_parameters_for_family
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_db_parameter_group, name) do
          name param_group_attrs.name
          family param_group_attrs.family
          description param_group_attrs.effective_description
          
          # Add parameters if present
          if param_group_attrs.parameters.any?
            param_group_attrs.parameters.each do |param|
              parameter do
                name param.name
                value param.value
                apply_method param.apply_method if param.apply_method
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
          type: 'aws_db_parameter_group',
          name: name,
          resource_attributes: param_group_attrs.to_h,
          outputs: {
            id: "${aws_db_parameter_group.#{name}.id}",
            arn: "${aws_db_parameter_group.#{name}.arn}",
            name: "${aws_db_parameter_group.#{name}.name}",
            description: "${aws_db_parameter_group.#{name}.description}",
            family: "${aws_db_parameter_group.#{name}.family}"
          },
          computed_properties: {
            engine: param_group_attrs.engine,
            engine_version: param_group_attrs.engine_version,
            is_aurora: param_group_attrs.is_aurora?,
            parameter_count: param_group_attrs.parameter_count,
            requires_reboot: param_group_attrs.requires_reboot?,
            reboot_required_parameters: param_group_attrs.reboot_required_parameters.map(&:name),
            immediate_parameters: param_group_attrs.immediate_parameters.map(&:name),
            effective_description: param_group_attrs.effective_description,
            estimated_monthly_cost: param_group_attrs.estimated_monthly_cost
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)