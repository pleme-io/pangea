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
        # Secrets Manager Secret resource attributes with validation
        class SecretsManagerSecretAttributes < Dry::Struct
          transform_keys(&:to_sym)
          
          attribute :name?, Resources::Types::SecretName.optional
          attribute :description?, Resources::Types::String.optional
          attribute :kms_key_id?, Resources::Types::String.optional
          attribute :policy?, SecretResourcePolicy.optional
          attribute :recovery_window_in_days?, Resources::Types::SecretsManagerRecoveryWindowInDays.optional
          attribute :force_overwrite_replica_secret?, Resources::Types::Bool.optional.default(false)
          attribute :replica?, Resources::Types::Array.of(Resources::Types::SecretsManagerReplicaRegion).optional
          attribute :tags?, Resources::Types::AwsTags.optional
          
          # Custom validation logic
          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}
            
            # Validate secret name if provided
            if attrs[:name]
              validate_secret_name(attrs[:name])
            end
            
            # Validate KMS key ID format if provided
            if attrs[:kms_key_id]
              validate_kms_key_id(attrs[:kms_key_id])
            end
            
            # Validate policy JSON if provided
            if attrs[:policy]
              validate_secret_policy(attrs[:policy])
            end
            
            # Validate replica configurations
            if attrs[:replica]
              validate_replica_config(attrs[:replica])
            end
            
            super(attrs)
          end
          
          # Secret name validation helper
          def self.validate_secret_name(name)
            # AWS Secrets Manager naming rules
            if name.length > 512
              raise Dry::Struct::Error, "Secret name too long: #{name.length} characters (max 512)"
            end
            
            # Cannot start or end with slash
            if name.start_with?('/') || name.end_with?('/')
              raise Dry::Struct::Error, "Secret name cannot start or end with slash: #{name}"
            end
            
            # Cannot contain consecutive slashes
            if name.include?('//')
              raise Dry::Struct::Error, "Secret name cannot contain consecutive slashes: #{name}"
            end
            
            # Valid characters only
            unless name.match?(/\A[a-zA-Z0-9\/_+=.@-]+\z/)
              raise Dry::Struct::Error, "Secret name contains invalid characters: #{name}"
            end
          end
          
          # KMS key ID validation helper
          def self.validate_kms_key_id(key_id)
            # Can be key ID, key ARN, alias name, or alias ARN
            valid_formats = [
              /\A[a-f0-9-]{36}\z/,  # Key ID
              /\Aarn:aws:kms:[a-z0-9-]+:\d{12}:key\/[a-f0-9-]{36}\z/,  # Key ARN
              /\Aalias\/[a-zA-Z0-9:/_-]+\z/,  # Alias name
              /\Aarn:aws:kms:[a-z0-9-]+:\d{12}:alias\/[a-zA-Z0-9:/_-]+\z/  # Alias ARN
            ]
            
            unless valid_formats.any? { |format| key_id.match?(format) }
              raise Dry::Struct::Error, "Invalid KMS key ID format: #{key_id}"
            end
          end
          
          # Secret policy validation helper
          def self.validate_secret_policy(policy)
            # Basic JSON validation
            begin
              parsed = JSON.parse(policy)
              
              # Must be a JSON object
              unless parsed.is_a?(Hash)
                raise Dry::Struct::Error, "Secret policy must be a JSON object"
              end
              
              # Should have Version and Statement
              unless parsed['Version'] && parsed['Statement']
                raise Dry::Struct::Error, "Secret policy should have Version and Statement fields"
              end
              
            rescue JSON::ParserError => e
              raise Dry::Struct::Error, "Invalid JSON in secret policy: #{e.message}"
            end
          end
          
          # Replica configuration validation
          def self.validate_replica_config(replicas)
            # Check for duplicate regions
            regions = replicas.map { |r| r[:region] }
            if regions.uniq.length != regions.length
              raise Dry::Struct::Error, "Duplicate regions found in replica configuration"
            end
            
            # Validate each replica region
            replicas.each do |replica|
              if replica[:kms_key_id]
                validate_kms_key_id(replica[:kms_key_id])
              end
            end
          end
          
          # Computed properties
          def is_cross_region?
            replica&.any?
          end
          
          def replica_count
            replica&.length || 0
          end
          
          def uses_custom_kms_key?
            !kms_key_id.nil?
          end
          
          def has_resource_policy?
            !policy.nil?
          end
          
          def recovery_period_days
            recovery_window_in_days || 30
          end
          
          def estimated_replication_regions
            return [] unless replica
            replica.map { |r| r[:region] }
          end
          
          def secret_scope
            if is_cross_region?
              "Multi-region secret replicated to #{replica_count} regions"
            else
              "Single-region secret"
            end
          end
          
          def encryption_details
            if uses_custom_kms_key?
              "Custom KMS key: #{kms_key_id}"
            else
              "AWS managed key (aws/secretsmanager)"
            end
          end
        end
        
        # Secret resource policy validation type
        SecretResourcePolicy = Resources::Types::String.constructor { |value|
          # Validate it's proper JSON
          begin
            parsed = JSON.parse(value)
            unless parsed.is_a?(Hash)
              raise Dry::Types::ConstraintError, "Secret policy must be a JSON object"
            end
            value
          rescue JSON::ParserError => e
            raise Dry::Types::ConstraintError, "Invalid JSON in secret policy: #{e.message}"
          end
        }
      end
    end
  end
end