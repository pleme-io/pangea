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
      # Type-safe attributes for AWS Redshift Snapshot Schedule resources
      class RedshiftSnapshotScheduleAttributes < Dry::Struct
        # Schedule identifier (required)
        attribute :identifier, Resources::Types::String
        
        # Schedule description
        attribute :description, Resources::Types::String.optional
        
        # Schedule definitions (required)
        # Format: "rate(12 hours)" or "cron(0 12 * * ? *)"
        attribute :definitions, Resources::Types::Array.of(Types::String).constrained(min_size: 1)
        
        # Force destroy
        attribute :force_destroy, Resources::Types::Bool.default(false)
        
        # Tags
        attribute :tags, Resources::Types::AwsTags.default({}.freeze)

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)
          
          # Validate identifier format
          unless attrs.identifier =~ /\A[a-zA-Z][a-zA-Z0-9\-_]*\z/
            raise Dry::Struct::Error, "Schedule identifier must start with letter and contain only alphanumeric, hyphens, and underscores"
          end
          
          # Validate identifier length
          if attrs.identifier.length > 255
            raise Dry::Struct::Error, "Schedule identifier must be 255 characters or less"
          end
          
          # Validate schedule definitions
          attrs.definitions.each do |definition|
            unless valid_schedule_definition?(definition)
              raise Dry::Struct::Error, "Invalid schedule definition: #{definition}. Must be rate() or cron() expression"
            end
          end
          
          # Validate maximum definitions
          if attrs.definitions.length > 50
            raise Dry::Struct::Error, "Maximum 50 schedule definitions allowed"
          end

          attrs
        end

        # Validate schedule definition format
        def self.valid_schedule_definition?(definition)
          # Check for rate expressions
          if definition.start_with?("rate(")
            return definition.match?(/\Arate\(\d+\s+(hours?|days?)\)\z/)
          end
          
          # Check for cron expressions
          if definition.start_with?("cron(")
            # Basic cron validation - 6 fields for Redshift
            cron_expr = definition[5..-2] # Remove "cron(" and ")"
            fields = cron_expr.split
            return fields.length == 6
          end
          
          false
        end

        # Parse rate expression to hours
        def self.parse_rate_to_hours(rate_expr)
          match = rate_expr.match(/rate\((\d+)\s+(hours?|days?)\)/)
          return nil unless match
          
          value = match[1].to_i
          unit = match[2]
          
          case unit
          when /hours?/
            value
          when /days?/
            value * 24
          else
            nil
          end
        end

        # Check if schedule has rate-based definitions
        def has_rate_schedules?
          definitions.any? { |d| d.start_with?("rate(") }
        end

        # Check if schedule has cron-based definitions
        def has_cron_schedules?
          definitions.any? { |d| d.start_with?("cron(") }
        end

        # Get minimum snapshot interval in hours
        def minimum_interval_hours
          rate_intervals = definitions
            .select { |d| d.start_with?("rate(") }
            .map { |d| self.class.parse_rate_to_hours(d) }
            .compact
          
          rate_intervals.min
        end

        # Get maximum snapshot interval in hours
        def maximum_interval_hours
          rate_intervals = definitions
            .select { |d| d.start_with?("rate(") }
            .map { |d| self.class.parse_rate_to_hours(d) }
            .compact
          
          rate_intervals.max
        end

        # Calculate snapshots per day
        def estimated_snapshots_per_day
          return 0 if definitions.empty?
          
          daily_snapshots = 0
          
          # Count rate-based snapshots
          definitions.each do |definition|
            if definition.start_with?("rate(")
              hours = self.class.parse_rate_to_hours(definition)
              daily_snapshots += (24.0 / hours).ceil if hours
            elsif definition.start_with?("cron(")
              # Rough estimate for cron - assume 1 per cron entry
              daily_snapshots += 1
            end
          end
          
          daily_snapshots
        end

        # Estimate monthly storage for snapshots (incremental)
        def estimated_monthly_storage_gb(cluster_size_gb, change_rate = 0.05)
          snapshots_per_month = estimated_snapshots_per_day * 30
          
          # First snapshot is full size, subsequent are incremental
          full_snapshot_size = cluster_size_gb
          incremental_size = cluster_size_gb * change_rate
          
          # Storage = 1 full + (n-1) incrementals
          full_snapshot_size + (snapshots_per_month - 1) * incremental_size
        end

        # Generate description if not provided
        def generated_description
          return description if description
          
          if definitions.length == 1
            "Snapshot schedule: #{definitions.first}"
          else
            "Snapshot schedule with #{definitions.length} definitions"
          end
        end

        # Check if this is a high-frequency schedule
        def high_frequency?
          min_interval = minimum_interval_hours
          min_interval && min_interval <= 4
        end

        # Common schedule templates
        def self.template_definitions(template)
          case template.to_s
          when "hourly"
            ["rate(1 hour)"]
          when "daily"
            ["cron(0 2 * * ? *)"] # 2 AM daily
          when "twice_daily"
            ["cron(0 2 * * ? *)", "cron(0 14 * * ? *)"] # 2 AM and 2 PM
          when "business_hours"
            ["cron(0 8 * * MON-FRI *)", "cron(0 18 * * MON-FRI *)"] # 8 AM and 6 PM weekdays
          when "weekly"
            ["cron(0 2 ? * SUN *)"] # 2 AM Sunday
          when "monthly"
            ["cron(0 2 1 * ? *)"] # 2 AM first day of month
          when "continuous"
            ["rate(1 hour)"] # Every hour
          when "compliance"
            ["rate(4 hours)"] # Every 4 hours for compliance
          else
            []
          end
        end

        # Generate schedule for retention policy
        def self.schedule_for_retention(retention_days)
          case retention_days
          when 1..3
            { definitions: ["rate(4 hours)"], description: "High frequency for short retention" }
          when 4..7
            { definitions: ["rate(6 hours)"], description: "4 snapshots daily for weekly retention" }
          when 8..30
            { definitions: ["rate(12 hours)"], description: "Twice daily for monthly retention" }
          when 31..90
            { definitions: ["cron(0 2 * * ? *)"], description: "Daily for quarterly retention" }
          else
            { definitions: ["cron(0 2 ? * SUN *)"], description: "Weekly for long-term retention" }
          end
        end
      end
    end
      end
    end
  end
end