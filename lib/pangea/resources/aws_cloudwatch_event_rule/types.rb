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
        # CloudWatch Event Rule resource attributes with validation
        class CloudWatchEventRuleAttributes < Dry::Struct
          transform_keys(&:to_sym)
          
          # Required attributes (at least one of event_pattern or schedule_expression)
          attribute :name, Resources::Types::String.optional.default(nil)
          attribute :name_prefix, Resources::Types::String.optional.default(nil)
          attribute :description, Resources::Types::String.optional.default(nil)
          attribute :event_bus_name, Resources::Types::String.default('default')
          attribute :event_pattern, Resources::Types::String.optional.default(nil)
          attribute :schedule_expression, Resources::Types::String.optional.default(nil)
          attribute :state, Resources::Types::String.default('ENABLED').enum('ENABLED', 'DISABLED')
          attribute :role_arn, Resources::Types::String.optional.default(nil)
          attribute :is_enabled, Resources::Types::Bool.default(true)
          attribute :tags, Resources::Types::AwsTags
          
          # Validate rule configuration
          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}
            
            # Validate name XOR name_prefix
            if attrs[:name] && attrs[:name_prefix]
              raise Dry::Struct::Error, "Cannot specify both name and name_prefix"
            end
            
            unless attrs[:name] || attrs[:name_prefix]
              raise Dry::Struct::Error, "Must specify either name or name_prefix"
            end
            
            # Validate name format if provided
            if attrs[:name] && !attrs[:name].match?(/^[\.\-_A-Za-z0-9]+$/)
              raise Dry::Struct::Error, "name must contain only alphanumeric characters, periods, hyphens, and underscores"
            end
            
            # Validate event_pattern XOR schedule_expression
            if attrs[:event_pattern] && attrs[:schedule_expression]
              raise Dry::Struct::Error, "Cannot specify both event_pattern and schedule_expression"
            end
            
            unless attrs[:event_pattern] || attrs[:schedule_expression]
              raise Dry::Struct::Error, "Must specify either event_pattern or schedule_expression"
            end
            
            # Validate event_pattern JSON if provided
            if attrs[:event_pattern]
              begin
                pattern = JSON.parse(attrs[:event_pattern])
                unless pattern.is_a?(Hash)
                  raise Dry::Struct::Error, "event_pattern must be a valid JSON object"
                end
              rescue JSON::ParserError => e
                raise Dry::Struct::Error, "event_pattern must be valid JSON: #{e.message}"
              end
            end
            
            # Validate schedule_expression format
            if attrs[:schedule_expression]
              expr = attrs[:schedule_expression]
              unless expr.match?(/^rate\(.+\)$/) || expr.match?(/^cron\(.+\)$/)
                raise Dry::Struct::Error, "schedule_expression must be a rate() or cron() expression"
              end
            end
            
            # Validate role_arn format if provided
            if attrs[:role_arn] && !attrs[:role_arn].empty?
              unless attrs[:role_arn].match?(/^arn:aws[a-z\-]*:iam::\d{12}:role\//) ||
                     attrs[:role_arn].match?(/^\$\{/)  # Allow terraform references
                raise Dry::Struct::Error, "role_arn must be a valid IAM role ARN"
              end
            end
            
            # Map is_enabled to state
            if attrs.key?(:is_enabled)
              attrs[:state] = attrs[:is_enabled] ? 'ENABLED' : 'DISABLED'
            end
            
            super(attrs)
          end
          
          # Computed properties
          def rule_type
            if event_pattern
              :event_pattern
            elsif schedule_expression
              :scheduled
            else
              :unknown
            end
          end
          
          def schedule_type
            return nil unless schedule_expression
            
            if schedule_expression.start_with?('rate(')
              :rate
            elsif schedule_expression.start_with?('cron(')
              :cron
            else
              :unknown
            end
          end
          
          def event_sources
            return [] unless event_pattern
            
            begin
              pattern = JSON.parse(event_pattern)
              Array(pattern['source']).compact
            rescue JSON::ParserError
              []
            end
          end
          
          def event_detail_types
            return [] unless event_pattern
            
            begin
              pattern = JSON.parse(event_pattern)
              Array(pattern['detail-type']).compact
            rescue JSON::ParserError
              []
            end
          end
          
          def is_custom_event_bus?
            event_bus_name != 'default'
          end
          
          def requires_role?
            # Role is required for certain built-in targets like ECS tasks
            false  # Most targets handle their own permissions
          end
          
          def to_h
            hash = {
              event_bus_name: event_bus_name,
              state: state,
              tags: tags
            }
            
            # Name configuration
            hash[:name] = name if name
            hash[:name_prefix] = name_prefix if name_prefix
            
            # Optional attributes
            hash[:description] = description if description
            hash[:event_pattern] = event_pattern if event_pattern
            hash[:schedule_expression] = schedule_expression if schedule_expression
            hash[:role_arn] = role_arn if role_arn
            
            hash.compact
          end
        end
      end
    end
  end
end