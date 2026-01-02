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
        # Helper methods for S3 bucket notification attributes
        module NotificationHelpers
          # Returns total count of notification destinations
          def total_notification_destinations
            cloudwatch_configuration.size + lambda_function.size + queue.size + (eventbridge ? 1 : 0)
          end

          def has_lambda_notifications?
            lambda_function.any?
          end

          def has_sqs_notifications?
            queue.any?
          end

          def has_sns_notifications?
            cloudwatch_configuration.any?
          end

          def has_eventbridge_enabled?
            eventbridge
          end

          # Returns all unique events configured across all notification types
          def all_configured_events
            events = []
            events.concat(cloudwatch_configuration.flat_map { |config| config[:events] })
            events.concat(lambda_function.flat_map { |config| config[:events] })
            events.concat(queue.flat_map { |config| config[:events] })
            events.uniq
          end

          def uses_wildcard_events?
            all_configured_events.any? { |event| event.include?('*') }
          end

          def monitors_object_creation?
            all_configured_events.any? { |event| event.include?('ObjectCreated') }
          end

          def monitors_object_removal?
            all_configured_events.any? { |event| event.include?('ObjectRemoved') }
          end

          def monitors_object_restore?
            all_configured_events.any? { |event| event.include?('ObjectRestore') }
          end

          def monitors_replication?
            all_configured_events.any? { |event| event.include?('Replication') }
          end
        end
      end
    end
  end
end
