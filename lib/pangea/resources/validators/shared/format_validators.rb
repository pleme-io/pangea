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

require 'base64'
require 'json'

module Pangea
  module Resources
    module Validators
      module SharedValidators
        # Format validators (hex, json, base64, terraform interpolation)
        module FormatValidators
          # Validate Terraform interpolation or literal value
          #
          # @param value [String] The value to check
          # @return [Boolean] True if it's a Terraform interpolation
          def terraform_interpolation?(value)
            value.is_a?(String) && value.match?(/\A\$\{.+\}\z/)
          end

          # Validate hex string of specific length
          #
          # @param value [String] The hex string
          # @param length [Integer] Expected length
          # @param allow_interpolation [Boolean] Allow Terraform interpolations
          # @return [String] The validated value
          def valid_hex!(value, length:, allow_interpolation: true)
            return value if allow_interpolation && terraform_interpolation?(value)

            unless value.match?(/\A[a-f0-9]{#{length}}\z/i)
              raise ValidationError, "Expected #{length}-char hex string: #{value}"
            end
            value
          end

          # Validate JSON string
          #
          # @param value [String] The JSON string
          # @return [String] The validated JSON
          def valid_json!(value)
            JSON.parse(value)
            value
          rescue JSON::ParserError
            raise ValidationError, "Invalid JSON: #{value[0..50]}..."
          end

          # Validate base64 encoded string
          #
          # @param value [String] The base64 string
          # @return [String] The validated string
          def valid_base64!(value)
            unless value.match?(/\A[A-Za-z0-9+\/]*={0,2}\z/)
              raise ValidationError, "Invalid base64 format"
            end
            begin
              Base64.strict_decode64(value)
              value
            rescue ArgumentError
              raise ValidationError, "Invalid base64 encoding"
            end
          end
        end
      end
    end
  end
end
