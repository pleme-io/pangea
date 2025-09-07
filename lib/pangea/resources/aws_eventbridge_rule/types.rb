# frozen_string_literal: true

require 'dry-struct'
require 'pangea/resources/types'
require 'json'

module Pangea
  module Resources
    module AWS
      module Types
        # Event pattern validation for EventBridge rules
        EventPattern = Pangea::Resources::Types::String.constructor { |value|
          # Validate that it's valid JSON
          begin
            parsed = JSON.parse(value)
            
            # Basic EventBridge pattern validation
            unless parsed.is_a?(Hash)
              raise Dry::Types::ConstraintError, "Event pattern must be a JSON object"
            end
            
            # Check for required EventBridge pattern structure
            allowed_keys = %w[source detail-type detail account time region version id resources]
            invalid_keys = parsed.keys - allowed_keys
            unless invalid_keys.empty?
              raise Dry::Types::ConstraintError, "Invalid event pattern keys: #{invalid_keys.join(', ')}"
            end
            
            value
          rescue JSON::ParserError => e
            raise Dry::Types::ConstraintError, "Event pattern must be valid JSON: #{e.message}"
          end
        }

        # Schedule expression validation for EventBridge rules
        ScheduleExpression = Pangea::Resources::Types::String.constructor { |value|
          # Validate rate() and cron() expressions
          if value.match?(/\Arate\(/)
            # Validate rate expression: rate(value unit)
            unless value.match?(/\Arate\((\d+)\s+(minute|minutes|hour|hours|day|days)\)\z/)
              raise Dry::Types::ConstraintError, "Invalid rate expression. Format: rate(value unit)"
            end
            
            # Extract the number and validate minimum values
            match = value.match(/\Arate\((\d+)\s+(minute|minutes|hour|hours|day|days)\)\z/)
            number = match[1].to_i
            unit = match[2]
            
            case unit
            when 'minute', 'minutes'
              if number < 1
                raise Dry::Types::ConstraintError, "Rate expression minimum is 1 minute"
              end
            when 'hour', 'hours'
              if number < 1
                raise Dry::Types::ConstraintError, "Rate expression minimum is 1 hour"
              end
            when 'day', 'days'
              if number < 1
                raise Dry::Types::ConstraintError, "Rate expression minimum is 1 day"
              end
            end
            
          elsif value.match?(/\Acron\(/)
            # Validate cron expression: cron(min hour dom month dow year)
            unless value.match?(/\Acron\([^)]+\)\z/)
              raise Dry::Types::ConstraintError, "Invalid cron expression format"
            end
            
            # Extract cron fields and basic validation
            cron_match = value.match(/\Acron\(([^)]+)\)\z/)
            cron_fields = cron_match[1].split(/\s+/)
            
            unless cron_fields.length == 6
              raise Dry::Types::ConstraintError, "Cron expression must have 6 fields: minute hour day month day-of-week year"
            end
            
          else
            raise Dry::Types::ConstraintError, "Schedule expression must start with 'rate(' or 'cron('"
          end
          
          value
        }

        # Type-safe attributes for AWS EventBridge Rule resources
        class EventbridgeRuleAttributes < Dry::Struct
          transform_keys(&:to_sym)
          
          # Rule name (required)
          attribute :name, Pangea::Resources::Types::String.constrained(format: /\A[a-zA-Z0-9._\-]{1,64}\z/)

          # Rule description
          attribute? :description, Pangea::Resources::Types::String.optional.constrained(max_size: 512)

          # Event bus name (defaults to "default")
          attribute :event_bus_name, Pangea::Resources::Types::String.default("default")

          # Rule state
          attribute :state, Pangea::Resources::Types::String.default("ENABLED").constrained(included_in: ["ENABLED", "DISABLED"])

          # Event pattern (JSON) - mutually exclusive with schedule_expression
          attribute? :event_pattern, EventPattern.optional

          # Schedule expression - mutually exclusive with event_pattern
          attribute? :schedule_expression, ScheduleExpression.optional

          # Role ARN for rules that need to invoke targets
          attribute? :role_arn, Pangea::Resources::Types::String.optional.constrained(format: /\Aarn:aws:iam::/)

          # Tagging support
          attribute :tags, Pangea::Resources::Types::AwsTags.default({})

          # Custom validation
          def self.new(attributes = {})
            attrs = super(attributes)
            
            # Validate mutually exclusive pattern/schedule
            if attrs.event_pattern && attrs.schedule_expression
              raise Dry::Struct::Error, "Cannot specify both event_pattern and schedule_expression"
            end
            
            if !attrs.event_pattern && !attrs.schedule_expression
              raise Dry::Struct::Error, "Must specify either event_pattern or schedule_expression"
            end

            # Validate role ARN format if provided
            if attrs.role_arn && !attrs.role_arn.match?(/\Aarn:aws:iam::\d{12}:role\//)
              raise Dry::Struct::Error, "Invalid IAM role ARN format"
            end

            attrs
          end

          # Helper methods
          def is_enabled?
            state == "ENABLED"
          end

          def is_disabled?
            state == "DISABLED"
          end

          def is_scheduled?
            !schedule_expression.nil?
          end

          def is_event_driven?
            !event_pattern.nil?
          end

          def rule_type
            return "scheduled" if is_scheduled?
            return "event_pattern" if is_event_driven?
            "unknown"
          end

          def uses_default_bus?
            event_bus_name == "default"
          end

          def uses_custom_bus?
            !uses_default_bus?
          end

          def has_role?
            !role_arn.nil?
          end

          def parsed_event_pattern
            return nil unless event_pattern
            JSON.parse(event_pattern)
          rescue JSON::ParserError
            nil
          end

          def schedule_frequency
            return nil unless schedule_expression
            
            if schedule_expression.start_with?("rate(")
              match = schedule_expression.match(/\Arate\((\d+)\s+(minute|minutes|hour|hours|day|days)\)\z/)
              return "Every #{match[1]} #{match[2]}" if match
            elsif schedule_expression.start_with?("cron(")
              return "Custom cron schedule"
            end
            
            "Unknown schedule"
          end

          def estimated_monthly_cost
            # EventBridge rules pricing
            base_cost = 1.00  # $1 per million requests
            
            if is_scheduled?
              case schedule_frequency
              when /minute/
                "~$5-15/month (high frequency)"
              when /hour/
                "~$1-5/month (hourly)"
              when /day/
                "~$0.10-1/month (daily)"
              else
                "~$1-10/month"
              end
            else
              "Variable based on event volume"
            end
          end
        end

        # Common EventBridge Rule configurations
        module EventBridgeRuleConfigs
          # Simple scheduled rule (cron-based)
          def self.scheduled_rule(name, schedule_expression:, description: nil)
            {
              name: name,
              schedule_expression: schedule_expression,
              description: description,
              state: "ENABLED"
            }.compact
          end

          # Event-driven rule matching specific source
          def self.event_pattern_rule(name, source:, detail_type: nil, description: nil)
            pattern = { source: [source] }
            pattern[:"detail-type"] = [detail_type] if detail_type
            
            {
              name: name,
              event_pattern: JSON.generate(pattern),
              description: description,
              state: "ENABLED"
            }.compact
          end

          # Custom bus rule
          def self.custom_bus_rule(name, event_bus_name:, event_pattern:, description: nil)
            {
              name: name,
              event_bus_name: event_bus_name,
              event_pattern: event_pattern,
              description: description,
              state: "ENABLED"
            }.compact
          end

          # High-frequency scheduled rule
          def self.frequent_schedule_rule(name, minutes: 5, description: "High frequency scheduled rule")
            {
              name: name,
              schedule_expression: "rate(#{minutes} minute#{minutes == 1 ? '' : 's'})",
              description: description,
              state: "ENABLED"
            }
          end

          # Daily batch processing rule
          def self.daily_batch_rule(name, hour: 2, minute: 0, description: "Daily batch processing")
            {
              name: name,
              schedule_expression: "cron(#{minute} #{hour} * * ? *)",
              description: description,
              state: "ENABLED"
            }
          end

          # AWS service integration rule
          def self.aws_service_rule(name, service:, detail_type:, description: nil)
            pattern = {
              source: ["aws.#{service}"],
              "detail-type": [detail_type]
            }
            
            {
              name: name,
              event_pattern: JSON.generate(pattern),
              description: description || "AWS #{service} integration rule",
              state: "ENABLED"
            }
          end

          # Multi-source event rule
          def self.multi_source_rule(name, sources:, detail_types: nil, description: nil)
            pattern = { source: sources }
            pattern[:"detail-type"] = detail_types if detail_types
            
            {
              name: name,
              event_pattern: JSON.generate(pattern),
              description: description,
              state: "ENABLED"
            }.compact
          end

          # Disaster recovery rule (cross-region)
          def self.disaster_recovery_rule(name, primary_region:, description: "Disaster recovery rule")
            pattern = {
              source: ["aws.health"],
              "detail-type": ["AWS Health Event"],
              detail: {
                eventTypeCategory: ["issue"],
                affectedEntities: {
                  awsRegion: [primary_region]
                }
              }
            }
            
            {
              name: name,
              event_pattern: JSON.generate(pattern),
              description: description,
              state: "ENABLED"
            }
          end
        end
      end
    end
  end
end