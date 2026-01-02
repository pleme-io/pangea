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
          module HelpersModules
            # Class methods for AWS Glue Trigger attributes
            module ClassMethods
              # Generate common schedule expressions
              def schedule_expressions
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
              def predicate_for_job_success(job_names)
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

              def predicate_for_crawler_success(crawler_names)
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
              def action_for_job(job_name, options = {})
                {
                  job_name: job_name,
                  arguments: options[:arguments] || {},
                  timeout: options[:timeout],
                  security_configuration: options[:security_configuration],
                  notification_property: options[:notification_property]
                }.compact
              end

              def action_for_crawler(crawler_name, _options = {})
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
end
