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
      module SageMakerNotebookInstance
        # Security and compliance methods for SageMaker Notebook Instance
        module Security
          LATEST_PLATFORM = 'notebook-al2-v2'
          MAX_SECURITY_SCORE = 100

          def security_score
            score = 0
            score += 20 if has_vpc_configuration? && !has_internet_access?
            score += 15 if uses_custom_kms_key?
            score += 10 if root_access == 'Disabled'
            score += 10 if has_lifecycle_config?
            score += 10 if platform_identifier == LATEST_PLATFORM
            score += 15 if imds_v2_required?
            score += 5 if security_group_ids&.any?

            [score, MAX_SECURITY_SCORE].min
          end

          def compliance_status
            issues = collect_compliance_issues

            {
              status: issues.empty? ? 'compliant' : 'needs_attention',
              issues: issues
            }
          end

          def instance_capabilities
            {
              instance_type: instance_type,
              gpu_enabled: is_gpu_instance?,
              compute_optimized: is_compute_optimized?,
              memory_optimized: is_memory_optimized?,
              burstable: is_burstable?,
              accelerators: accelerator_types || [],
              storage_gb: volume_size_in_gb,
              estimated_monthly_cost: estimated_monthly_cost
            }
          end

          private

          def imds_v2_required?
            instance_metadata_service_configuration&.dig(:minimum_instance_metadata_service_version) == '2'
          end

          def collect_compliance_issues
            issues = []
            issues << 'Notebook has direct internet access' if has_internet_access? && has_vpc_configuration?
            issues << 'No custom KMS key for encryption' unless uses_custom_kms_key?
            issues << 'Root access is enabled' if root_access == 'Enabled'
            issues << 'No lifecycle configuration specified' unless has_lifecycle_config?
            issues << 'Using older platform identifier' if platform_identifier && platform_identifier != LATEST_PLATFORM
            issues << 'Instance metadata service v1 allowed' unless imds_v2_required?
            issues
          end
        end
      end
    end
  end
end
