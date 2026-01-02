# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

module Pangea
  module Resources
    module AWS
      module Types
        module RedshiftSnapshotScheduleTemplates
          # Common schedule templates
          def template_definitions(template)
            case template.to_s
            when "hourly"
              ["rate(1 hour)"]
            when "daily"
              ["cron(0 2 * * ? *)"] # 2 AM daily
            when "twice_daily"
              ["cron(0 2 * * ? *)", "cron(0 14 * * ? *)"] # 2 AM and 2 PM
            when "business_hours"
              ["cron(0 8 * * MON-FRI *)", "cron(0 18 * * MON-FRI *)"] # 8 AM and 6 PM weekdays
            when "weekly"
              ["cron(0 2 ? * SUN *)"] # 2 AM Sunday
            when "monthly"
              ["cron(0 2 1 * ? *)"] # 2 AM first day of month
            when "continuous"
              ["rate(1 hour)"] # Every hour
            when "compliance"
              ["rate(4 hours)"] # Every 4 hours for compliance
            else
              []
            end
          end

          # Generate schedule for retention policy
          def schedule_for_retention(retention_days)
            case retention_days
            when 1..3
              { definitions: ["rate(4 hours)"], description: "High frequency for short retention" }
            when 4..7
              { definitions: ["rate(6 hours)"], description: "4 snapshots daily for weekly retention" }
            when 8..30
              { definitions: ["rate(12 hours)"], description: "Twice daily for monthly retention" }
            when 31..90
              { definitions: ["cron(0 2 * * ? *)"], description: "Daily for quarterly retention" }
            else
              { definitions: ["cron(0 2 ? * SUN *)"], description: "Weekly for long-term retention" }
            end
          end
        end
      end
    end
  end
end
