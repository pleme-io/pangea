# frozen_string_literal: true

require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
      # Type-safe attributes for AWS RDS DB Subnet Group resources
      class DbSubnetGroupAttributes < Dry::Struct
        # Subnet group name (required)
        attribute :name, Resources::Types::String

        # List of subnet IDs (minimum 2 subnets in different AZs required)
        attribute :subnet_ids, Resources::Types::Array.of(Types::String).constrained(min_size: 2)

        # Description for the subnet group
        attribute :description, Resources::Types::String.optional.default("Managed by Pangea")

        # Tags to apply to the subnet group
        attribute :tags, Resources::Types::AwsTags.default({})

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)
          
          # Validate subnet count
          if attrs.subnet_ids.length < 2
            raise Dry::Struct::Error, "DB subnet groups require at least 2 subnets in different Availability Zones"
          end

          # Validate unique subnet IDs
          if attrs.subnet_ids.uniq.length != attrs.subnet_ids.length
            raise Dry::Struct::Error, "Subnet IDs must be unique within the subnet group"
          end

          # Validate subnet ID format
          attrs.subnet_ids.each do |subnet_id|
            unless subnet_id.match?(/^subnet-[a-f0-9]+$/)
              raise Dry::Struct::Error, "Invalid subnet ID format: #{subnet_id}. Expected format: subnet-xxxxxxxx"
            end
          end

          attrs
        end

        # Get the number of subnets
        def subnet_count
          subnet_ids.length
        end

        # Check if this is a multi-AZ configuration
        def is_multi_az?
          subnet_count >= 2
        end

        # Generate a description if none provided
        def effective_description
          description || "DB subnet group with #{subnet_count} subnets for #{name}"
        end

        # Validate subnet group for different database engines
        def validate_for_engine(engine)
          case engine
          when /aurora/
            # Aurora clusters require subnets in multiple AZs
            if subnet_count < 2
              raise "Aurora clusters require subnets in at least 2 Availability Zones"
            end
          when /rds/
            # Standard RDS instances can work with single subnet for single-AZ
            # but multi-AZ requires multiple subnets
            true
          else
            true
          end
        end

        # Estimate monthly cost (minimal cost for subnet groups)
        def estimated_monthly_cost
          "$0.00/month (no direct cost for subnet groups)"
        end
      end
    end
      end
    end
  end
end