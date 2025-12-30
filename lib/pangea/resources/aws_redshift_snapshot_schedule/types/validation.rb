# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

module Pangea
  module Resources
    module AWS
      module Types
        module RedshiftSnapshotScheduleValidation
          # Validate schedule definition format
          def valid_schedule_definition?(definition)
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
          def parse_rate_to_hours(rate_expr)
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

          def validate_identifier(attrs)
            unless attrs.identifier =~ /\A[a-zA-Z][a-zA-Z0-9\-_]*\z/
              raise Dry::Struct::Error, "Schedule identifier must start with letter and contain only alphanumeric, hyphens, and underscores"
            end

            if attrs.identifier.length > 255
              raise Dry::Struct::Error, "Schedule identifier must be 255 characters or less"
            end
          end

          def validate_definitions(attrs)
            attrs.definitions.each do |definition|
              unless valid_schedule_definition?(definition)
                raise Dry::Struct::Error, "Invalid schedule definition: #{definition}. Must be rate() or cron() expression"
              end
            end

            if attrs.definitions.length > 50
              raise Dry::Struct::Error, "Maximum 50 schedule definitions allowed"
            end
          end
        end
      end
    end
  end
end
