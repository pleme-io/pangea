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


require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
      # Type-safe attributes for AWS CloudFront Public Key resources
      class CloudFrontPublicKeyAttributes < Dry::Struct
        # Name for the public key
        attribute :name, Resources::Types::String

        # The public key data (PEM format)
        attribute :encoded_key, Resources::Types::String

        # Comment/description for the public key
        attribute :comment, Resources::Types::String.optional

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)
          
          # Validate name format
          unless attrs.name.match?(/\A[a-zA-Z0-9\-_]{1,128}\z/)
            raise Dry::Struct::Error, "Public key name must be 1-128 characters and contain only alphanumeric, hyphens, and underscores"
          end

          # Validate public key format
          unless attrs.valid_public_key_format?
            raise Dry::Struct::Error, "Invalid public key format - must be PEM encoded RSA public key"
          end

          # Set default comment if not provided
          unless attrs.comment
            attrs = attrs.copy_with(comment: "CloudFront public key for #{attrs.name}")
          end

          attrs
        end

        # Helper methods
        def valid_public_key_format?
          # Check if the key looks like a PEM-formatted RSA public key
          encoded_key.include?('-----BEGIN PUBLIC KEY-----') &&
          encoded_key.include?('-----END PUBLIC KEY-----') &&
          encoded_key.strip.lines.length > 5
        end

        def key_size
          # Extract key size from the public key (simplified)
          # In practice, you'd use OpenSSL to parse this
          if encoded_key.length > 800
            "4096-bit"
          elsif encoded_key.length > 400
            "2048-bit"
          else
            "1024-bit"
          end
        end

        def key_type
          if encoded_key.include?('RSA PUBLIC KEY')
            "RSA"
          elsif encoded_key.include?('EC PUBLIC KEY')
            "EC"
          else
            "RSA" # Default assumption
          end
        end

        def estimated_monthly_cost
          "$0.00 (no additional charge for public keys)"
        end

        def validate_configuration
          warnings = []
          
          if key_size == "1024-bit"
            warnings << "1024-bit key size is deprecated - consider using 2048-bit or higher"
          end
          
          if name.length < 3
            warnings << "Very short public key name - consider more descriptive naming"
          end
          
          if comment && comment.include?(encoded_key[0,20])
            warnings << "Comment contains key data - avoid including sensitive information"
          end
          
          warnings
        end

        # Check if this is a strong key
        def strong_key?
          key_size.to_i >= 2048
        end

        # Get security level
        def security_level
          case key_size
          when "4096-bit"
            "high"
          when "2048-bit"
            "medium"
          else
            "low"
          end
        end
      end

      # Common CloudFront public key configurations
      module CloudFrontPublicKeyConfigs
        # Standard public key for field-level encryption
        def self.field_level_encryption_key(key_name, public_key_pem)
          {
            name: key_name,
            encoded_key: public_key_pem,
            comment: "Public key for CloudFront field-level encryption"
          }
        end

        # Development public key with descriptive naming
        def self.development_key(project_name, public_key_pem)
          {
            name: "#{project_name.downcase.gsub(/[^a-z0-9]/, '-')}-dev-key",
            encoded_key: public_key_pem,
            comment: "Development public key for #{project_name}"
          }
        end

        # Production public key with security metadata
        def self.production_key(service_name, public_key_pem)
          {
            name: "#{service_name.downcase.gsub(/[^a-z0-9]/, '-')}-prod-key",
            encoded_key: public_key_pem,
            comment: "Production public key for #{service_name} field-level encryption"
          }
        end

        # Corporate security key
        def self.corporate_security_key(organization, key_purpose, public_key_pem)
          {
            name: "#{organization.downcase.gsub(/[^a-z0-9]/, '-')}-#{key_purpose.downcase.gsub(/[^a-z0-9]/, '-')}-key",
            encoded_key: public_key_pem,
            comment: "Corporate security key for #{key_purpose} - #{organization}"
          }
        end

        # Multi-environment key
        def self.multi_environment_key(application_name, environment, public_key_pem)
          {
            name: "#{application_name.downcase.gsub(/[^a-z0-9]/, '-')}-#{environment}-encryption-key",
            encoded_key: public_key_pem,
            comment: "#{environment.capitalize} encryption key for #{application_name}"
          }
        end
      end
    end
      end
    end
  end
end