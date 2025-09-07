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
require 'pangea/resources/aws_ssm_parameter/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS Systems Manager Parameter with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] SSM parameter attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_ssm_parameter(name, attributes = {})
        # Validate attributes using dry-struct
        parameter_attrs = Types::SsmParameterAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_ssm_parameter, name) do
          parameter_name parameter_attrs.name
          type parameter_attrs.type
          value parameter_attrs.value

          # Description
          if parameter_attrs.description
            description parameter_attrs.description
          end

          # KMS Key ID for SecureString
          if parameter_attrs.key_id
            key_id parameter_attrs.key_id
          end

          # Parameter tier
          tier parameter_attrs.tier

          # Allowed pattern
          if parameter_attrs.allowed_pattern
            allowed_pattern parameter_attrs.allowed_pattern
          end

          # Data type
          if parameter_attrs.data_type
            data_type parameter_attrs.data_type
          end

          # Overwrite setting
          overwrite parameter_attrs.overwrite

          # Apply tags if present
          if parameter_attrs.tags.any?
            tags do
              parameter_attrs.tags.each do |key, value|
                public_send(key, value)
              end
            end
          end
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_ssm_parameter',
          name: name,
          resource_attributes: parameter_attrs.to_h,
          outputs: {
            name: "${aws_ssm_parameter.#{name}.name}",
            arn: "${aws_ssm_parameter.#{name}.arn}",
            type: "${aws_ssm_parameter.#{name}.type}",
            value: "${aws_ssm_parameter.#{name}.value}",
            version: "${aws_ssm_parameter.#{name}.version}",
            tier: "${aws_ssm_parameter.#{name}.tier}",
            data_type: "${aws_ssm_parameter.#{name}.data_type}",
            key_id: "${aws_ssm_parameter.#{name}.key_id}",
            tags_all: "${aws_ssm_parameter.#{name}.tags_all}"
          },
          computed_properties: {
            is_secure_string: parameter_attrs.is_secure_string?,
            is_string_list: parameter_attrs.is_string_list?,
            is_string: parameter_attrs.is_string?,
            uses_kms_key: parameter_attrs.uses_kms_key?,
            is_advanced_tier: parameter_attrs.is_advanced_tier?,
            is_standard_tier: parameter_attrs.is_standard_tier?,
            has_description: parameter_attrs.has_description?,
            has_allowed_pattern: parameter_attrs.has_allowed_pattern?,
            has_data_type: parameter_attrs.has_data_type?,
            allows_overwrite: parameter_attrs.allows_overwrite?,
            is_hierarchical: parameter_attrs.is_hierarchical?,
            parameter_path: parameter_attrs.parameter_path,
            parameter_name_only: parameter_attrs.parameter_name_only,
            string_list_values: parameter_attrs.string_list_values,
            estimated_monthly_cost: parameter_attrs.estimated_monthly_cost
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)