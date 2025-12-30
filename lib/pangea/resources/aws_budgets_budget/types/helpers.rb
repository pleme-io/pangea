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
        # Helper methods for BudgetAttributes
        module BudgetHelpers
          # Computed properties for budget analysis
          def monthly_budget_estimate
            amount = limit_amount.to_f

            case time_unit
            when 'DAILY' then amount * 30
            when 'MONTHLY' then amount
            when 'QUARTERLY' then amount / 3
            when 'ANNUALLY' then amount / 12
            else amount
            end
          end

          def annual_budget_estimate
            amount = limit_amount.to_f

            case time_unit
            when 'DAILY' then amount * 365
            when 'MONTHLY' then amount * 12
            when 'QUARTERLY' then amount * 4
            when 'ANNUALLY' then amount
            else amount
            end
          end

          def has_cost_tracking?
            budget_type == 'COST'
          end

          def has_usage_tracking?
            budget_type == 'USAGE'
          end

          def has_ri_tracking?
            %w[RI_UTILIZATION RI_COVERAGE].include?(budget_type)
          end

          def has_savings_plans_tracking?
            %w[SAVINGS_PLANS_UTILIZATION SAVINGS_PLANS_COVERAGE].include?(budget_type)
          end

          def notification_count
            notifications&.length || 0
          end

          def has_email_notifications?
            return false unless notifications

            notifications.any? { |n| n[:subscribers]&.any? { |s| s[:subscription_type] == 'EMAIL' } }
          end

          def has_sns_notifications?
            return false unless notifications

            notifications.any? { |n| n[:subscribers]&.any? { |s| s[:subscription_type] == 'SNS' } }
          end

          def cost_optimization_score
            score = 0

            # Base points for having a budget
            score += 20

            # Points for notifications
            score += 15 if notification_count > 0
            score += 10 if has_email_notifications?
            score += 10 if has_sns_notifications?

            # Points for cost filtering
            score += 15 if cost_filters

            # Points for planned limits
            score += 10 if planned_budget_limits

            # Points for auto-adjustment
            score += 20 if auto_adjust_data

            # Deduct points for overly broad budgets
            score -= 5 if !cost_filters && budget_type == 'COST'

            [score, 100].min
          end

          # Financial governance assessment
          def governance_compliance_level
            if cost_optimization_score >= 80
              'EXCELLENT'
            elsif cost_optimization_score >= 60
              'GOOD'
            elsif cost_optimization_score >= 40
              'BASIC'
            else
              'POOR'
            end
          end
        end
      end
    end
  end
end
