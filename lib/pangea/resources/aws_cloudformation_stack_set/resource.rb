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
require 'pangea/resources/aws_cloudformation_stack_set/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS CloudFormation Stack Set with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] CloudFormation stack set attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_cloudformation_stack_set(name, attributes = {})
        # Validate attributes using dry-struct
        stack_set_attrs = Types::CloudFormationStackSetAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_cloudformation_stack_set, name) do
          stack_set_name stack_set_attrs.name

          # Template source
          if stack_set_attrs.template_body
            template_body stack_set_attrs.template_body
          elsif stack_set_attrs.template_url
            template_url stack_set_attrs.template_url
          end

          # Description
          if stack_set_attrs.description
            description stack_set_attrs.description
          end

          # Stack set parameters
          if stack_set_attrs.has_parameters?
            parameters do
              stack_set_attrs.parameters.each do |key, value|
                public_send(key, value)
              end
            end
          end

          # Stack set capabilities
          if stack_set_attrs.has_capabilities?
            capabilities stack_set_attrs.capabilities
          end

          # Permission model
          permission_model stack_set_attrs.permission_model

          # Auto deployment configuration (SERVICE_MANAGED only)
          if stack_set_attrs.auto_deployment
            auto_deployment do
              enabled stack_set_attrs.auto_deployment[:enabled]
              retain_stacks_on_account_removal stack_set_attrs.auto_deployment[:retain_stacks_on_account_removal]
            end
          end

          # Administration and execution roles (SELF_MANAGED only)
          if stack_set_attrs.administration_role_arn
            administration_role_arn stack_set_attrs.administration_role_arn
          end

          if stack_set_attrs.execution_role_name
            execution_role_name stack_set_attrs.execution_role_name
          end

          # Operation preferences
          if stack_set_attrs.operation_preferences
            operation_preferences do
              prefs = stack_set_attrs.operation_preferences
              
              region_concurrency_type prefs[:region_concurrency_type] if prefs[:region_concurrency_type]
              max_concurrent_percentage prefs[:max_concurrent_percentage] if prefs[:max_concurrent_percentage]
              max_concurrent_count prefs[:max_concurrent_count] if prefs[:max_concurrent_count]
              failure_tolerance_percentage prefs[:failure_tolerance_percentage] if prefs[:failure_tolerance_percentage]
              failure_tolerance_count prefs[:failure_tolerance_count] if prefs[:failure_tolerance_count]
            end
          end

          # Call as
          call_as stack_set_attrs.call_as

          # Apply tags if present
          if stack_set_attrs.tags.any?
            tags do
              stack_set_attrs.tags.each do |key, value|
                public_send(key, value)
              end
            end
          end
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_cloudformation_stack_set',
          name: name,
          resource_attributes: stack_set_attrs.to_h,
          outputs: {
            id: "${aws_cloudformation_stack_set.#{name}.id}",
            name: "${aws_cloudformation_stack_set.#{name}.name}",
            stack_set_id: "${aws_cloudformation_stack_set.#{name}.stack_set_id}",
            arn: "${aws_cloudformation_stack_set.#{name}.arn}",
            status: "${aws_cloudformation_stack_set.#{name}.status}",
            description: "${aws_cloudformation_stack_set.#{name}.description}",
            parameters: "${aws_cloudformation_stack_set.#{name}.parameters}",
            capabilities: "${aws_cloudformation_stack_set.#{name}.capabilities}",
            permission_model: "${aws_cloudformation_stack_set.#{name}.permission_model}",
            tags_all: "${aws_cloudformation_stack_set.#{name}.tags_all}",
            template_description: "${aws_cloudformation_stack_set.#{name}.template_description}"
          },
          computed_properties: {
            uses_template_body: stack_set_attrs.uses_template_body?,
            uses_template_url: stack_set_attrs.uses_template_url?,
            has_parameters: stack_set_attrs.has_parameters?,
            has_capabilities: stack_set_attrs.has_capabilities?,
            has_description: stack_set_attrs.has_description?,
            is_service_managed: stack_set_attrs.is_service_managed?,
            is_self_managed: stack_set_attrs.is_self_managed?,
            has_auto_deployment: stack_set_attrs.has_auto_deployment?,
            auto_deployment_enabled: stack_set_attrs.auto_deployment_enabled?,
            retains_stacks_on_removal: stack_set_attrs.retains_stacks_on_removal?,
            has_operation_preferences: stack_set_attrs.has_operation_preferences?,
            uses_parallel_deployment: stack_set_attrs.uses_parallel_deployment?,
            uses_sequential_deployment: stack_set_attrs.uses_sequential_deployment?,
            requires_iam_capabilities: stack_set_attrs.requires_iam_capabilities?,
            template_source: stack_set_attrs.template_source
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)