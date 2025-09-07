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


require 'dry-struct'
require 'pangea/resources/types'
require 'json'

module Pangea
  module Resources
    module AWS
      module Types
        # AWS Step Functions State Machine attributes with validation
        class SfnStateMachineAttributes < Dry::Struct
          transform_keys(&:to_sym)
          
          # Core attributes
          attribute :name, Resources::Types::String
          attribute :definition, Resources::Types::String
          attribute :role_arn, Resources::Types::String
          
          # Optional attributes
          attribute :type, Resources::Types::String.optional.default("STANDARD")
          attribute? :logging_configuration, Resources::Types::Hash.optional
          attribute? :tracing_configuration, Resources::Types::Hash.optional
          attribute? :tags, Resources::Types::Hash.optional
          
          # Custom validation
          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}
            
            # Validate state machine type
            if attrs[:type] && !%w[STANDARD EXPRESS].include?(attrs[:type])
              raise Dry::Struct::Error, "State machine type must be 'STANDARD' or 'EXPRESS'"
            end
            
            # Validate definition is valid JSON (Amazon States Language)
            if attrs[:definition]
              begin
                parsed_definition = JSON.parse(attrs[:definition])
                
                # Validate ASL structure
                validate_asl_definition(parsed_definition)
              rescue JSON::ParserError => e
                raise Dry::Struct::Error, "Definition must be valid JSON: #{e.message}"
              rescue StandardError => e
                raise Dry::Struct::Error, "Invalid Amazon States Language definition: #{e.message}"
              end
            end
            
            # Validate logging configuration
            if attrs[:logging_configuration]
              validate_logging_configuration(attrs[:logging_configuration])
            end
            
            # Validate tracing configuration
            if attrs[:tracing_configuration]
              validate_tracing_configuration(attrs[:tracing_configuration])
            end
            
            super(attrs)
          end
          
          # Amazon States Language (ASL) validation
          def self.validate_asl_definition(definition)
            unless definition.is_a?(Hash)
              raise "Definition must be a JSON object"
            end
            
            # Required fields
            unless definition["StartAt"]
              raise "Definition must include 'StartAt' field"
            end
            
            unless definition["States"]
              raise "Definition must include 'States' field"
            end
            
            unless definition["States"].is_a?(Hash)
              raise "'States' must be an object"
            end
            
            # Validate StartAt references existing state
            start_state = definition["StartAt"]
            unless definition["States"][start_state]
              raise "'StartAt' must reference an existing state: #{start_state}"
            end
            
            # Validate each state
            definition["States"].each do |state_name, state_def|
              validate_state_definition(state_name, state_def)
            end
            
            true
          end
          
          def self.validate_state_definition(state_name, state_def)
            unless state_def.is_a?(Hash)
              raise "State '#{state_name}' must be an object"
            end
            
            unless state_def["Type"]
              raise "State '#{state_name}' must have a 'Type' field"
            end
            
            state_type = state_def["Type"]
            valid_types = %w[Task Pass Fail Succeed Choice Wait Parallel Map]
            
            unless valid_types.include?(state_type)
              raise "State '#{state_name}' has invalid type '#{state_type}'. Valid types: #{valid_types.join(', ')}"
            end
            
            # Type-specific validation
            case state_type
            when "Task"
              unless state_def["Resource"]
                raise "Task state '#{state_name}' must have a 'Resource' field"
              end
            when "Choice"
              unless state_def["Choices"] && state_def["Choices"].is_a?(Array)
                raise "Choice state '#{state_name}' must have a 'Choices' array"
              end
            when "Wait"
              wait_fields = %w[Seconds SecondsPath Timestamp TimestampPath]
              unless wait_fields.any? { |field| state_def[field] }
                raise "Wait state '#{state_name}' must have one of: #{wait_fields.join(', ')}"
              end
            when "Parallel"
              unless state_def["Branches"] && state_def["Branches"].is_a?(Array)
                raise "Parallel state '#{state_name}' must have a 'Branches' array"
              end
            end
            
            true
          end
          
          def self.validate_logging_configuration(config)
            unless config.is_a?(Hash)
              raise "Logging configuration must be a hash"
            end
            
            if config[:level] && !%w[ALL ERROR FATAL OFF].include?(config[:level])
              raise "Logging level must be one of: ALL, ERROR, FATAL, OFF"
            end
            
            if config[:include_execution_data] && ![true, false].include?(config[:include_execution_data])
              raise "include_execution_data must be boolean"
            end
            
            if config[:destinations] && !config[:destinations].is_a?(Array)
              raise "Logging destinations must be an array"
            end
            
            true
          end
          
          def self.validate_tracing_configuration(config)
            unless config.is_a?(Hash)
              raise "Tracing configuration must be a hash"
            end
            
            if config[:enabled] && ![true, false].include?(config[:enabled])
              raise "Tracing enabled must be boolean"
            end
            
            true
          end
          
          # Computed properties
          def is_express_type?
            type == "EXPRESS"
          end
          
          def is_standard_type?
            type == "STANDARD"
          end
          
          def has_logging?
            !logging_configuration.nil? && logging_configuration[:level] != "OFF"
          end
          
          def has_tracing?
            !tracing_configuration.nil? && tracing_configuration[:enabled] == true
          end
          
          def parsed_definition
            @parsed_definition ||= JSON.parse(definition)
          end
          
          def start_state
            parsed_definition["StartAt"]
          end
          
          def states
            parsed_definition["States"] || {}
          end
          
          def state_count
            states.size
          end
          
          # Common state machine patterns
          def self.simple_task_definition(task_arn, next_state = nil)
            definition = {
              "Comment" => "Simple task state machine",
              "StartAt" => "Task",
              "States" => {
                "Task" => {
                  "Type" => "Task",
                  "Resource" => task_arn
                }
              }
            }
            
            if next_state
              definition["States"]["Task"]["Next"] = next_state
            else
              definition["States"]["Task"]["End"] = true
            end
            
            JSON.pretty_generate(definition)
          end
          
          def self.sequential_tasks_definition(tasks)
            states = {}
            
            tasks.each_with_index do |(name, resource), index|
              state = {
                "Type" => "Task",
                "Resource" => resource
              }
              
              if index < tasks.size - 1
                state["Next"] = tasks[index + 1][0]
              else
                state["End"] = true
              end
              
              states[name] = state
            end
            
            definition = {
              "Comment" => "Sequential tasks state machine",
              "StartAt" => tasks.first[0],
              "States" => states
            }
            
            JSON.pretty_generate(definition)
          end
          
          def self.parallel_tasks_definition(branches)
            parallel_branches = branches.map do |branch_name, tasks|
              {
                "StartAt" => tasks.first[0],
                "States" => tasks.each_with_object({}) do |(name, resource), branch_states|
                  branch_states[name] = {
                    "Type" => "Task",
                    "Resource" => resource,
                    "End" => true
                  }
                end
              }
            end
            
            definition = {
              "Comment" => "Parallel tasks state machine",
              "StartAt" => "Parallel",
              "States" => {
                "Parallel" => {
                  "Type" => "Parallel",
                  "Branches" => parallel_branches,
                  "End" => true
                }
              }
            }
            
            JSON.pretty_generate(definition)
          end
          
          def self.choice_definition(choices, default_state)
            choice_rules = choices.map do |condition, next_state|
              {
                "Variable" => condition[:variable],
                condition[:operator] => condition[:value],
                "Next" => next_state
              }
            end
            
            definition = {
              "Comment" => "Choice state machine",
              "StartAt" => "Choice",
              "States" => {
                "Choice" => {
                  "Type" => "Choice",
                  "Choices" => choice_rules,
                  "Default" => default_state
                }
              }
            }
            
            JSON.pretty_generate(definition)
          end
          
          # Logging configuration helpers
          def self.cloudwatch_logging(log_group_arn, level = "ERROR", include_execution_data = false)
            {
              level: level,
              include_execution_data: include_execution_data,
              destinations: [
                {
                  cloud_watch_logs_log_group: {
                    log_group_arn: log_group_arn
                  }
                }
              ]
            }
          end
          
          # Tracing configuration helpers
          def self.enable_xray_tracing
            {
              enabled: true
            }
          end
          
          def self.disable_tracing
            {
              enabled: false
            }
          end
        end
      end
    end
  end
end