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


require 'dry-struct'
require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
        # Secrets Manager Secret Version resource attributes with validation
        class SecretsManagerSecretVersionAttributes < Dry::Struct
          transform_keys(&:to_sym)
          
          attribute :secret_id, Resources::Types::String
          attribute :secret_string?, Resources::Types::SecretValue.optional
          attribute :secret_binary?, Resources::Types::SecretBinary.optional
          attribute :version_stages?, Resources::Types::Array.of(Resources::Types::SecretVersionStage).optional
          
          # Custom validation logic
          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}
            
            # Must have either secret_string or secret_binary, but not both
            if attrs[:secret_string] && attrs[:secret_binary]
              raise Dry::Struct::Error, "Cannot specify both secret_string and secret_binary"
            end
            
            if !attrs[:secret_string] && !attrs[:secret_binary]
              raise Dry::Struct::Error, "Must specify either secret_string or secret_binary"
            end
            
            # Validate secret_id format
            if attrs[:secret_id]
              validate_secret_id(attrs[:secret_id])
            end
            
            super(attrs)
          end
          
          # Secret ID validation helper
          def self.validate_secret_id(secret_id)
            # Can be secret name, ARN, or partial ARN
            valid_formats = [
              /\A[a-zA-Z0-9\/_+=.@-]{1,512}\z/,  # Secret name
              /\Aarn:aws:secretsmanager:[a-z0-9-]+:\d{12}:secret:[a-zA-Z0-9\/_+=.@-]+-[a-zA-Z0-9]{6}\z/  # Full ARN
            ]
            
            unless valid_formats.any? { |format| secret_id.match?(format) }
              raise Dry::Struct::Error, "Invalid secret ID format: #{secret_id}"
            end
          end
          
          # Computed properties
          def uses_string_value?
            !secret_string.nil?
          end
          
          def uses_binary_value?
            !secret_binary.nil?
          end
          
          def version_stage_count
            version_stages&.length || 1  # AWSCURRENT is default
          end
          
          def has_custom_stages?
            version_stages&.any? { |stage| !['AWSCURRENT', 'AWSPENDING'].include?(stage) }
          end
          
          def secret_value_type
            uses_string_value? ? 'string' : 'binary'
          end
          
          def estimated_value_size
            if uses_string_value?
              secret_string.is_a?(String) ? secret_string.length : "JSON object"
            else
              "Binary data (base64 encoded)"
            end
          end
        end
      end
    end
  end
end