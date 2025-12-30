# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

module Pangea
  module Resources
    module AWS
      module Types
        class SfnStateMachineAttributes
          module Validators
            extend self

            def validate_type(attrs)
              return unless attrs[:type] && !%w[STANDARD EXPRESS].include?(attrs[:type])
              raise Dry::Struct::Error, "State machine type must be 'STANDARD' or 'EXPRESS'"
            end

            def validate_definition(attrs)
              return unless attrs[:definition]
              parsed = JSON.parse(attrs[:definition])
              validate_asl_definition(parsed)
            rescue JSON::ParserError => e
              raise Dry::Struct::Error, "Definition must be valid JSON: #{e.message}"
            end

            def validate_logging(attrs)
              return unless attrs[:logging_configuration]
              validate_logging_configuration(attrs[:logging_configuration])
            end

            def validate_tracing(attrs)
              return unless attrs[:tracing_configuration]
              validate_tracing_configuration(attrs[:tracing_configuration])
            end

            def validate_asl_definition(definition)
              raise "Definition must be a JSON object" unless definition.is_a?(Hash)
              raise "Definition must include 'StartAt' field" unless definition["StartAt"]
              raise "Definition must include 'States' field" unless definition["States"]
              raise "'States' must be an object" unless definition["States"].is_a?(Hash)
              raise "'StartAt' must reference an existing state" unless definition["States"][definition["StartAt"]]
              definition["States"].each { |name, state| validate_state_definition(name, state) }
            end

            def validate_state_definition(state_name, state_def)
              raise "State '#{state_name}' must be an object" unless state_def.is_a?(Hash)
              raise "State '#{state_name}' must have a 'Type' field" unless state_def["Type"]
              valid_types = %w[Task Pass Fail Succeed Choice Wait Parallel Map]
              type = state_def["Type"]
              raise "Invalid type '#{type}' for '#{state_name}'" unless valid_types.include?(type)
              validate_state_type_requirements(state_name, type, state_def)
            end

            def validate_state_type_requirements(state_name, type, state_def)
              case type
              when "Task"
                raise "Task '#{state_name}' must have 'Resource'" unless state_def["Resource"]
              when "Choice"
                raise "Choice '#{state_name}' must have 'Choices' array" unless state_def["Choices"]&.is_a?(Array)
              when "Wait"
                wait_fields = %w[Seconds SecondsPath Timestamp TimestampPath]
                raise "Wait '#{state_name}' must have timing field" unless wait_fields.any? { |f| state_def[f] }
              when "Parallel"
                raise "Parallel '#{state_name}' must have 'Branches' array" unless state_def["Branches"]&.is_a?(Array)
              end
            end

            def validate_logging_configuration(config)
              raise "Logging configuration must be a hash" unless config.is_a?(Hash)
              if config[:level] && !%w[ALL ERROR FATAL OFF].include?(config[:level])
                raise "Logging level must be one of: ALL, ERROR, FATAL, OFF"
              end
              if config[:destinations] && !config[:destinations].is_a?(Array)
                raise "Logging destinations must be an array"
              end
            end

            def validate_tracing_configuration(config)
              raise "Tracing configuration must be a hash" unless config.is_a?(Hash)
            end
          end
        end
      end
    end
  end
end
