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
        # Validation methods for Athena Workgroup attributes
        module AthenaWorkgroupValidation
          def validate_workgroup_name(name)
            unless name =~ /\A[a-zA-Z0-9_-]+\z/
              raise Dry::Struct::Error, 'Workgroup name must contain only alphanumeric characters, hyphens, and underscores'
            end

            return unless name.length > 128

            raise Dry::Struct::Error, 'Workgroup name must be 128 characters or less'
          end

          def validate_kms_encryption(config)
            return unless config && config[:result_configuration]

            result_config = config[:result_configuration]
            return unless result_config[:encryption_configuration]

            encryption = result_config[:encryption_configuration]
            return unless %w[SSE_KMS CSE_KMS].include?(encryption[:encryption_option])
            return unless encryption[:kms_key_id].nil?

            raise Dry::Struct::Error, 'KMS key ID required for KMS encryption'
          end

          def validate_bytes_cutoff(config)
            return unless config && config[:bytes_scanned_cutoff_per_query]
            return unless config[:bytes_scanned_cutoff_per_query] < 10_000_000

            raise Dry::Struct::Error, 'Bytes scanned cutoff must be at least 10MB (10000000 bytes)'
          end
        end
      end
    end
  end
end
