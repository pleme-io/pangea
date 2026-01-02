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

module Pangea
  module Resources
    module AWS
      module Types
        module GlueTriggerTypes
          # Validation logic for AWS Glue Trigger resources
          module Validation
            def self.included(base)
              base.extend(ClassMethods)
            end

            module ClassMethods
              # Custom validation for trigger attributes
              def new(attributes = {})
                attrs = super(attributes)
                validate_trigger_name(attrs)
                validate_schedule(attrs)
                validate_predicate(attrs)
                validate_actions(attrs)
                attrs
              end

              private

              def validate_trigger_name(attrs)
                # Validate trigger name format
                unless attrs.name =~ /\A[a-zA-Z_][a-zA-Z0-9_-]*\z/
                  raise Dry::Struct::Error, "Trigger name must start with letter or underscore and contain only alphanumeric characters, underscores, and hyphens"
                end

                # Validate trigger name length
                if attrs.name.length > 255
                  raise Dry::Struct::Error, "Trigger name must be 255 characters or less"
                end
              end

              def validate_schedule(attrs)
                return unless attrs.type == "SCHEDULED"

                unless attrs.schedule
                  raise Dry::Struct::Error, "Schedule expression is required for SCHEDULED triggers"
                end

                # Validate schedule format (cron or rate expressions)
                schedule = attrs.schedule
                unless schedule.match(/\A(cron|rate)\(/) || schedule.match(/\Aat\(/)
                  raise Dry::Struct::Error, "Schedule must be a valid cron() or rate() expression"
                end
              end

              def validate_predicate(attrs)
                return unless attrs.type == "CONDITIONAL"

                unless attrs.predicate && attrs.predicate[:conditions]&.any?
                  raise Dry::Struct::Error, "Predicate with conditions is required for CONDITIONAL triggers"
                end
              end

              def validate_actions(attrs)
                # Validate actions are present
                unless attrs.actions.any?
                  raise Dry::Struct::Error, "At least one action must be specified"
                end

                # Validate each action has either job_name or crawler_name
                attrs.actions.each_with_index do |action, index|
                  unless action[:job_name] || action[:crawler_name]
                    raise Dry::Struct::Error, "Action #{index} must specify either job_name or crawler_name"
                  end

                  if action[:job_name] && action[:crawler_name]
                    raise Dry::Struct::Error, "Action #{index} cannot specify both job_name and crawler_name"
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
