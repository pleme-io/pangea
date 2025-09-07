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
      # Type-safe attributes for AWS CloudFront Key Group resources
      class CloudFrontKeyGroupAttributes < Dry::Struct
        # Name for the key group
        attribute :name, Resources::Types::String

        # List of public key IDs in this group
        attribute :items, Resources::Types::Array.of(Types::String)

        # Comment/description for the key group
        attribute :comment, Resources::Types::String.optional

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)
          
          # Validate name format
          unless attrs.name.match?(/\A[a-zA-Z0-9\-_]{1,128}\z/)
            raise Dry::Struct::Error, "Key group name must be 1-128 characters and contain only alphanumeric, hyphens, and underscores"
          end

          # Validate that at least one public key is provided
          if attrs.items.empty?
            raise Dry::Struct::Error, "Key group must contain at least one public key ID"
          end

          # Validate maximum number of keys (AWS limit is typically 20)
          if attrs.items.length > 20
            raise Dry::Struct::Error, "Key group cannot contain more than 20 public keys"
          end

          # Validate public key ID format
          attrs.items.each do |key_id|
            unless key_id.match?(/\A[A-Z0-9]{14}\z/)
              raise Dry::Struct::Error, "Invalid public key ID format: #{key_id}"
            end
          end

          # Check for duplicate key IDs
          if attrs.items.uniq.length != attrs.items.length
            raise Dry::Struct::Error, "Key group contains duplicate public key IDs"
          end

          # Set default comment if not provided
          unless attrs.comment
            attrs = attrs.copy_with(comment: "CloudFront key group #{attrs.name} with #{attrs.items.length} key(s)")
          end

          attrs
        end

        # Helper methods
        def key_count
          items.length
        end

        def single_key?
          items.length == 1
        end

        def multiple_keys?
          items.length > 1
        end

        def estimated_monthly_cost
          "$0.00 (no additional charge for key groups)"
        end

        def validate_configuration
          warnings = []
          
          if single_key?
            warnings << "Key group contains only one key - consider adding backup keys for rotation"
          end
          
          if key_count > 10
            warnings << "Large number of keys in group - consider splitting for better management"
          end
          
          if name.length < 3
            warnings << "Very short key group name - consider more descriptive naming"
          end
          
          warnings
        end

        # Get security configuration
        def security_level
          case key_count
          when 1
            "basic"
          when 2..5
            "standard"
          else
            "high"
          end
        end

        # Check if suitable for production
        def production_ready?
          key_count >= 2 && name.length >= 5
        end

        # Get rotation capability
        def rotation_capable?
          multiple_keys?
        end
      end

      # Common CloudFront key group configurations
      module CloudFrontKeyGroupConfigs
        # Standard key group for field-level encryption
        def self.field_level_encryption_group(group_name, public_key_ids)
          {
            name: group_name,
            items: public_key_ids,
            comment: "Key group for CloudFront field-level encryption"
          }
        end

        # Single key group for simple encryption
        def self.single_key_group(group_name, public_key_id)
          {
            name: group_name,
            items: [public_key_id],
            comment: "Single-key group for #{group_name}"
          }
        end

        # Production key group with rotation capability
        def self.production_key_group(service_name, primary_key_id, backup_key_id)
          {
            name: "#{service_name.downcase.gsub(/[^a-z0-9]/, '-')}-prod-keys",
            items: [primary_key_id, backup_key_id],
            comment: "Production key group for #{service_name} with rotation capability"
          }
        end

        # Development key group
        def self.development_key_group(project_name, public_key_ids)
          {
            name: "#{project_name.downcase.gsub(/[^a-z0-9]/, '-')}-dev-keys",
            items: public_key_ids,
            comment: "Development key group for #{project_name}"
          }
        end

        # Corporate security key group
        def self.corporate_security_group(organization, department, public_key_ids)
          {
            name: "#{organization.downcase.gsub(/[^a-z0-9]/, '-')}-#{department.downcase.gsub(/[^a-z0-9]/, '-')}-security",
            items: public_key_ids,
            comment: "Corporate security key group for #{department} - #{organization}"
          }
        end

        # Multi-environment key group
        def self.multi_environment_group(application_name, environment, public_key_ids)
          {
            name: "#{application_name.downcase.gsub(/[^a-z0-9]/, '-')}-#{environment}-keygroup",
            items: public_key_ids,
            comment: "#{environment.capitalize} key group for #{application_name}"
          }
        end
      end
    end
      end
    end
  end
end