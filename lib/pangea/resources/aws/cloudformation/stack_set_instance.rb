# frozen_string_literal: true

require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/aws/cloudformation/types'

module Pangea
  module Resources
    module AWS
      module CloudFormation
        # AWS CloudFormation Stack Set Instance resource
        # Manages individual stack instances within a CloudFormation stack set.
        # Stack instances represent stacks created from a stack set template
        # in specific AWS accounts and regions.
        #
        # @see https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/stackinstances-create.html
        module StackSetInstance
          # Creates an AWS CloudFormation Stack Set Instance
          #
          # @param name [Symbol] The unique name for this resource instance
          # @param attributes [Hash] The configuration options for the stack instance
          # @option attributes [String] :stack_set_name Name of the stack set (required)
          # @option attributes [String] :account_id AWS account ID (for SELF_MANAGED)
          # @option attributes [String] :region AWS region (for SELF_MANAGED)
          # @option attributes [Hash] :deployment_targets Deployment targets (for SERVICE_MANAGED)
          # @option attributes [Hash] :parameter_overrides Parameter values to override
          # @option attributes [Boolean] :retain_stack Whether to retain the stack on deletion
          # @option attributes [Hash] :operation_preferences Operation preferences for deployment
          # @option attributes [String] :call_as Call as DELEGATED_ADMIN or SELF
          #
          # @example Self-managed stack instance
          #   prod_instance = aws_cloudformation_stack_set_instance(:prod_security, {
          #     stack_set_name: security_baseline.name,
          #     account_id: "123456789012",
          #     region: "us-east-1",
          #     parameter_overrides: {
          #       "Environment": "Production",
          #       "AlertingEmail": "security-alerts@company.com"
          #     },
          #     retain_stack: true,
          #     operation_preferences: {
          #       failure_tolerance_count: 0,
          #       max_concurrent_count: 1,
          #       concurrency_mode: "STRICT_FAILURE_TOLERANCE"
          #     }
          #   })
          #
          # @example Organization-managed stack instance
          #   org_instance = aws_cloudformation_stack_set_instance(:org_security, {
          #     stack_set_name: security_baseline.name,
          #     deployment_targets: {
          #       organizational_unit_ids: ["ou-root-123456789", "ou-prod-987654321"],
          #       account_filter_type: "DIFFERENCE",
          #       accounts: ["111111111111"] # Exclude this account
          #     },
          #     parameter_overrides: {
          #       "ComplianceLevel": "High"
          #     },
          #     call_as: "DELEGATED_ADMIN",
          #     operation_preferences: {
          #       failure_tolerance_percentage: 5,
          #       max_concurrent_percentage: 25,
          #       concurrency_mode: "SOFT_FAILURE_TOLERANCE"
          #     }
          #   })
          #
          # @return [ResourceReference] The stack set instance resource reference
          def aws_cloudformation_stack_set_instance(name, attributes = {})
            # Validate attributes using dry-struct
            instance_attrs = Types::CloudFormationStackSetInstanceAttributes.new(attributes)
            
            # Generate terraform resource block
            resource(:aws_cloudformation_stack_set_instance, name) do
              stack_set_name instance_attrs.stack_set_name
              
              # Target specification
              if instance_attrs.account_deployment?
                account_id instance_attrs.account_id
                region instance_attrs.region
              elsif instance_attrs.deployment_targets
                deployment_targets do
                  if instance_attrs.deployment_targets[:organizational_unit_ids]
                    organizational_unit_ids instance_attrs.deployment_targets[:organizational_unit_ids]
                  end
                  if instance_attrs.deployment_targets[:account_filter_type]
                    account_filter_type instance_attrs.deployment_targets[:account_filter_type]
                  end
                  if instance_attrs.deployment_targets[:accounts]
                    accounts instance_attrs.deployment_targets[:accounts]
                  end
                end
              end
              
              # Optional configurations
              retain_stack instance_attrs.retain_stack
              call_as instance_attrs.call_as if instance_attrs.call_as
              
              # Parameter overrides
              if instance_attrs.parameter_overrides.any?
                parameter_overrides instance_attrs.parameter_overrides
              end
              
              # Operation preferences
              if instance_attrs.operation_preferences
                operation_preferences do
                  failure_tolerance_count instance_attrs.operation_preferences[:failure_tolerance_count] if instance_attrs.operation_preferences[:failure_tolerance_count]
                  failure_tolerance_percentage instance_attrs.operation_preferences[:failure_tolerance_percentage] if instance_attrs.operation_preferences[:failure_tolerance_percentage]
                  max_concurrent_count instance_attrs.operation_preferences[:max_concurrent_count] if instance_attrs.operation_preferences[:max_concurrent_count]
                  max_concurrent_percentage instance_attrs.operation_preferences[:max_concurrent_percentage] if instance_attrs.operation_preferences[:max_concurrent_percentage]
                  concurrency_mode instance_attrs.operation_preferences[:concurrency_mode] if instance_attrs.operation_preferences[:concurrency_mode]
                end
              end
            end
            
            # Return resource reference
            ResourceReference.new(
              type: 'aws_cloudformation_stack_set_instance',
              name: name,
              resource_attributes: instance_attrs.to_h,
              outputs: {
                id: "${aws_cloudformation_stack_set_instance.#{name}.id}",
                stack_id: "${aws_cloudformation_stack_set_instance.#{name}.stack_id}",
                stack_instance_summaries: "${aws_cloudformation_stack_set_instance.#{name}.stack_instance_summaries}"
              },
              computed_properties: {
                deployment_type: instance_attrs.organization_deployment? ? 'organization' : 'account',
                is_organization_deployment: instance_attrs.organization_deployment?,
                is_account_deployment: instance_attrs.account_deployment?,
                has_parameter_overrides: instance_attrs.parameter_overrides.any?
              }
            )
          end
        end
      end
    end
  end
end