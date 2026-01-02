# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

module Pangea
  module Resources
    module AWS
      module Types
        # Common SSM Maintenance Window configurations
        module SsmMaintenanceWindowConfigs
          def self.daily_maintenance_window(name, hour: 2, duration: 4, cutoff: 1)
            {
              name: name,
              schedule: "cron(0 #{hour} * * ? *)",
              duration: duration,
              cutoff: cutoff,
              description: 'Daily maintenance window'
            }
          end

          def self.weekly_maintenance_window(name, day_of_week: 'SUN', hour: 2, duration: 6, cutoff: 1)
            {
              name: name,
              schedule: "cron(0 #{hour} ? * #{day_of_week} *)",
              duration: duration,
              cutoff: cutoff,
              description: 'Weekly maintenance window'
            }
          end

          def self.monthly_maintenance_window(name, day_of_month: 1, hour: 2, duration: 8, cutoff: 1)
            {
              name: name,
              schedule: "cron(0 #{hour} #{day_of_month} * ? *)",
              duration: duration,
              cutoff: cutoff,
              description: 'Monthly maintenance window'
            }
          end

          def self.business_hours_maintenance_window(name, day_of_week: 'MON-FRI', hour: 14, timezone: 'America/New_York')
            {
              name: name,
              schedule: "cron(0 #{hour} ? * #{day_of_week} *)",
              duration: 4,
              cutoff: 1,
              schedule_timezone: timezone,
              description: 'Business hours maintenance window'
            }
          end

          def self.off_hours_maintenance_window(name, timezone: 'UTC')
            {
              name: name,
              schedule: 'cron(0 2 ? * SUN *)',
              duration: 6,
              cutoff: 1,
              schedule_timezone: timezone,
              description: 'Off-hours maintenance window'
            }
          end

          def self.emergency_maintenance_window(name)
            {
              name: name,
              schedule: 'rate(7 days)',
              duration: 12,
              cutoff: 2,
              allow_unassociated_targets: true,
              enabled: false,
              description: 'Emergency maintenance window'
            }
          end

          def self.patch_maintenance_window(name, day_of_week: 'SAT', hour: 3)
            {
              name: name,
              schedule: "cron(0 #{hour} ? * #{day_of_week} *)",
              duration: 4,
              cutoff: 1,
              description: 'Patch management maintenance window'
            }
          end
        end
      end
    end
  end
end
