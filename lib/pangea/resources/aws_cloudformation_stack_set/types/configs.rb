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

module Pangea
  module Resources
    module AWS
      module Types
        # Common CloudFormation Stack Set configurations
        module CloudFormationStackSetConfigs
          module_function

          # Service-managed stack set (Organizations)
          def service_managed_stack_set(name, template_body)
            {
              name: name,
              template_body: template_body,
              permission_model: 'SERVICE_MANAGED',
              auto_deployment: {
                enabled: true,
                retain_stacks_on_account_removal: false
              },
              call_as: 'DELEGATED_ADMIN'
            }
          end

          # Self-managed stack set
          def self_managed_stack_set(name, template_body, admin_role_arn, exec_role_name)
            {
              name: name,
              template_body: template_body,
              permission_model: 'SELF_MANAGED',
              administration_role_arn: admin_role_arn,
              execution_role_name: exec_role_name,
              call_as: 'SELF'
            }
          end

          # Stack set with parallel deployment
          def parallel_deployment_stack_set(name, template_url)
            {
              name: name,
              template_url: template_url,
              permission_model: 'SERVICE_MANAGED',
              auto_deployment: {
                enabled: true,
                retain_stacks_on_account_removal: false
              },
              operation_preferences: {
                region_concurrency_type: 'PARALLEL',
                max_concurrent_percentage: 100,
                failure_tolerance_percentage: 10
              }
            }
          end

          # Stack set with conservative deployment
          def conservative_deployment_stack_set(name, template_body)
            {
              name: name,
              template_body: template_body,
              permission_model: 'SERVICE_MANAGED',
              auto_deployment: {
                enabled: false,
                retain_stacks_on_account_removal: true
              },
              operation_preferences: {
                region_concurrency_type: 'SEQUENTIAL',
                max_concurrent_count: 1,
                failure_tolerance_count: 0
              }
            }
          end

          # IAM-enabled stack set
          def iam_stack_set(name, template_body, admin_role_arn, exec_role_name)
            {
              name: name,
              template_body: template_body,
              permission_model: 'SELF_MANAGED',
              administration_role_arn: admin_role_arn,
              execution_role_name: exec_role_name,
              capabilities: %w[CAPABILITY_IAM CAPABILITY_NAMED_IAM]
            }
          end

          # Stack set with custom operation preferences
          def custom_operation_stack_set(name, template_url, max_concurrent: 50, failure_tolerance: 5)
            {
              name: name,
              template_url: template_url,
              permission_model: 'SERVICE_MANAGED',
              auto_deployment: {
                enabled: true,
                retain_stacks_on_account_removal: false
              },
              operation_preferences: {
                region_concurrency_type: 'PARALLEL',
                max_concurrent_percentage: max_concurrent,
                failure_tolerance_percentage: failure_tolerance
              }
            }
          end
        end
      end
    end
  end
end
