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
      # Type-safe attributes for AWS Systems Manager Maintenance Window resources
      class SsmMaintenanceWindowAttributes < Dry::Struct
        # Maintenance window name (required)
        attribute :name, Resources::Types::String

        # Schedule expression (required) - cron or rate format
        attribute :schedule, Resources::Types::String

        # Duration in hours (required)
        attribute :duration, Resources::Types::Integer.constrained(gteq: 1, lteq: 24)

        # Cutoff time in hours before end of maintenance window
        attribute :cutoff, Resources::Types::Integer.constrained(gteq: 0, lteq: 23)

        # Allow unassociated targets
        attribute :allow_unassociated_targets, Resources::Types::Bool.default(false)

        # Whether the maintenance window is enabled
        attribute :enabled, Resources::Types::Bool.default(true)

        # End date for the maintenance window (ISO 8601 format)
        attribute :end_date, Resources::Types::String.optional

        # Start date for the maintenance window (ISO 8601 format)
        attribute :start_date, Resources::Types::String.optional

        # Schedule timezone
        attribute :schedule_timezone, Resources::Types::String.optional

        # Schedule offset (days)
        attribute :schedule_offset, Resources::Types::Integer.optional.constrained(gteq: 1, lteq: 6)

        # Description of the maintenance window
        attribute :description, Resources::Types::String.optional

        # Tags for the maintenance window
        attribute :tags, Resources::Types::AwsTags.default({})

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)
          
          # Validate schedule expression format
          schedule = attrs.schedule.strip
          
          # Validate cron expression
          if schedule.start_with?('cron(')
            unless schedule.match?(/\Acron\(\s*(\*|[0-5]?\d|\d+\-\d+|\d+(,\d+)*|\d+\/\d+)\s+(\*|[0-2]?\d|1?\d\-2?\d|\d+(,\d+)*|\d+\/\d+)\s+(\*|\?|[1-2]?\d|3[01]|\d+\-\d+|\d+(,\d+)*|L|W|\d+W|LW)\s+(\*|\?|[1-9]|1[0-2]|JAN|FEB|MAR|APR|MAY|JUN|JUL|AUG|SEP|OCT|NOV|DEC|\d+\-\d+|\d+(,\d+)*)\s+(\*|\?|[0-6]|SUN|MON|TUE|WED|THU|FRI|SAT|\d+\-\d+|\d+(,\d+)*|L|#|\d+#\d+)\s+(\*|19[7-9]\d|20\d{2}|\d{4}\-\d{4}|\d+(,\d+)*)\s*\)\z/i)
              raise Dry::Struct::Error, "Invalid cron expression format. Use: cron(minute hour day-of-month month day-of-week year)"
            end
          # Validate rate expression  
          elsif schedule.start_with?('rate(')
            unless schedule.match?(/\Arate\(\s*(\d+)\s+(minute|minutes|hour|hours|day|days)\s*\)\z/i)
              raise Dry::Struct::Error, "Invalid rate expression format. Use: rate(value unit) where unit is minute(s), hour(s), or day(s)"
            end
            
            # Extract and validate rate value
            match = schedule.match(/\Arate\(\s*(\d+)\s+(minute|minutes|hour|hours|day|days)\s*\)\z/i)
            if match
              value = match[1].to_i
              unit = match[2].downcase
              
              case unit
              when 'minute', 'minutes'
                if value < 15
                  raise Dry::Struct::Error, "Rate expression minimum value for minutes is 15"
                end
              when 'hour', 'hours'
                if value < 1
                  raise Dry::Struct::Error, "Rate expression minimum value for hours is 1"
                end
              when 'day', 'days'
                if value < 1
                  raise Dry::Struct::Error, "Rate expression minimum value for days is 1"
                end
              end
            end
          else
            raise Dry::Struct::Error, "Schedule must be a cron() or rate() expression"
          end

          # Validate cutoff is less than duration
          if attrs.cutoff >= attrs.duration
            raise Dry::Struct::Error, "Cutoff must be less than duration"
          end

          # Validate date formats
          if attrs.start_date
            begin
              DateTime.iso8601(attrs.start_date)
            rescue ArgumentError
              raise Dry::Struct::Error, "start_date must be in ISO 8601 format (YYYY-MM-DDTHH:MM:SSZ)"
            end
          end

          if attrs.end_date
            begin
              DateTime.iso8601(attrs.end_date)
            rescue ArgumentError
              raise Dry::Struct::Error, "end_date must be in ISO 8601 format (YYYY-MM-DDTHH:MM:SSZ)"
            end
          end

          # Validate date relationship
          if attrs.start_date && attrs.end_date
            start_time = DateTime.iso8601(attrs.start_date)
            end_time = DateTime.iso8601(attrs.end_date)
            
            if end_time <= start_time
              raise Dry::Struct::Error, "end_date must be after start_date"
            end
          end

          # Validate schedule offset
          if attrs.schedule_offset && !schedule.start_with?('cron(')
            raise Dry::Struct::Error, "schedule_offset can only be used with cron expressions"
          end

          # Validate timezone format
          if attrs.schedule_timezone
            # Basic timezone validation - should be IANA timezone
            unless attrs.schedule_timezone.match?(/\A[A-Za-z0-9_\/+-]+\z/)
              raise Dry::Struct::Error, "Invalid timezone format. Use IANA timezone format (e.g., 'America/New_York', 'UTC')"
            end
          end

          # Validate description length
          if attrs.description && attrs.description.length > 128
            raise Dry::Struct::Error, "Description cannot exceed 128 characters"
          end

          attrs
        end

        # Helper methods
        def is_enabled?
          enabled
        end

        def is_disabled?
          !enabled
        end

        def uses_cron_schedule?
          schedule.start_with?('cron(')
        end

        def uses_rate_schedule?
          schedule.start_with?('rate(')
        end

        def has_start_date?
          !start_date.nil?
        end

        def has_end_date?
          !end_date.nil?
        end

        def has_timezone?
          !schedule_timezone.nil?
        end

        def has_schedule_offset?
          !schedule_offset.nil?
        end

        def has_description?
          !description.nil?
        end

        def allows_unassociated_targets?
          allow_unassociated_targets
        end

        def duration_hours
          duration
        end

        def cutoff_hours
          cutoff
        end

        def effective_execution_time_hours
          duration - cutoff
        end

        def schedule_type
          if uses_cron_schedule?
            'cron'
          elsif uses_rate_schedule?
            'rate'
          else
            'unknown'
          end
        end

        def parsed_schedule_info
          if uses_cron_schedule?
            # Extract cron fields
            match = schedule.match(/\Acron\(\s*([^)]+)\s*\)\z/)
            return {} unless match
            
            fields = match[1].split(/\s+/)
            return {} unless fields.length == 6
            
            {
              minute: fields[0],
              hour: fields[1], 
              day_of_month: fields[2],
              month: fields[3],
              day_of_week: fields[4],
              year: fields[5]
            }
          elsif uses_rate_schedule?
            # Extract rate value and unit
            match = schedule.match(/\Arate\(\s*(\d+)\s+(minute|minutes|hour|hours|day|days)\s*\)\z/i)
            return {} unless match
            
            {
              value: match[1].to_i,
              unit: match[2].downcase.sub(/s$/, '') # normalize to singular
            }
          else
            {}
          end
        end

        def estimated_monthly_executions
          schedule_info = parsed_schedule_info
          return "Unknown" if schedule_info.empty?

          if uses_rate_schedule?
            case schedule_info[:unit]
            when 'minute'
              (30 * 24 * 60) / schedule_info[:value]
            when 'hour'
              (30 * 24) / schedule_info[:value]
            when 'day'
              30 / schedule_info[:value]
            else
              "Unknown"
            end
          elsif uses_cron_schedule?
            # Simplified estimation for common cron patterns
            cron = schedule_info
            if cron[:day_of_week] != '*' && cron[:day_of_week] != '?'
              # Weekly pattern
              4
            elsif cron[:day_of_month] != '*' && cron[:day_of_month] != '?'
              # Monthly pattern
              1
            elsif cron[:hour] != '*'
              # Daily pattern
              30
            else
              "Variable"
            end
          else
            "Unknown"
          end
        end
      end

      # Common SSM Maintenance Window configurations
      module SsmMaintenanceWindowConfigs
        # Daily maintenance window
        def self.daily_maintenance_window(name, hour: 2, duration: 4, cutoff: 1)
          {
            name: name,
            schedule: "cron(0 #{hour} * * ? *)",
            duration: duration,
            cutoff: cutoff,
            description: "Daily maintenance window"
          }
        end

        # Weekly maintenance window
        def self.weekly_maintenance_window(name, day_of_week: "SUN", hour: 2, duration: 6, cutoff: 1)
          {
            name: name,
            schedule: "cron(0 #{hour} ? * #{day_of_week} *)",
            duration: duration,
            cutoff: cutoff,
            description: "Weekly maintenance window"
          }
        end

        # Monthly maintenance window
        def self.monthly_maintenance_window(name, day_of_month: 1, hour: 2, duration: 8, cutoff: 1)
          {
            name: name,
            schedule: "cron(0 #{hour} #{day_of_month} * ? *)",
            duration: duration,
            cutoff: cutoff,
            description: "Monthly maintenance window"
          }
        end

        # Business hours maintenance window
        def self.business_hours_maintenance_window(name, day_of_week: "MON-FRI", hour: 14, timezone: "America/New_York")
          {
            name: name,
            schedule: "cron(0 #{hour} ? * #{day_of_week} *)",
            duration: 4,
            cutoff: 1,
            schedule_timezone: timezone,
            description: "Business hours maintenance window"
          }
        end

        # Off-hours maintenance window
        def self.off_hours_maintenance_window(name, timezone: "UTC")
          {
            name: name,
            schedule: "cron(0 2 ? * SUN *)",
            duration: 6,
            cutoff: 1,
            schedule_timezone: timezone,
            description: "Off-hours maintenance window"
          }
        end

        # Emergency maintenance window
        def self.emergency_maintenance_window(name)
          {
            name: name,
            schedule: "rate(7 days)", # Weekly but can be triggered manually
            duration: 12,
            cutoff: 2,
            allow_unassociated_targets: true,
            enabled: false, # Disabled by default, enable when needed
            description: "Emergency maintenance window"
          }
        end

        # Patch management window
        def self.patch_maintenance_window(name, day_of_week: "SAT", hour: 3)
          {
            name: name,
            schedule: "cron(0 #{hour} ? * #{day_of_week} *)",
            duration: 4,
            cutoff: 1,
            description: "Patch management maintenance window"
          }
        end
      end
    end
      end
    end
  end
end