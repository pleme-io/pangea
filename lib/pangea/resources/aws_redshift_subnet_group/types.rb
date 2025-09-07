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
      # Type-safe attributes for AWS Redshift Subnet Group resources
      class RedshiftSubnetGroupAttributes < Dry::Struct
        # Subnet group name (required)
        attribute :name, Resources::Types::String
        
        # Description
        attribute :description, Resources::Types::String.optional
        
        # Subnet IDs (required)
        attribute :subnet_ids, Resources::Types::Array.of(Types::String).constrained(min_size: 1)
        
        # Tags
        attribute :tags, Resources::Types::AwsTags.default({}.freeze)

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)
          
          # Validate subnet group name format
          unless attrs.name =~ /\A[a-z][a-z0-9\-]*\z/
            raise Dry::Struct::Error, "Subnet group name must start with lowercase letter and contain only lowercase letters, numbers, and hyphens"
          end
          
          # Validate subnet group name length
          if attrs.name.length > 255
            raise Dry::Struct::Error, "Subnet group name must be 255 characters or less"
          end
          
          # Validate subnet count for multi-AZ
          if attrs.subnet_ids.length < 2
            raise Dry::Struct::Error, "At least 2 subnets in different AZs recommended for high availability"
          end

          attrs
        end

        # Check if subnet group supports multi-AZ
        def multi_az_capable?
          subnet_ids.length >= 2
        end

        # Check if subnet group has redundancy
        def has_redundancy?
          subnet_ids.length >= 3
        end

        # Get subnet count
        def subnet_count
          subnet_ids.length
        end

        # Estimate AZ coverage (assumes different subnets are in different AZs)
        def estimated_az_count
          # In practice, this would need actual subnet AZ lookup
          # For now, assume each subnet is in a different AZ up to 3
          [subnet_ids.length, 3].min
        end

        # Generate description if not provided
        def generated_description
          description || "Redshift subnet group with #{subnet_count} subnets"
        end

        # Check if this appears to be a production subnet group
        def production_grade?
          multi_az_capable? && (name.include?("prod") || tags.any? { |k, v| v.to_s.downcase.include?("production") })
        end

        # Generate subnet group configurations for common scenarios
        def self.configuration_for_environment(env_type, subnet_ids)
          case env_type.to_s
          when "production"
            {
              name: "redshift-prod-subnet-group",
              description: "Production Redshift subnet group with multi-AZ support",
              subnet_ids: subnet_ids,
              tags: {
                Environment: "production",
                ManagedBy: "terraform",
                HighAvailability: "true"
              }
            }
          when "development"
            {
              name: "redshift-dev-subnet-group",
              description: "Development Redshift subnet group",
              subnet_ids: subnet_ids.first(2), # Use only 2 subnets for dev
              tags: {
                Environment: "development",
                ManagedBy: "terraform",
                CostCenter: "engineering"
              }
            }
          when "data-lake"
            {
              name: "redshift-data-lake-subnet-group",
              description: "Data lake Redshift subnet group for analytics workloads",
              subnet_ids: subnet_ids,
              tags: {
                Environment: "production",
                Workload: "analytics",
                DataClassification: "internal"
              }
            }
          else
            {
              name: "redshift-#{env_type}-subnet-group",
              subnet_ids: subnet_ids,
              tags: {
                Environment: env_type
              }
            }
          end
        end
      end
    end
      end
    end
  end
end