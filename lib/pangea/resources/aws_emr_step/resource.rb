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
require 'pangea/resources/aws_emr_step/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS EMR Step with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] EMR Step attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_emr_step(name, attributes = {})
        # Validate attributes using dry-struct
        step_attrs = Types::EmrStepAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_emr_step, name) do
          # Required attributes
          step_name = step_attrs.name
          cluster_id step_attrs.cluster_id
          action_on_failure step_attrs.action_on_failure
          
          # Hadoop JAR step configuration
          hadoop_jar_step do
            hjs = step_attrs.hadoop_jar_step
            jar hjs[:jar]
            main_class hjs[:main_class] if hjs[:main_class]
            
            # Arguments
            if hjs[:args]&.any?
              hjs[:args].each do |arg|
                args arg
              end
            end
            
            # Properties
            if hjs[:properties]&.any?
              properties do
                hjs[:properties].each do |key, value|
                  public_send(key.gsub(/[^a-zA-Z0-9_]/, '_').downcase, value)
                end
              end
            end
          end
          
          # Optional attributes
          description step_attrs.description if step_attrs.description
          step_concurrency_level step_attrs.step_concurrency_level if step_attrs.step_concurrency_level
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_emr_step',
          name: name,
          resource_attributes: step_attrs.to_h,
          outputs: {
            id: "${aws_emr_step.#{name}.id}",
            state: "${aws_emr_step.#{name}.state}"
          },
          computed_properties: {
            uses_command_runner: step_attrs.uses_command_runner?,
            uses_s3_jar: step_attrs.uses_s3_jar?,
            has_custom_main_class: step_attrs.has_custom_main_class?,
            step_type: step_attrs.step_type,
            argument_count: step_attrs.argument_count,
            property_count: step_attrs.property_count,
            is_likely_long_running: step_attrs.is_likely_long_running?,
            complexity_score: step_attrs.complexity_score,
            configuration_warnings: step_attrs.configuration_warnings
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)