# frozen_string_literal: true

require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/aws/cloudformation/types'

module Pangea
  module Resources
    module AWS
      module CloudFormation
        # AWS CloudFormation Stack Set resource
        # Manages CloudFormation stacks across multiple AWS accounts and regions.
        # Stack sets enable centralized deployment and management of stacks across
        # AWS Organizations or individual accounts with consistent templates.
        #
        # @see https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/what-is-cfnstacksets.html
        module StackSet
          # Creates an AWS CloudFormation Stack Set
          #
          # @param name [Symbol] The unique name for this resource instance
          # @param attributes [Hash] The configuration options for the stack set
          # @option attributes [String] :name The name of the stack set (required)
          # @option attributes [String] :template_body The CloudFormation template body
          # @option attributes [String] :template_url The S3 URL of the CloudFormation template
          # @option attributes [Hash] :parameters Template parameters as key-value pairs
          # @option attributes [Array<String>] :capabilities Required IAM capabilities
          # @option attributes [String] :description Description of the stack set
          # @option attributes [String] :execution_role_name IAM role for stack set execution
          # @option attributes [String] :administration_role_arn IAM role for stack set administration
          # @option attributes [Hash] :tags Tags to apply to the stack set
          # @option attributes [String] :permission_model Permission model (SERVICE_MANAGED or SELF_MANAGED)
          # @option attributes [Hash] :auto_deployment Auto deployment configuration for Organizations
          # @option attributes [String] :call_as Call as DELEGATED_ADMIN or SELF
          # @option attributes [Hash] :managed_execution Managed execution configuration
          # @option attributes [Hash] :operation_preferences Default operation preferences
          #
          # @example Multi-account security baseline stack set
          #   security_baseline = aws_cloudformation_stack_set(:security_baseline, {
          #     name: "SecurityBaseline",
          #     template_url: "https://s3.amazonaws.com/templates/security-baseline.yaml",
          #     description: "Baseline security configurations for all accounts",
          #     parameters: {
          #       "CloudTrailBucketName": "organization-cloudtrail-logs",
          #       "ConfigBucketName": "organization-config-logs"
          #     },
          #     capabilities: ["CAPABILITY_IAM", "CAPABILITY_NAMED_IAM"],
          #     permission_model: "SERVICE_MANAGED",
          #     execution_role_name: "AWSCloudFormationStackSetExecutionRole",
          #     administration_role_arn: ref(:aws_iam_role, :stackset_admin, :arn),
          #     auto_deployment: {
          #       enabled: true,
          #       retain_stacks_on_account_removal: false
          #     },
          #     managed_execution: {
          #       active: true
          #     },
          #     operation_preferences: {
          #       failure_tolerance_count: 1,
          #       max_concurrent_count: 10,
          #       concurrency_mode: "SOFT_FAILURE_TOLERANCE"
          #     },
          #     tags: {
          #       "Environment" => "Production",
          #       "Purpose" => "Security",
          #       "ManagedBy" => "CloudFormation"
          #     }
          #   })
          #
          # @example Self-managed network stack set
          #   network_stack_set = aws_cloudformation_stack_set(:network_stack, {
          #     name: "NetworkInfrastructure",
          #     template_body: File.read("templates/network.yaml"),
          #     description: "VPC and networking infrastructure",
          #     parameters: {
          #       "VpcCidr": "10.0.0.0/16",
          #       "Environment": "Production"
          #     },
          #     capabilities: ["CAPABILITY_IAM"],
          #     permission_model: "SELF_MANAGED",
          #     execution_role_name: "CloudFormationExecutionRole",
          #     administration_role_arn: ref(:aws_iam_role, :cf_admin, :arn),
          #     operation_preferences: {
          #       failure_tolerance_percentage: 10,
          #       max_concurrent_percentage: 50,
          #       concurrency_mode: "STRICT_FAILURE_TOLERANCE"
          #     },
          #     tags: {
          #       "Component" => "Networking"
          #     }
          #   })
          #
          # @return [ResourceReference] The stack set resource reference
          def aws_cloudformation_stack_set(name, attributes = {})
            # Validate attributes using dry-struct
            stack_set_attrs = Types::CloudFormationStackSetAttributes.new(attributes)
            
            # Generate terraform resource block
            resource(:aws_cloudformation_stack_set, name) do
              name stack_set_attrs.name
              
              # Template source (mutually exclusive)
              if stack_set_attrs.template_body
                template_body stack_set_attrs.template_body
              elsif stack_set_attrs.template_url
                template_url stack_set_attrs.template_url
              end
              
              # Optional configurations
              description stack_set_attrs.description if stack_set_attrs.description
              execution_role_name stack_set_attrs.execution_role_name if stack_set_attrs.execution_role_name
              administration_role_arn stack_set_attrs.administration_role_arn if stack_set_attrs.administration_role_arn
              permission_model stack_set_attrs.permission_model if stack_set_attrs.permission_model
              call_as stack_set_attrs.call_as if stack_set_attrs.call_as
              
              # Template parameters
              if stack_set_attrs.parameters.any?
                parameters stack_set_attrs.parameters
              end
              
              # IAM capabilities
              if stack_set_attrs.capabilities.any?
                capabilities stack_set_attrs.capabilities
              end
              
              # Auto deployment for Organizations
              if stack_set_attrs.auto_deployment
                auto_deployment do
                  enabled stack_set_attrs.auto_deployment[:enabled]
                  retain_stacks_on_account_removal stack_set_attrs.auto_deployment[:retain_stacks_on_account_removal] if stack_set_attrs.auto_deployment.key?(:retain_stacks_on_account_removal)
                end
              end
              
              # Managed execution
              if stack_set_attrs.managed_execution
                managed_execution do
                  active stack_set_attrs.managed_execution[:active]
                end
              end
              
              # Default operation preferences
              if stack_set_attrs.operation_preferences
                operation_preferences do
                  failure_tolerance_count stack_set_attrs.operation_preferences[:failure_tolerance_count] if stack_set_attrs.operation_preferences[:failure_tolerance_count]
                  failure_tolerance_percentage stack_set_attrs.operation_preferences[:failure_tolerance_percentage] if stack_set_attrs.operation_preferences[:failure_tolerance_percentage]
                  max_concurrent_count stack_set_attrs.operation_preferences[:max_concurrent_count] if stack_set_attrs.operation_preferences[:max_concurrent_count]
                  max_concurrent_percentage stack_set_attrs.operation_preferences[:max_concurrent_percentage] if stack_set_attrs.operation_preferences[:max_concurrent_percentage]
                  concurrency_mode stack_set_attrs.operation_preferences[:concurrency_mode] if stack_set_attrs.operation_preferences[:concurrency_mode]
                end
              end
              
              # Tags
              if stack_set_attrs.tags.any?
                tags stack_set_attrs.tags
              end
            end
            
            # Return resource reference
            ResourceReference.new(
              type: 'aws_cloudformation_stack_set',
              name: name,
              resource_attributes: stack_set_attrs.to_h,
              outputs: {
                id: "${aws_cloudformation_stack_set.#{name}.id}",
                arn: "${aws_cloudformation_stack_set.#{name}.arn}",
                stack_set_id: "${aws_cloudformation_stack_set.#{name}.stack_set_id}",
                template_description: "${aws_cloudformation_stack_set.#{name}.template_description}"
              },
              computed_properties: {
                is_organization_managed: stack_set_attrs.organization_managed?,
                has_auto_deployment: stack_set_attrs.has_auto_deployment?,
                has_managed_execution: stack_set_attrs.has_managed_execution?,
                template_source: stack_set_attrs.template_source,
                requires_capabilities: stack_set_attrs.requires_capabilities?
              }
            )
          end
        end
      end
    end
  end
end