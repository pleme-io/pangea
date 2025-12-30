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

require 'json'

module Pangea
  module Resources
    module AWS
      module Types
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
