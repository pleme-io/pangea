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
require 'pangea/resources/aws/cloudformation/types'

module Pangea
  module Resources
    module AWS
      module CloudFormation
        # AWS CloudFormation Stack Instances resource
        # Manages multiple stack instances across accounts and regions in a single operation.
        # This resource creates or updates multiple stack instances from a stack set
        # simultaneously with shared operation preferences.
        #
        # @see https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/stackinstances-create.html
        module StackInstances
          # Creates AWS CloudFormation Stack Instances
          #
          # @param name [Symbol] The unique name for this resource instance
          # @param attributes [Hash] The configuration options for the stack instances
          # @option attributes [String] :stack_set_name Name of the stack set (required)
          # @option attributes [Hash] :deployment_targets Deployment targets configuration
          # @option attributes [Array<String>] :regions List of AWS regions to deploy to
          # @option attributes [Hash] :parameter_overrides Parameter values to override
          # @option attributes [Hash] :operation_preferences Operation preferences for deployment
          # @option attributes [String] :call_as Call as DELEGATED_ADMIN or SELF
          # @option attributes [String] :operation_id Unique operation identifier
          #
          # @example Multi-region organization deployment
          #   multi_region_instances = aws_cloudformation_stack_instances(:global_security, {
          #     stack_set_name: security_baseline.name,
          #     deployment_targets: {
          #       organizational_unit_ids: ["ou-root-123456789"],
          #       account_filter_type: "NONE"
          #     },
          #     regions: ["us-east-1", "us-west-2", "eu-west-1", "ap-southeast-1"],
          #     parameter_overrides: {
          #       "GlobalPrefix": "GLOBAL",
          #       "ComplianceLevel": "Enterprise"
          #     },
          #     operation_preferences: {
          #       failure_tolerance_percentage: 10,
          #       max_concurrent_percentage: 50,
          #       concurrency_mode: "SOFT_FAILURE_TOLERANCE",
          #       region_concurrency_type: "PARALLEL"
          #     },
          #     call_as: "DELEGATED_ADMIN"
          #   })
          #
          # @example Multi-account specific regions deployment
          #   account_instances = aws_cloudformation_stack_instances(:prod_accounts, {
          #     stack_set_name: application_stack.name,
          #     deployment_targets: {
          #       accounts: ["123456789012", "234567890123", "345678901234"]
          #     },
          #     regions: ["us-east-1", "us-west-2"],
          #     parameter_overrides: {
          #       "Environment": "Production",
          #       "InstanceType": "m5.large"
          #     },
          #     operation_preferences: {
          #       failure_tolerance_count: 1,
          #       max_concurrent_count: 3,
          #       concurrency_mode: "STRICT_FAILURE_TOLERANCE"
          #     }
          #   })
          #
          # @return [ResourceReference] The stack instances resource reference
          def aws_cloudformation_stack_instances(name, attributes = {})
            # Validate attributes using dry-struct
            instances_attrs = Types::CloudFormationStackInstancesAttributes.new(attributes)
            
            # Generate terraform resource block
            resource(:aws_cloudformation_stack_instances, name) do
              stack_set_name instances_attrs.stack_set_name
              
              # Deployment targets
              if instances_attrs.deployment_targets
                deployment_targets do
                  if instances_attrs.deployment_targets[:organizational_unit_ids]
                    organizational_unit_ids instances_attrs.deployment_targets[:organizational_unit_ids]
                  end
                  if instances_attrs.deployment_targets[:accounts]
                    accounts instances_attrs.deployment_targets[:accounts]
                  end
                  if instances_attrs.deployment_targets[:account_filter_type]
                    account_filter_type instances_attrs.deployment_targets[:account_filter_type]
                  end
                  if instances_attrs.deployment_targets[:accounts_url]
                    accounts_url instances_attrs.deployment_targets[:accounts_url]
                  end
                  if instances_attrs.deployment_targets[:organizational_unit_ids_url]
                    organizational_unit_ids_url instances_attrs.deployment_targets[:organizational_unit_ids_url]
                  end
                end
              end
              
              # Regions
              if instances_attrs.regions.any?
                regions instances_attrs.regions
              end
              
              # Optional configurations
              call_as instances_attrs.call_as if instances_attrs.call_as
              operation_id instances_attrs.operation_id if instances_attrs.operation_id
              
              # Parameter overrides
              if instances_attrs.parameter_overrides.any?
                parameter_overrides instances_attrs.parameter_overrides
              end
              
              # Operation preferences
              if instances_attrs.operation_preferences
                operation_preferences do
                  failure_tolerance_count instances_attrs.operation_preferences[:failure_tolerance_count] if instances_attrs.operation_preferences[:failure_tolerance_count]
                  failure_tolerance_percentage instances_attrs.operation_preferences[:failure_tolerance_percentage] if instances_attrs.operation_preferences[:failure_tolerance_percentage]
                  max_concurrent_count instances_attrs.operation_preferences[:max_concurrent_count] if instances_attrs.operation_preferences[:max_concurrent_count]
                  max_concurrent_percentage instances_attrs.operation_preferences[:max_concurrent_percentage] if instances_attrs.operation_preferences[:max_concurrent_percentage]
                  concurrency_mode instances_attrs.operation_preferences[:concurrency_mode] if instances_attrs.operation_preferences[:concurrency_mode]
                  region_concurrency_type instances_attrs.operation_preferences[:region_concurrency_type] if instances_attrs.operation_preferences[:region_concurrency_type]
                end
              end
            end
            
            # Return resource reference
            ResourceReference.new(
              type: 'aws_cloudformation_stack_instances',
              name: name,
              resource_attributes: instances_attrs.to_h,
              outputs: {
                id: "${aws_cloudformation_stack_instances.#{name}.id}",
                stack_instance_summaries: "${aws_cloudformation_stack_instances.#{name}.stack_instance_summaries}"
              },
              computed_properties: {
                deployment_scope: instances_attrs.deployment_scope,
                region_count: instances_attrs.regions.length,
                is_multi_region: instances_attrs.multi_region?,
                has_parameter_overrides: instances_attrs.parameter_overrides.any?
              }
            )
          end
        end
      end
    end
  end
end