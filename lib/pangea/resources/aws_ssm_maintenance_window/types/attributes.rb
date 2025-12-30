# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
        # Type-safe attributes for AWS Systems Manager Maintenance Window resources
        class SsmMaintenanceWindowAttributes < Dry::Struct
          attribute :name, Resources::Types::String
          attribute :schedule, Resources::Types::String
          attribute :duration, Resources::Types::Integer.constrained(gteq: 1, lteq: 24)
          attribute :cutoff, Resources::Types::Integer.constrained(gteq: 0, lteq: 23)
          attribute :allow_unassociated_targets, Resources::Types::Bool.default(false)
          attribute :enabled, Resources::Types::Bool.default(true)
          attribute :end_date, Resources::Types::String.optional
          attribute :start_date, Resources::Types::String.optional
          attribute :schedule_timezone, Resources::Types::String.optional
          attribute :schedule_offset, Resources::Types::Integer.optional.constrained(gteq: 1, lteq: 6)
          attribute :description, Resources::Types::String.optional
          attribute :tags, Resources::Types::AwsTags.default({}.freeze)

          def self.new(attributes = {})
            attrs = super(attributes)
            validate_schedule!(attrs.schedule)
            validate_cutoff!(attrs)
            validate_dates!(attrs)
            validate_schedule_offset!(attrs)
            validate_timezone!(attrs)
            validate_description!(attrs)
            attrs
          end

          def self.validate_schedule!(schedule)
            schedule = schedule.strip
            if schedule.start_with?('cron(')
              validate_cron_expression!(schedule)
            elsif schedule.start_with?('rate(')
              validate_rate_expression!(schedule)
            else
              raise Dry::Struct::Error, 'Schedule must be a cron() or rate() expression'
            end
          end

          def self.validate_cron_expression!(schedule)
            return if schedule.match?(/\Acron\(\s*(\*|[0-5]?\d|\d+\-\d+|\d+(,\d+)*|\d+\/\d+)\s+(\*|[0-2]?\d|1?\d\-2?\d|\d+(,\d+)*|\d+\/\d+)\s+(\*|\?|[1-2]?\d|3[01]|\d+\-\d+|\d+(,\d+)*|L|W|\d+W|LW)\s+(\*|\?|[1-9]|1[0-2]|JAN|FEB|MAR|APR|MAY|JUN|JUL|AUG|SEP|OCT|NOV|DEC|\d+\-\d+|\d+(,\d+)*)\s+(\*|\?|[0-6]|SUN|MON|TUE|WED|THU|FRI|SAT|\d+\-\d+|\d+(,\d+)*|L|#|\d+#\d+)\s+(\*|19[7-9]\d|20\d{2}|\d{4}\-\d{4}|\d+(,\d+)*)\s*\)\z/i)

            raise Dry::Struct::Error, 'Invalid cron expression format. Use: cron(minute hour day-of-month month day-of-week year)'
          end

          def self.validate_rate_expression!(schedule)
            match = schedule.match(/\Arate\(\s*(\d+)\s+(minute|minutes|hour|hours|day|days)\s*\)\z/i)
            raise Dry::Struct::Error, 'Invalid rate expression format. Use: rate(value unit) where unit is minute(s), hour(s), or day(s)' unless match

            value = match[1].to_i
            unit = match[2].downcase
            min_values = { 'minute' => 15, 'minutes' => 15, 'hour' => 1, 'hours' => 1, 'day' => 1, 'days' => 1 }
            raise Dry::Struct::Error, "Rate expression minimum value for #{unit} is #{min_values[unit]}" if value < min_values[unit]
          end

          def self.validate_cutoff!(attrs)
            raise Dry::Struct::Error, 'Cutoff must be less than duration' if attrs.cutoff >= attrs.duration
          end

          def self.validate_dates!(attrs)
            if attrs.start_date
              begin
                DateTime.iso8601(attrs.start_date)
              rescue ArgumentError
                raise Dry::Struct::Error, 'start_date must be in ISO 8601 format (YYYY-MM-DDTHH:MM:SSZ)'
              end
            end

            if attrs.end_date
              begin
                DateTime.iso8601(attrs.end_date)
              rescue ArgumentError
                raise Dry::Struct::Error, 'end_date must be in ISO 8601 format (YYYY-MM-DDTHH:MM:SSZ)'
              end
            end

            return unless attrs.start_date && attrs.end_date

            start_time = DateTime.iso8601(attrs.start_date)
            end_time = DateTime.iso8601(attrs.end_date)
            raise Dry::Struct::Error, 'end_date must be after start_date' if end_time <= start_time
          end

          def self.validate_schedule_offset!(attrs)
            raise Dry::Struct::Error, 'schedule_offset can only be used with cron expressions' if attrs.schedule_offset && !attrs.schedule.start_with?('cron(')
          end

          def self.validate_timezone!(attrs)
            return unless attrs.schedule_timezone
            raise Dry::Struct::Error, "Invalid timezone format. Use IANA timezone format (e.g., 'America/New_York', 'UTC')" unless attrs.schedule_timezone.match?(/\A[A-Za-z0-9_\/+-]+\z/)
          end

          def self.validate_description!(attrs)
            raise Dry::Struct::Error, 'Description cannot exceed 128 characters' if attrs.description && attrs.description.length > 128
          end

          def is_enabled? = enabled
          def is_disabled? = !enabled
          def uses_cron_schedule? = schedule.start_with?('cron(')
          def uses_rate_schedule? = schedule.start_with?('rate(')
          def has_start_date? = !start_date.nil?
          def has_end_date? = !end_date.nil?
          def has_timezone? = !schedule_timezone.nil?
          def has_schedule_offset? = !schedule_offset.nil?
          def has_description? = !description.nil?
          def allows_unassociated_targets? = allow_unassociated_targets
          def duration_hours = duration
          def cutoff_hours = cutoff
          def effective_execution_time_hours = duration - cutoff

          def schedule_type
            return 'cron' if uses_cron_schedule?
            return 'rate' if uses_rate_schedule?

            'unknown'
          end

          def parsed_schedule_info
            if uses_cron_schedule?
              parse_cron_schedule
            elsif uses_rate_schedule?
              parse_rate_schedule
            else
              {}
            end
          end

          def estimated_monthly_executions
            schedule_info = parsed_schedule_info
            return 'Unknown' if schedule_info.empty?

            if uses_rate_schedule?
              estimate_rate_executions(schedule_info)
            elsif uses_cron_schedule?
              estimate_cron_executions(schedule_info)
            else
              'Unknown'
            end
          end

          private

          def parse_cron_schedule
            match = schedule.match(/\Acron\(\s*([^)]+)\s*\)\z/)
            return {} unless match

            fields = match[1].split(/\s+/)
            return {} unless fields.length == 6

            { minute: fields[0], hour: fields[1], day_of_month: fields[2], month: fields[3], day_of_week: fields[4], year: fields[5] }
          end

          def parse_rate_schedule
            match = schedule.match(/\Arate\(\s*(\d+)\s+(minute|minutes|hour|hours|day|days)\s*\)\z/i)
            return {} unless match

            { value: match[1].to_i, unit: match[2].downcase.sub(/s$/, '') }
          end

          def estimate_rate_executions(schedule_info)
            case schedule_info[:unit]
            when 'minute' then (30 * 24 * 60) / schedule_info[:value]
            when 'hour' then (30 * 24) / schedule_info[:value]
            when 'day' then 30 / schedule_info[:value]
            else 'Unknown'
            end
          end

          def estimate_cron_executions(cron)
            return 4 if cron[:day_of_week] != '*' && cron[:day_of_week] != '?'
            return 1 if cron[:day_of_month] != '*' && cron[:day_of_month] != '?'
            return 30 if cron[:hour] != '*'

            'Variable'
          end
        end
      end
    end
  end
end
