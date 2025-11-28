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

module Pangea
  module Resources
    module Cloudflare
      module Types
        # Cron expression validator
        CloudflareCronExpression = Dry::Types['strict.string'].constructor do |value|
          # Basic validation for cron expression format (5 or 6 fields)
          parts = value.strip.split(/\s+/)
          unless [5, 6].include?(parts.length)
            raise Dry::Types::ConstraintError, "Cron expression must have 5 or 6 fields"
          end
          value
        end

        # Type-safe attributes for Cloudflare Workers Cron Trigger
        #
        # Schedules Workers to run on a cron schedule. Perfect for periodic
        # tasks, maintenance jobs, and scheduled data processing.
        #
        # @example Create a cron trigger
        #   WorkersCronTriggerAttributes.new(
        #     account_id: "a" * 32,
        #     script_name: "cleanup-worker",
        #     schedules: ["0 2 * * *"]  # Run at 2 AM daily
        #   )
        class WorkersCronTriggerAttributes < Dry::Struct
          transform_keys(&:to_sym)

          # @!attribute account_id
          #   @return [String] The Cloudflare account ID
          attribute :account_id, ::Pangea::Resources::Types::CloudflareAccountId

          # @!attribute script_name
          #   @return [String] Name of the Worker script to trigger
          attribute :script_name, Dry::Types['strict.string'].constrained(
            min_size: 1,
            max_size: 256
          )

          # @!attribute schedules
          #   @return [Array<String>] Array of cron expressions
          attribute :schedules, Dry::Types['strict.array'].of(CloudflareCronExpression).constrained(
            min_size: 1
          )

          # Check if schedule runs frequently (more than once per hour)
          # @return [Boolean] true if any schedule runs more than once per hour
          def frequent_schedule?
            schedules.any? { |s| s.match?(/\*\/[1-5]?\d\s/) }
          end

          # Get human-readable description of first schedule
          # @return [String] Description of schedule
          def schedule_description
            first_schedule = schedules.first
            case first_schedule
            when /^\* \* \* \* \*$/
              "Every minute"
            when /^\*\/5 \* \* \* \*$/
              "Every 5 minutes"
            when /^\*\/30 \* \* \* \*$/
              "Every 30 minutes"
            when /^0 \* \* \* \*$/
              "Every hour"
            when /^0 0 \* \* \*$/
              "Daily at midnight"
            when /^0 2 \* \* \*$/
              "Daily at 2 AM"
            else
              "Custom schedule"
            end
          end

          # Count total schedules configured
          # @return [Integer] Number of schedules
          def schedule_count
            schedules.length
          end
        end
      end
    end
  end
end
