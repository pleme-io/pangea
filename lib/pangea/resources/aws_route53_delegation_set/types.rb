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
      # Type-safe attributes for AWS Route53 Delegation Set resources
      class Route53DelegationSetAttributes < Dry::Struct
        # Reference name for the delegation set (optional)
        attribute :reference_name, Resources::Types::String.optional

        # Whether to use the same delegation set for all hosted zones
        attribute :reusable_delegation_set, Resources::Types::Bool.default(true)

        # Tags to apply to the delegation set
        attribute :tags, Resources::Types::AwsTags.default({}.freeze)

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)
          
          # Validate reference name if provided
          if attrs.reference_name
            unless attrs.reference_name.match?(/\A[a-zA-Z0-9\-_]{1,32}\z/)
              raise Dry::Struct::Error, "Reference name must be 1-32 characters and contain only alphanumeric, hyphens, and underscores"
            end
          end

          # Set default reference name if not provided
          unless attrs.reference_name
            attrs = attrs.copy_with(reference_name: "delegation-set-#{SecureRandom.hex(8)}")
          end

          attrs
        end

        # Helper methods
        def estimated_monthly_cost
          "$0.00 (included with hosted zones)"
        end

        def validate_configuration
          warnings = []
          
          if reference_name && reference_name.length < 3
            warnings << "Very short reference name - consider using more descriptive name"
          end
          
          warnings
        end

        # Check if this is a custom delegation set
        def custom_delegation_set?
          reference_name.present?
        end

        # Get delegation set type
        def delegation_set_type
          reusable_delegation_set ? "reusable" : "single-use"
        end
      end

      # Common Route53 delegation set configurations
      module Route53DelegationSetConfigs
        # Standard reusable delegation set
        def self.reusable_delegation_set(reference_name)
          {
            reference_name: reference_name,
            reusable_delegation_set: true
          }
        end

        # Corporate delegation set for multiple domains
        def self.corporate_delegation_set(organization_name)
          {
            reference_name: "#{organization_name.downcase.gsub(/[^a-z0-9]/, '-')}-delegation-set",
            reusable_delegation_set: true,
            tags: {
              Organization: organization_name,
              Purpose: "Corporate DNS delegation set"
            }
          }
        end

        # Development delegation set
        def self.development_delegation_set(project_name)
          {
            reference_name: "#{project_name.downcase.gsub(/[^a-z0-9]/, '-')}-dev-delegation",
            reusable_delegation_set: true,
            tags: {
              Project: project_name,
              Environment: "development",
              Purpose: "Development DNS delegation set"
            }
          }
        end

        # Production delegation set with enhanced tagging
        def self.production_delegation_set(service_name, organization)
          {
            reference_name: "#{service_name.downcase.gsub(/[^a-z0-9]/, '-')}-prod-delegation",
            reusable_delegation_set: true,
            tags: {
              Service: service_name,
              Organization: organization,
              Environment: "production",
              CriticalityLevel: "high",
              Purpose: "Production DNS delegation set"
            }
          }
        end
      end
    end
      end
    end
  end
end