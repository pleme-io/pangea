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
        # Helper methods for SageMaker Notebook Instance attributes
        module Helpers
          def is_gpu_instance?
            instance_type.start_with?('ml.p')
          end

          def is_compute_optimized?
            instance_type.start_with?('ml.c')
          end

          def is_memory_optimized?
            instance_type.start_with?('ml.r')
          end

          def is_burstable?
            instance_type.start_with?('ml.t')
          end

          def has_vpc_configuration?
            !subnet_id.nil?
          end

          def has_internet_access?
            direct_internet_access == 'Enabled'
          end

          def has_accelerators?
            accelerator_types&.any?
          end

          def uses_custom_kms_key?
            !kms_key_id.nil?
          end

          def has_lifecycle_config?
            !lifecycle_config_name.nil?
          end

          def has_code_repositories?
            !default_code_repository.nil? || additional_code_repositories&.any?
          end

          def total_code_repositories
            count = 0
            count += 1 if default_code_repository
            count += additional_code_repositories.size if additional_code_repositories
            count
          end
        end
      end
    end
  end
end
