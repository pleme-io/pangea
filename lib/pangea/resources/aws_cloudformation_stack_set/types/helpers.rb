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
        # Helper methods for CloudFormation Stack Set attributes
        module CloudFormationStackSetHelpers
          def uses_template_body?
            !template_body.nil?
          end

          def uses_template_url?
            !template_url.nil?
          end

          def has_parameters?
            parameters.any?
          end

          def has_capabilities?
            capabilities.any?
          end

          def has_description?
            !description.nil?
          end

          def is_service_managed?
            permission_model == 'SERVICE_MANAGED'
          end

          def is_self_managed?
            permission_model == 'SELF_MANAGED'
          end

          def has_auto_deployment?
            !auto_deployment.nil?
          end

          def auto_deployment_enabled?
            auto_deployment&.dig(:enabled) == true
          end

          def retains_stacks_on_removal?
            auto_deployment&.dig(:retain_stacks_on_account_removal) == true
          end

          def has_operation_preferences?
            !operation_preferences.nil?
          end

          def uses_parallel_deployment?
            operation_preferences&.dig(:region_concurrency_type) == 'PARALLEL'
          end

          def uses_sequential_deployment?
            operation_preferences&.dig(:region_concurrency_type) == 'SEQUENTIAL'
          end

          def requires_iam_capabilities?
            capabilities.any? { |cap| cap.include?('IAM') }
          end

          def template_source
            return :body if template_body
            return :url if template_url

            :none
          end
        end
      end
    end
  end
end
