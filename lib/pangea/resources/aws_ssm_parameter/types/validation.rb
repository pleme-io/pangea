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
        # Validation logic for SSM Parameter attributes
        module SsmParameterValidation
          KMS_KEY_PATTERN = /\A(alias\/[a-zA-Z0-9\/_-]+|arn:aws:kms:[a-z0-9-]+:\d{12}:key\/[a-f0-9-]{36}|[a-f0-9-]{36})\z/
          PARAMETER_NAME_PATTERN = /\A[a-zA-Z0-9\/_.-]+\z/
          MAX_NAME_LENGTH = 2048
          MAX_DESCRIPTION_LENGTH = 1024
          STANDARD_TIER_MAX_VALUE_SIZE = 4096
          ADVANCED_TIER_MAX_VALUE_SIZE = 8192

          def self.validate(attrs)
            validate_secure_string_requirements(attrs)
            validate_parameter_name(attrs)
            validate_parameter_value_size(attrs)
            validate_description_length(attrs)
            validate_allowed_pattern(attrs)
          end

          def self.validate_secure_string_requirements(attrs)
            if attrs.type == "SecureString"
              if attrs.key_id && !attrs.key_id.match?(KMS_KEY_PATTERN)
                raise Dry::Struct::Error, "key_id must be a valid KMS key ID, ARN, or alias"
              end
            elsif attrs.key_id
              raise Dry::Struct::Error, "key_id can only be specified for SecureString parameters"
            end
          end

          def self.validate_parameter_name(attrs)
            unless attrs.name.match?(PARAMETER_NAME_PATTERN)
              raise Dry::Struct::Error, "Parameter name can only contain letters, numbers, and the following symbols: /_.-"
            end

            if attrs.name.length > MAX_NAME_LENGTH
              raise Dry::Struct::Error, "Parameter name cannot exceed #{MAX_NAME_LENGTH} characters"
            end
          end

          def self.validate_parameter_value_size(attrs)
            max_value_size = attrs.tier == "Advanced" ? ADVANCED_TIER_MAX_VALUE_SIZE : STANDARD_TIER_MAX_VALUE_SIZE
            if attrs.value.bytesize > max_value_size
              raise Dry::Struct::Error, "Parameter value cannot exceed #{max_value_size} bytes for #{attrs.tier} tier"
            end
          end

          def self.validate_description_length(attrs)
            if attrs.description && attrs.description.length > MAX_DESCRIPTION_LENGTH
              raise Dry::Struct::Error, "Parameter description cannot exceed #{MAX_DESCRIPTION_LENGTH} characters"
            end
          end

          def self.validate_allowed_pattern(attrs)
            return unless attrs.allowed_pattern

            begin
              Regexp.new(attrs.allowed_pattern)
            rescue RegexpError => e
              raise Dry::Struct::Error, "Invalid allowed_pattern regular expression: #{e.message}"
            end
          end
        end
      end
    end
  end
end
