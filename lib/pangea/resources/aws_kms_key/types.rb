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
        # KMS Key resource attributes with validation
        class KmsKeyAttributes < Dry::Struct
          transform_keys(&:to_sym)
          
          attribute :description, Pangea::Resources::Types::String
          attribute :key_usage?, Pangea::Resources::Types::String.default('ENCRYPT_DECRYPT').enum('ENCRYPT_DECRYPT', 'SIGN_VERIFY')
          attribute :key_spec?, Pangea::Resources::Types::String.default('SYMMETRIC_DEFAULT').enum(
            'SYMMETRIC_DEFAULT',
            'RSA_2048', 'RSA_3072', 'RSA_4096',
            'ECC_NIST_P256', 'ECC_NIST_P384', 'ECC_NIST_P521', 'ECC_SECG_P256K1'
          )
          attribute :policy?, Pangea::Resources::Types::String.optional
          attribute :bypass_policy_lockout_safety_check?, Pangea::Resources::Types::Bool.optional.default(false)
          attribute :deletion_window_in_days?, Pangea::Resources::Types::Integer.constrained(gteq: 7, lteq: 30).default(10).optional
          attribute :enable_key_rotation?, Pangea::Resources::Types::Bool.optional.default(false)
          attribute :multi_region?, Pangea::Resources::Types::Bool.optional.default(false)
          attribute :tags?, Pangea::Resources::Types::AwsTags.optional
          
          # Custom validation logic
          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}
            
            # Validate key usage and spec compatibility
            if attrs[:key_usage] && attrs[:key_spec]
              validate_key_usage_spec_compatibility(attrs[:key_usage], attrs[:key_spec])
            end
            
            # Validate key rotation compatibility
            if attrs[:enable_key_rotation] && attrs[:key_spec]
              validate_rotation_compatibility(attrs[:enable_key_rotation], attrs[:key_spec])
            end
            
            super(attrs)
          end
          
          # Key usage and spec compatibility validation
          def self.validate_key_usage_spec_compatibility(usage, spec)
            case usage
            when 'ENCRYPT_DECRYPT'
              # All key specs are valid for encrypt/decrypt
            when 'SIGN_VERIFY'
              unless ['RSA_2048', 'RSA_3072', 'RSA_4096', 'ECC_NIST_P256', 'ECC_NIST_P384', 'ECC_NIST_P521', 'ECC_SECG_P256K1'].include?(spec)
                raise Dry::Struct::Error, "Key spec #{spec} is not valid for SIGN_VERIFY usage"
              end
            end
          end
          
          # Key rotation compatibility validation
          def self.validate_rotation_compatibility(enable_rotation, spec)
            if enable_rotation && spec != 'SYMMETRIC_DEFAULT'
              raise Dry::Struct::Error, "Key rotation is only supported for SYMMETRIC_DEFAULT keys"
            end
          end
          
          # Computed properties
          def supports_encryption?
            key_usage == 'ENCRYPT_DECRYPT'
          end
          
          def supports_signing?
            key_usage == 'SIGN_VERIFY'
          end
          
          def is_symmetric?
            key_spec == 'SYMMETRIC_DEFAULT'
          end
          
          def is_asymmetric?
            !is_symmetric?
          end
          
          def supports_rotation?
            is_symmetric? && supports_encryption?
          end
          
          def key_algorithm_family
            case key_spec
            when 'SYMMETRIC_DEFAULT' then 'AES'
            when /^RSA_/ then 'RSA'
            when /^ECC_/ then 'ECC'
            else 'Unknown'
            end
          end
          
          def estimated_monthly_cost
            # AWS KMS pricing (approximate)
            base_cost = multi_region? ? 2.00 : 1.00  # Multi-region keys cost more
            rotation_cost = enable_key_rotation? ? 0.00 : 0.00  # Rotation is free
            base_cost + rotation_cost
          end
        end
        
      end
    end
  end
end