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
        module S3ObjectValidation
          def validate_content_source(attrs)
            if attrs.source && attrs.content
              raise Dry::Struct::Error, 'source and content are mutually exclusive - specify only one'
            end

            return if attrs.source || attrs.content

            raise Dry::Struct::Error, 'either source or content must be specified'
          end

          def validate_source_file_exists(attrs)
            return unless attrs.source && !File.exist?(attrs.source)

            raise Dry::Struct::Error, "source file '#{attrs.source}' does not exist"
          end

          def validate_kms_encryption(attrs)
            return unless attrs.server_side_encryption == 'aws:kms' && attrs.kms_key_id.nil?

            raise Dry::Struct::Error, 'kms_key_id is required when using aws:kms encryption'
          end

          def validate_object_lock(attrs)
            if attrs.object_lock_mode && attrs.object_lock_retain_until_date.nil?
              raise Dry::Struct::Error, 'object_lock_retain_until_date is required when object_lock_mode is specified'
            end

            return unless attrs.object_lock_retain_until_date && attrs.object_lock_mode.nil?

            raise Dry::Struct::Error, 'object_lock_mode is required when object_lock_retain_until_date is specified'
          end
        end
      end
    end
  end
end
