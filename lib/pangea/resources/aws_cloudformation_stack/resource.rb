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
require 'pangea/resources/aws_cloudformation_stack/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS CloudFormation Stack with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] CloudFormation stack attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_cloudformation_stack(name, attributes = {})
        # Validate attributes using dry-struct
        stack_attrs = Types::CloudFormationStackAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_cloudformation_stack, name) do
          stack_name stack_attrs.name

          # Template source
          if stack_attrs.template_body
            template_body stack_attrs.template_body
          elsif stack_attrs.template_url
            template_url stack_attrs.template_url
          end

          # Stack parameters
          if stack_attrs.has_parameters?
            parameters do
              stack_attrs.parameters.each do |key, value|
                public_send(key, value)
              end
            end
          end

          # Stack capabilities
          if stack_attrs.has_capabilities?
            capabilities stack_attrs.capabilities
          end

          # Notification ARNs
          if stack_attrs.has_notifications?
            notification_arns stack_attrs.notification_arns
          end

          # Stack policy
          if stack_attrs.policy_body
            policy_body stack_attrs.policy_body
          elsif stack_attrs.policy_url
            policy_url stack_attrs.policy_url
          end

          # Timeout configuration
          if stack_attrs.timeout_in_minutes
            timeout_in_minutes stack_attrs.timeout_in_minutes
          end

          # Rollback configuration
          disable_rollback stack_attrs.disable_rollback

          # Termination protection
          enable_termination_protection stack_attrs.enable_termination_protection

          # IAM role
          if stack_attrs.iam_role_arn
            iam_role_arn stack_attrs.iam_role_arn
          end

          # Failure behavior
          on_failure stack_attrs.on_failure

          # Apply tags if present
          if stack_attrs.tags.any?
            tags do
              stack_attrs.tags.each do |key, value|
                public_send(key, value)
              end
            end
          end
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_cloudformation_stack',
          name: name,
          resource_attributes: stack_attrs.to_h,
          outputs: {
            id: "${aws_cloudformation_stack.#{name}.id}",
            name: "${aws_cloudformation_stack.#{name}.name}",
            stack_id: "${aws_cloudformation_stack.#{name}.stack_id}",
            arn: "${aws_cloudformation_stack.#{name}.arn}",
            stack_status: "${aws_cloudformation_stack.#{name}.stack_status}",
            stack_status_reason: "${aws_cloudformation_stack.#{name}.stack_status_reason}",
            creation_time: "${aws_cloudformation_stack.#{name}.creation_time}",
            last_updated_time: "${aws_cloudformation_stack.#{name}.last_updated_time}",
            outputs: "${aws_cloudformation_stack.#{name}.outputs}",
            parameters: "${aws_cloudformation_stack.#{name}.parameters}",
            tags_all: "${aws_cloudformation_stack.#{name}.tags_all}"
          },
          computed_properties: {
            uses_template_body: stack_attrs.uses_template_body?,
            uses_template_url: stack_attrs.uses_template_url?,
            has_parameters: stack_attrs.has_parameters?,
            has_capabilities: stack_attrs.has_capabilities?,
            has_notifications: stack_attrs.has_notifications?,
            has_policy: stack_attrs.has_policy?,
            has_timeout: stack_attrs.has_timeout?,
            has_iam_role: stack_attrs.has_iam_role?,
            rollback_disabled: stack_attrs.rollback_disabled?,
            termination_protected: stack_attrs.termination_protected?,
            requires_iam_capabilities: stack_attrs.requires_iam_capabilities?,
            template_source: stack_attrs.template_source
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)