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
    module AWS
      module Types
        # Budget time unit types
        BudgetTimeUnit = String.enum('DAILY', 'MONTHLY', 'QUARTERLY', 'ANNUALLY')
        
        # Budget type enumeration
        BudgetType = String.enum('USAGE', 'COST', 'RI_UTILIZATION', 'RI_COVERAGE', 'SAVINGS_PLANS_UTILIZATION', 'SAVINGS_PLANS_COVERAGE')
        
        # Cost currency types
        BudgetCurrency = String.enum('USD', 'EUR', 'GBP', 'JPY', 'CNY', 'CAD', 'AUD', 'BRL', 'INR')
        
        # Budget comparison operator
        BudgetComparisonOperator = String.enum('GREATER_THAN', 'LESS_THAN', 'EQUAL_TO')
        
        # Threshold type for budget notifications
        BudgetThresholdType = String.enum('PERCENTAGE', 'ABSOLUTE_VALUE')
        
        # Budget notification type
        BudgetNotificationType = String.enum('ACTUAL', 'FORECASTED')
        
        # Budget subscriber protocol
        BudgetSubscriberProtocol = String.enum('EMAIL', 'SNS')
        
        # Cost dimension key types for budget filters
        CostDimensionKey = String.enum(
          'AZ', 'INSTANCE_TYPE', 'LINKED_ACCOUNT', 'OPERATION', 'PURCHASE_TYPE', 
          'REGION', 'SERVICE', 'USAGE_TYPE', 'USAGE_TYPE_GROUP', 'RECORD_TYPE', 
          'OPERATING_SYSTEM', 'TENANCY', 'SCOPE', 'PLATFORM', 'SUBSCRIPTION_ID',
          'LEGAL_ENTITY_NAME', 'DEPLOYMENT_OPTION', 'DATABASE_ENGINE',
          'CACHE_ENGINE', 'INSTANCE_TYPE_FAMILY', 'BILLING_ENTITY', 'RESERVATION_ID',
          'RESOURCE_ID', 'RIGHTSIZING_TYPE', 'SAVINGS_PLANS_TYPE', 'SAVINGS_PLAN_ARN',
          'PAYMENT_OPTION', 'AGREEMENT_END_DATE_TIME_AFTER', 'AGREEMENT_END_DATE_TIME_BEFORE'
        )
        
        # Budget spend definition
        BudgetSpend = Hash.schema(
          amount: String.constrained(format: /\A\d+(\.\d{1,2})?\z/).constructor { |value|
            amount_float = value.to_f
            if amount_float <= 0
              raise Dry::Types::ConstraintError, "Budget amount must be positive"
            end
            if amount_float > 1000000000 # 1 billion limit
              raise Dry::Types::ConstraintError, "Budget amount cannot exceed 1 billion"
            end
            value
          },
          unit: BudgetCurrency
        )
        
        # Time period for budget
        BudgetTimePeriod = Hash.schema(
          start?: String.constrained(format: /\A\d{4}-\d{2}-\d{2}\z/).optional,
          end?: String.constrained(format: /\A\d{4}-\d{2}-\d{2}\z/).optional
        ).constructor { |value|
          if value[:start] && value[:end]
            start_date = Date.parse(value[:start])
            end_date = Date.parse(value[:end])
            
            if end_date <= start_date
              raise Dry::Types::ConstraintError, "Budget end date must be after start date"
            end
            
            # AWS requires at least 3 months difference for quarterly and annual budgets
            months_diff = (end_date.year - start_date.year) * 12 + end_date.month - start_date.month
            if months_diff < 1
              raise Dry::Types::ConstraintError, "Budget must span at least 1 month"
            end
          end
          
          value
        rescue Date::Error
          raise Dry::Types::ConstraintError, "Budget time period dates must be in YYYY-MM-DD format"
        end
        
        # Cost filter for budget
        BudgetCostFilter = Hash.schema(
          dimension_key: CostDimensionKey,
          values: Array.of(String).constrained(min_size: 1, max_size: 1000),
          match_options?: Array.of(String.enum('EQUALS', 'ABSENT', 'STARTS_WITH', 'ENDS_WITH', 'CONTAINS', 'CASE_SENSITIVE', 'CASE_INSENSITIVE')).optional
        )
        
        # Tag filter for budget costs
        BudgetTagFilter = Hash.schema(
          key: String.constrained(min_size: 1, max_size: 128),
          values?: Array.of(String).constrained(max_size: 1000).optional,
          match_options?: Array.of(String.enum('EQUALS', 'ABSENT', 'STARTS_WITH', 'ENDS_WITH', 'CONTAINS', 'CASE_SENSITIVE', 'CASE_INSENSITIVE')).optional
        )
        
        # Cost filters for budget
        BudgetCostFilters = Hash.schema(
          and?: Array.of(
            Hash.schema(
              dimensions?: Hash.map(CostDimensionKey, Array.of(String)).optional,
              tags?: Hash.map(String, Array.of(String)).optional,
              cost_categories?: Hash.map(String, Array.of(String)).optional
            )
          ).optional,
          dimensions?: Hash.map(CostDimensionKey, Array.of(String)).optional,
          tags?: Hash.map(String, Array.of(String)).optional,
          cost_categories?: Hash.map(String, Array.of(String)).optional,
          not?: Hash.schema(
            dimensions?: Hash.map(CostDimensionKey, Array.of(String)).optional,
            tags?: Hash.map(String, Array.of(String)).optional,
            cost_categories?: Hash.map(String, Array.of(String)).optional
          ).optional
        )
        
        # Budget notification subscriber
        BudgetSubscriber = Hash.schema(
          subscription_type: BudgetSubscriberProtocol,
          address: String.constructor { |value, context|
            protocol = context[:subscription_type] rescue nil
            
            case protocol
            when 'EMAIL'
              unless value.match?(/\A[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}\z/)
                raise Dry::Types::ConstraintError, "Email address format is invalid"
              end
            when 'SNS'
              unless value.match?(/\Aarn:aws:sns:[a-z0-9-]+:\d{12}:[a-zA-Z0-9-_]+\z/)
                raise Dry::Types::ConstraintError, "SNS topic ARN format is invalid"
              end
            end
            
            value
          }
        )
        
        # Budget notification configuration
        BudgetNotification = Hash.schema(
          notification_type: BudgetNotificationType,
          comparison_operator: BudgetComparisonOperator,
          threshold: Numeric.constructor { |value|
            if value <= 0
              raise Dry::Types::ConstraintError, "Budget notification threshold must be positive"
            end
            if value > 1000000
              raise Dry::Types::ConstraintError, "Budget notification threshold cannot exceed 1,000,000"
            end
            value
          },
          threshold_type?: BudgetThresholdType.default('PERCENTAGE').optional,
          subscribers?: Array.of(BudgetSubscriber).constrained(max_size: 11).optional
        )
        
        # Planned budget limits for cost budgets
        BudgetPlannedBudgetLimits = Hash.map(
          String.constrained(format: /\A\d{4}-\d{2}-\d{2}\z/), # Date in YYYY-MM-DD format
          BudgetSpend
        ).constructor { |value|
          # Validate that all dates are valid and in chronological order
          dates = value.keys.sort
          dates.each_cons(2) do |prev_date, curr_date|
            prev_parsed = Date.parse(prev_date)
            curr_parsed = Date.parse(curr_date)
            
            if curr_parsed <= prev_parsed
              raise Dry::Types::ConstraintError, "Planned budget limit dates must be in chronological order"
            end
          end
          
          value
        rescue Date::Error
          raise Dry::Types::ConstraintError, "Planned budget limit dates must be in YYYY-MM-DD format"
        end
        
        # Auto-adjust data configuration
        BudgetAutoAdjustData = Hash.schema(
          auto_adjust_type: String.enum('HISTORICAL', 'FORECAST'),
          historical_options?: Hash.schema(
            budget_adjustment_period: Integer.constrained(gteq: 1, lteq: 60),
            lookback_available_periods?: Integer.constrained(gteq: 1, lteq: 60).optional
          ).optional
        ).constructor { |value|
          if value[:auto_adjust_type] == 'HISTORICAL' && !value[:historical_options]
            raise Dry::Types::ConstraintError, "Historical auto-adjust type requires historical_options"
          end
          value
        end
        
        # Budget resource attributes with comprehensive validation
        class BudgetAttributes < Dry::Struct
          transform_keys(&:to_sym)
          
          attribute :budget_name, String.constrained(format: /\A[a-zA-Z0-9_\-. ]{1,100}\z/).constructor { |value|
            # Remove leading/trailing whitespace and validate
            cleaned = value.strip
            if cleaned.empty?
              raise Dry::Struct::Error, "Budget name cannot be empty"
            end
            if cleaned != value
              raise Dry::Struct::Error, "Budget name cannot have leading or trailing whitespace"
            end
            cleaned
          }
          
          attribute :budget_type, BudgetType
          attribute :time_unit, BudgetTimeUnit
          
          # Main budget limit
          attribute :limit_amount, String.constrained(format: /\A\d+(\.\d{1,2})?\z/).constructor { |value|
            amount_float = value.to_f
            if amount_float <= 0
              raise Dry::Struct::Error, "Budget limit amount must be positive"
            end
            value
          }
          
          attribute :limit_unit, BudgetCurrency
          
          # Optional attributes
          attribute :time_period?, BudgetTimePeriod.optional
          attribute :cost_filters?, BudgetCostFilters.optional
          attribute :planned_budget_limits?, BudgetPlannedBudgetLimits.optional
          attribute :auto_adjust_data?, BudgetAutoAdjustData.optional
          attribute :notifications?, Array.of(BudgetNotification).constrained(max_size: 5).optional
          attribute :tags?, AwsTags.optional
          
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
            ['RI_UTILIZATION', 'RI_COVERAGE'].include?(budget_type)
          end
          
          def has_savings_plans_tracking?
            ['SAVINGS_PLANS_UTILIZATION', 'SAVINGS_PLANS_COVERAGE'].include?(budget_type)
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