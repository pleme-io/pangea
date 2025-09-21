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
      # Type-safe attributes for AWS EventBridge Bus resources
      class EventBridgeBusAttributes < Dry::Struct
        # Event bus name (required)
        attribute :name, Resources::Types::String.constrained(format: /\A[a-zA-Z0-9._-]{1,256}\z/)

        # Event source name (for partner event buses)
        attribute :event_source_name, Resources::Types::String.optional

        # KMS key for encryption
        attribute :kms_key_id, Resources::Types::String.optional

        # Tagging support
        attribute :tags, Resources::Types::AwsTags.default({}.freeze)

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)
          
          # Validate event bus name rules
          if attrs.name == "default"
            raise Dry::Struct::Error, "Cannot create a custom event bus named 'default' - it's reserved"
          end

          # AWS service event buses start with 'aws.'
          if attrs.name.start_with?('aws.') && !attrs.event_source_name
            raise Dry::Struct::Error, "Event bus names starting with 'aws.' are reserved for AWS services"
          end

          # Partner event bus validation
          if attrs.event_source_name
            unless attrs.event_source_name.match?(/\A[a-zA-Z0-9._-]+\z/)
              raise Dry::Struct::Error, "Event source name contains invalid characters"
            end
          end

          attrs
        end

        # Helper methods
        def is_default?
          name == "default"
        end

        def is_custom?
          !is_default? && !is_aws_service? && !is_partner?
        end

        def is_aws_service?
          name.start_with?('aws.')
        end

        def is_partner?
          !event_source_name.nil?
        end

        def has_encryption?
          !kms_key_id.nil?
        end

        def bus_type
          return "default" if is_default?
          return "aws_service" if is_aws_service?
          return "partner" if is_partner?
          "custom"
        end

        def estimated_monthly_cost
          # EventBridge pricing (simplified)
          return "Free (default bus)" if is_default?
          return "~$1.00/month" if is_custom?
          return "Partner pricing varies" if is_partner?
          "AWS service bus - included"
        end

        def max_rules_per_bus
          # Different limits based on bus type
          case bus_type
          when "default", "custom"
            300
          when "partner"
            100
          when "aws_service"
            "Varies by service"
          else
            300
          end
        end
      end

      # Common EventBridge Bus configurations
      module EventBridgeBusConfigs
        # Simple custom event bus
        def self.simple_custom_bus(name)
          {
            name: name
          }
        end

        # Encrypted custom event bus
        def self.encrypted_custom_bus(name, kms_key_id:)
          {
            name: name,
            kms_key_id: kms_key_id
          }
        end

        # Partner event bus
        def self.partner_event_bus(name, event_source_name:)
          {
            name: name,
            event_source_name: event_source_name
          }
        end

        # Application event bus with tagging
        def self.application_event_bus(name, application:, environment: "production")
          {
            name: name,
            tags: {
              Application: application,
              Environment: environment,
              Purpose: "EventDriven"
            }
          }
        end

        # Multi-tenant event bus
        def self.tenant_event_bus(tenant_id, environment: "production")
          {
            name: "tenant-#{tenant_id}",
            tags: {
              TenantId: tenant_id,
              Environment: environment,
              Purpose: "MultiTenant"
            }
          }
        end

        # Service mesh event bus
        def self.service_mesh_event_bus(service_name, version: "v1")
          {
            name: "#{service_name}-#{version}",
            tags: {
              Service: service_name,
              Version: version,
              Purpose: "ServiceMesh"
            }
          }
        end
      end
    end
      end
    end
  end
end