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
        # KMS Alias resource attributes with validation
        class KmsAliasAttributes < Dry::Struct
          transform_keys(&:to_sym)
          
          attribute :name, Pangea::Resources::Types::String.constrained(
            format: /\Aalias\/[a-zA-Z0-9\/_-]{1,256}\z/
          ).constructor { |value|
            # Additional validation beyond regex
            alias_part = value.sub('alias/', '')
            
            if alias_part.start_with?('aws/')
              raise Dry::Types::ConstraintError, "KMS alias name cannot start with 'alias/aws/': #{value}"
            end
            
            value
          }
          attribute :target_key_id, Pangea::Resources::Types::String
          
          # Custom validation logic
          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}
            
            # Validate alias name format
            if attrs[:name]
              validate_alias_name(attrs[:name])
            end
            
            # Validate target key ID format
            if attrs[:target_key_id]
              validate_target_key_id(attrs[:target_key_id])
            end
            
            super(attrs)
          end
          
          # Alias name validation helper
          def self.validate_alias_name(name)
            # Must start with "alias/"
            unless name.start_with?('alias/')
              raise Dry::Struct::Error, "KMS alias name must start with 'alias/': #{name}"
            end
            
            # Extract the alias part after "alias/"
            alias_part = name.sub('alias/', '')
            
            # Check length (1-256 characters after "alias/")
            if alias_part.empty? || alias_part.length > 256
              raise Dry::Struct::Error, "KMS alias name must be 1-256 characters after 'alias/': #{name}"
            end
            
            # Check for valid characters (alphanumeric, hyphens, underscores, forward slashes)
            unless alias_part.match?(/\A[a-zA-Z0-9\/_-]+\z/)
              raise Dry::Struct::Error, "KMS alias name contains invalid characters: #{name}"
            end
            
            # Cannot start with "aws/" (reserved for AWS managed aliases)
            if alias_part.start_with?('aws/')
              raise Dry::Struct::Error, "KMS alias name cannot start with 'alias/aws/': #{name}"
            end
          end
          
          # Target key ID validation helper
          def self.validate_target_key_id(key_id)
            # Can be key ID or key ARN
            valid_formats = [
              /\A[a-f0-9-]{36}\z/,  # Key ID format
              /\Aarn:aws:kms:[a-z0-9-]+:\d{12}:key\/[a-f0-9-]{36}\z/  # Key ARN format
            ]
            
            unless valid_formats.any? { |format| key_id.match?(format) }
              raise Dry::Struct::Error, "Invalid target key ID format: #{key_id}"
            end
          end
          
          # Computed properties
          def alias_suffix
            name.sub('alias/', '')
          end
          
          def is_service_alias?
            alias_suffix.include?('/')
          end
          
          def estimated_alias_purpose
            suffix = alias_suffix.downcase
            case suffix
            when /secret/ then 'Secrets Manager encryption'
            when /rds/ then 'RDS encryption'
            when /s3/ then 'S3 bucket encryption'
            when /lambda/ then 'Lambda environment encryption'
            when /ebs/ then 'EBS volume encryption'
            else 'General purpose encryption'
            end
          end
          
          def uses_key_id?
            target_key_id.match?(/\A[a-f0-9-]{36}\z/)
          end
          
          def uses_key_arn?
            target_key_id.start_with?('arn:aws:kms:')
          end
        end
        
      end
    end
  end
end