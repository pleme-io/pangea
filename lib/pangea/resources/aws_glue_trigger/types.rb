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


require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
      # Type-safe attributes for AWS Glue Trigger resources
      class GlueTriggerAttributes < Dry::Struct
        # Trigger name (required)
        attribute :name, Resources::Types::String
        
        # Trigger type (required)
        attribute :type, Resources::Types::String.enum("SCHEDULED", "CONDITIONAL", "ON_DEMAND")
        
        # Trigger description
        attribute :description, Resources::Types::String.optional
        
        # Enable/disable trigger
        attribute :enabled, Resources::Types::Bool.default(true)
        
        # Schedule expression for SCHEDULED triggers
        attribute :schedule, Resources::Types::String.optional
        
        # Start time for scheduled triggers
        attribute :start_on_creation, Resources::Types::Bool.optional
        
        # Workflow name if part of workflow
        attribute :workflow_name, Resources::Types::String.optional
        
        # Actions to execute when trigger fires
        attribute :actions, Resources::Types::Array.of(
          Types::Hash.schema(
            job_name?: Types::String.optional,
            crawler_name?: Types::String.optional,
            arguments?: Types::Hash.map(Types::String, Types::String).optional,
            timeout?: Types::Integer.optional,
            security_configuration?: Types::String.optional,
            notification_property?: Types::Hash.schema(
              notify_delay_after?: Types::Integer.optional
            ).optional
          )
        ).default([].freeze)
        
        # Predicate for CONDITIONAL triggers
        attribute :predicate, Resources::Types::Hash.schema(
          logical?: Types::String.enum("AND", "ANY").optional,
          conditions?: Types::Array.of(
            Types::Hash.schema(
              logical_operator?: Types::String.enum("EQUALS").optional,
              job_name?: Types::String.optional,
              state?: Types::String.enum("SUCCEEDED", "STOPPED", "FAILED", "TIMEOUT").optional,
              crawler_name?: Types::String.optional,
              crawl_state?: Types::String.enum("SUCCEEDED", "CANCELLED", "FAILED").optional
            )
          ).optional
        ).optional
        
        # Event batching configuration
        attribute :event_batching_condition, Resources::Types::Hash.schema(
          batch_size: Types::Integer.constrained(gteq: 1, lteq: 100),
          batch_window?: Types::Integer.constrained(gteq: 900, lteq: 900).optional
        ).optional
        
        # Tags
        attribute :tags, Resources::Types::AwsTags.default({}.freeze)

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)
          
          # Validate trigger name format
          unless attrs.name =~ /\A[a-zA-Z_][a-zA-Z0-9_-]*\z/
            raise Dry::Struct::Error, "Trigger name must start with letter or underscore and contain only alphanumeric characters, underscores, and hyphens"
          end
          
          # Validate trigger name length
          if attrs.name.length > 255
            raise Dry::Struct::Error, "Trigger name must be 255 characters or less"
          end
          
          # Validate schedule for SCHEDULED triggers
          if attrs.type == "SCHEDULED"
            unless attrs.schedule
              raise Dry::Struct::Error, "Schedule expression is required for SCHEDULED triggers"
            end
            
            # Validate schedule format (cron or rate expressions)
            schedule = attrs.schedule
            unless schedule.match(/\A(cron|rate)\(/) || schedule.match(/\Aat\(/)
              raise Dry::Struct::Error, "Schedule must be a valid cron() or rate() expression"
            end
          end
          
          # Validate predicate for CONDITIONAL triggers
          if attrs.type == "CONDITIONAL"
            unless attrs.predicate && attrs.predicate[:conditions]&.any?
              raise Dry::Struct::Error, "Predicate with conditions is required for CONDITIONAL triggers"
            end
          end
          
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

          attrs
        end

        # Check if trigger is scheduled
        def is_scheduled?
          type == "SCHEDULED"
        end

        # Check if trigger is conditional
        def is_conditional?
          type == "CONDITIONAL"
        end

        # Check if trigger is on-demand
        def is_on_demand?
          type == "ON_DEMAND"
        end

        # Check if trigger is part of workflow
        def is_workflow_trigger?
          !workflow_name.nil?
        end

        # Get job actions
        def job_actions
          actions.select { |action| action[:job_name] }
        end

        # Get crawler actions
        def crawler_actions
          actions.select { |action| action[:crawler_name] }
        end

        # Get total action count
        def total_actions
          actions.size
        end

        # Get condition count for conditional triggers
        def condition_count
          return 0 unless is_conditional?
          predicate&.dig(:conditions)&.size || 0
        end

        # Get schedule frequency (for scheduled triggers)
        def schedule_frequency
          return nil unless is_scheduled?
          return nil unless schedule
          
          case schedule
          when /rate\((\d+)\s+(minute|minutes)\)/
            { type: "minutes", value: $1.to_i }
          when /rate\((\d+)\s+(hour|hours)\)/
            { type: "hours", value: $1.to_i }
          when /rate\((\d+)\s+(day|days)\)/
            { type: "days", value: $1.to_i }
          when /cron\(/
            { type: "cron", expression: schedule }
          else
            { type: "unknown", expression: schedule }
          end
        end

        # Estimate trigger execution frequency per day
        def estimated_executions_per_day
          return 0 unless is_scheduled?
          
          freq = schedule_frequency
          return 1 unless freq
          
          case freq[:type]
          when "minutes"
            (24 * 60) / freq[:value]
          when "hours"
            24 / freq[:value]
          when "days"
            1.0 / freq[:value]
          when "cron"
            # Complex cron expressions are hard to calculate
            1
          else
            1
          end
        end

        # Check if trigger configuration is optimal
        def configuration_warnings
          warnings = []
          
          if is_scheduled? && estimated_executions_per_day > 1440
            warnings << "Very frequent scheduling (>1440/day) may impact costs and performance"
          end
          
          if is_conditional? && condition_count > 10
            warnings << "Large number of conditions may impact trigger evaluation performance"
          end
          
          if total_actions > 20
            warnings << "Large number of actions may impact trigger execution time"
          end
          
          if is_scheduled? && !start_on_creation
            warnings << "Consider setting start_on_creation=true for immediate scheduling"
          end
          
          job_actions.each do |action|
            unless action[:timeout]
              warnings << "Consider setting timeout for job actions to prevent long-running jobs"
            end
          end
          
          warnings
        end

        # Generate common schedule expressions
        def self.schedule_expressions
          {
            # Rate expressions
            every_5_minutes: "rate(5 minutes)",
            every_15_minutes: "rate(15 minutes)",
            every_30_minutes: "rate(30 minutes)",
            hourly: "rate(1 hour)",
            every_2_hours: "rate(2 hours)",
            every_6_hours: "rate(6 hours)",
            every_12_hours: "rate(12 hours)",
            daily: "rate(1 day)",
            weekly: "rate(7 days)",
            
            # Cron expressions for common patterns
            daily_at_midnight: "cron(0 0 * * ? *)",
            daily_at_6am: "cron(0 6 * * ? *)",
            daily_at_noon: "cron(0 12 * * ? *)",
            weekdays_at_9am: "cron(0 9 ? * MON-FRI *)",
            weekends_at_10am: "cron(0 10 ? * SAT,SUN *)",
            first_day_of_month: "cron(0 0 1 * ? *)",
            last_day_of_month: "cron(0 0 L * ? *)",
            
            # Business hours patterns
            business_hours_hourly: "cron(0 9-17 ? * MON-FRI *)",
            business_days_morning: "cron(0 9 ? * MON-FRI *)",
            business_days_evening: "cron(0 18 ? * MON-FRI *)"
          }
        end

        # Generate predicate for common conditional patterns
        def self.predicate_for_job_success(job_names)
          job_names = Array(job_names)
          conditions = job_names.map do |job_name|
            {
              logical_operator: "EQUALS",
              job_name: job_name,
              state: "SUCCEEDED"
            }
          end
          
          {
            logical: job_names.size > 1 ? "AND" : "ANY",
            conditions: conditions
          }
        end
        
        def self.predicate_for_crawler_success(crawler_names)
          crawler_names = Array(crawler_names)
          conditions = crawler_names.map do |crawler_name|
            {
              logical_operator: "EQUALS",
              crawler_name: crawler_name,
              crawl_state: "SUCCEEDED"
            }
          end
          
          {
            logical: crawler_names.size > 1 ? "AND" : "ANY",
            conditions: conditions
          }
        end

        # Generate action configurations
        def self.action_for_job(job_name, options = {})
          {
            job_name: job_name,
            arguments: options[:arguments] || {},
            timeout: options[:timeout],
            security_configuration: options[:security_configuration],
            notification_property: options[:notification_property]
          }.compact
        end
        
        def self.action_for_crawler(crawler_name, options = {})
          {
            crawler_name: crawler_name
          }
        end
      end
    end
      end
    end
  end
end