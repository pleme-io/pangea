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
      # Type-safe attributes for AWS ElastiCache Subnet Group resources
      class ElastiCacheSubnetGroupAttributes < Dry::Struct
        # Name of the subnet group
        attribute :name, Resources::Types::String

        # Description of the subnet group
        attribute :description, Resources::Types::String.optional

        # List of subnet IDs to include in the subnet group
        attribute :subnet_ids, Resources::Types::Array.of(Types::String).constrained(min_size: 1)

        # Tags to apply to the subnet group
        attribute :tags, Resources::Types::AwsTags.default({}.freeze)

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)
          
          # Validate subnet group name format
          unless attrs.name.match?(/\A[a-z0-9\-]+\z/)
            raise Dry::Struct::Error, "Subnet group name must contain only lowercase letters, numbers, and hyphens"
          end

          # Validate name length
          if attrs.name.length < 1 || attrs.name.length > 255
            raise Dry::Struct::Error, "Subnet group name must be between 1 and 255 characters"
          end

          # Cannot start or end with hyphen
          if attrs.name.start_with?('-') || attrs.name.end_with?('-')
            raise Dry::Struct::Error, "Subnet group name cannot start or end with a hyphen"
          end

          # Validate minimum subnet requirement
          if attrs.subnet_ids.length < 1
            raise Dry::Struct::Error, "At least one subnet ID is required"
          end

          # ElastiCache requires at least 2 subnets for Multi-AZ deployment
          if attrs.subnet_ids.length == 1
            # This is allowed but limits cluster to single-AZ
          end

          # Validate subnet ID format
          attrs.subnet_ids.each do |subnet_id|
            unless subnet_id.match?(/\Asubnet-[a-f0-9]{8,17}\z/)
              raise Dry::Struct::Error, "Invalid subnet ID format: #{subnet_id}"
            end
          end

          # Default description if not provided
          unless attrs.description
            attrs = attrs.copy_with(description: "ElastiCache subnet group for #{attrs.name}")
          end

          attrs
        end

        # Helper methods
        def subnet_count
          subnet_ids.length
        end

        def supports_multi_az?
          subnet_count >= 2
        end

        def is_single_az?
          subnet_count == 1
        end

        # Generate availability zones from subnet placement (if known)
        def inferred_availability_zones
          # This would require AWS API calls to determine actual AZs
          # For now, return empty array - could be enhanced with region mapping
          []
        end

        # Validate subnet group configuration
        def validate_configuration
          errors = []

          if is_single_az?
            errors << "Single subnet limits cluster to single-AZ deployment"
          end

          if subnet_count > 20
            errors << "Maximum of 20 subnets supported per subnet group"
          end

          errors
        end

        # Cost implications (subnet groups themselves are free)
        def has_cost_implications?
          false
        end

        def estimated_monthly_cost
          "$0.00/month (subnet groups are free)"
        end
      end

      # Common ElastiCache subnet group configurations
      module ElastiCacheSubnetGroupConfigs
        # Multi-AZ subnet group configuration
        def self.multi_az(name, subnet_ids, description: nil)
          {
            name: name,
            subnet_ids: subnet_ids,
            description: description || "Multi-AZ subnet group for #{name}"
          }
        end

        # Single-AZ subnet group configuration (for development/testing)
        def self.single_az(name, subnet_id, description: nil)
          {
            name: name,
            subnet_ids: [subnet_id],
            description: description || "Single-AZ subnet group for #{name}"
          }
        end

        # Private subnets configuration
        def self.private_subnets(name, private_subnet_ids)
          {
            name: "#{name}-private",
            subnet_ids: private_subnet_ids,
            description: "Private subnet group for #{name} ElastiCache clusters"
          }
        end
      end
    end
      end
    end
  end
end