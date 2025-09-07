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
require 'pangea/resources/aws_redshift_parameter_group/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS Redshift Parameter Group with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Redshift Parameter Group attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_redshift_parameter_group(name, attributes = {})
        # Validate attributes using dry-struct
        param_group_attrs = Types::RedshiftParameterGroupAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_redshift_parameter_group, name) do
          # Required attributes
          parameter_group_name = param_group_attrs.name
          family param_group_attrs.family
          
          # Optional description
          description param_group_attrs.generated_description
          
          # Parameters
          param_group_attrs.parameters.each do |param|
            parameter do
              param_name = param[:name]
              value param[:value]
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
          type: 'aws_redshift_parameter_group',
          name: name,
          resource_attributes: param_group_attrs.to_h,
          outputs: {
            id: "${aws_redshift_parameter_group.#{name}.id}",
            name: "${aws_redshift_parameter_group.#{name}.name}",
            arn: "${aws_redshift_parameter_group.#{name}.arn}"
          },
          computed_properties: {
            has_wlm_configuration: param_group_attrs.has_wlm_configuration?,
            query_monitoring_enabled: param_group_attrs.query_monitoring_enabled?,
            result_caching_enabled: param_group_attrs.result_caching_enabled?,
            concurrency_scaling_enabled: param_group_attrs.concurrency_scaling_enabled?,
            concurrency_scaling_limit: param_group_attrs.concurrency_scaling_limit,
            auto_analyze_enabled: param_group_attrs.auto_analyze_enabled?,
            performance_impact_score: param_group_attrs.performance_impact_score
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)