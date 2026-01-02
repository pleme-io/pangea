# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

module Pangea
  module Resources
    module AWS
      module Types
        module RedshiftSnapshotScheduleInstanceMethods
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
        end
      end
    end
  end
end
