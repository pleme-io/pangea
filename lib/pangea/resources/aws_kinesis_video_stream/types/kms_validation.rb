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
        # KMS key ID validation helpers for Kinesis Video Stream
        module KmsValidation
          # Validate KMS key ID format
          # KMS key ID can be:
          # - Key ID: 12345678-1234-1234-1234-123456789012
          # - Key ARN: arn:aws:kms:region:account:key/key-id
          # - Alias name: alias/my-key
          # - Alias ARN: arn:aws:kms:region:account:alias/my-key
          def self.valid_kms_key_id?(key_id)
            # UUID format
            return true if key_id.match?(/\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/i)

            # Key ARN
            return true if key_id.match?(/\Aarn:aws:kms:[a-z0-9-]+:\d{12}:key\/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/i)

            # Alias name
            return true if key_id.match?(/\Aalias\/[a-zA-Z0-9:/_-]+\z/)

            # Alias ARN
            return true if key_id.match?(/\Aarn:aws:kms:[a-z0-9-]+:\d{12}:alias\/[a-zA-Z0-9:/_-]+\z/)

            false
          end

          # Instance method for checking encryption status
          def is_encrypted?
            !kms_key_id.nil? && !kms_key_id.empty?
          end
        end
      end
    end
  end
end
