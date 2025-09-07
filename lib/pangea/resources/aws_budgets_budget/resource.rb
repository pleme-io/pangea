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


require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/aws_budgets_budget/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS Budgets Budget with comprehensive cost management and financial governance
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Budget configuration attributes
      # @return [ResourceReference] Reference object with outputs and financial insights
      def aws_budgets_budget(name, attributes = {})
        # Validate attributes using dry-struct with extensive cost management validation
        budget_attrs = Types::BudgetAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_budgets_budget, name) do
          budget_name budget_attrs.budget_name
          budget_type budget_attrs.budget_type
          time_unit budget_attrs.time_unit
          
          # Budget limits configuration
          limit_amount budget_attrs.limit_amount
          limit_unit budget_attrs.limit_unit
          
          # Time period configuration
          if budget_attrs.time_period
            time_period do
              start budget_attrs.time_period[:start] if budget_attrs.time_period[:start]
              end budget_attrs.time_period[:end] if budget_attrs.time_period[:end]
            end
          end
          
          # Cost filters for granular budget tracking
          if budget_attrs.cost_filters
            cost_filters do
              if budget_attrs.cost_filters[:dimensions]
                budget_attrs.cost_filters[:dimensions].each do |dimension_key, values|
                  dimension do
                    key dimension_key
                    values values
                  end
                end
              end
              
              if budget_attrs.cost_filters[:tags]
                budget_attrs.cost_filters[:tags].each do |tag_key, tag_values|
                  tag do
                    key tag_key
                    values tag_values
                  end
                end
              end
              
              if budget_attrs.cost_filters[:cost_categories]
                budget_attrs.cost_filters[:cost_categories].each do |category_key, category_values|
                  cost_category do
                    key category_key
                    values category_values
                  end
                end
              end
              
              # NOT filters for exclusions
              if budget_attrs.cost_filters[:not]
                not_filter = budget_attrs.cost_filters[:not]
                if not_filter[:dimensions] || not_filter[:tags] || not_filter[:cost_categories]
                  # Terraform syntax for NOT filters
                  # This would need to be structured appropriately for the provider
                end
              end
            end
          end
          
          # Planned budget limits for variable spending patterns
          if budget_attrs.planned_budget_limits
            budget_attrs.planned_budget_limits.each do |period_date, budget_spend|
              planned_budget_limit do
                start_date period_date
                limit_amount budget_spend[:amount]
                limit_unit budget_spend[:unit]
              end
            end
          end
          
          # Auto-adjust configuration for dynamic budgets
          if budget_attrs.auto_adjust_data
            auto_adjust_data do
              auto_adjust_type budget_attrs.auto_adjust_data[:auto_adjust_type]
              
              if budget_attrs.auto_adjust_data[:historical_options]
                historical_options do
                  budget_adjustment_period budget_attrs.auto_adjust_data[:historical_options][:budget_adjustment_period]
                  lookback_available_periods budget_attrs.auto_adjust_data[:historical_options][:lookback_available_periods] if budget_attrs.auto_adjust_data[:historical_options][:lookback_available_periods]
                end
              end
            end
          end
          
          # Budget notifications for proactive cost management
          if budget_attrs.notifications
            budget_attrs.notifications.each_with_index do |notification, index|
              notification_block = "notification_#{index}".to_sym
              
              public_send(notification_block) do
                notification_type notification[:notification_type]
                comparison_operator notification[:comparison_operator]
                threshold notification[:threshold]
                threshold_type notification[:threshold_type] if notification[:threshold_type]
                
                # Subscribers for notifications
                if notification[:subscribers]
                  notification[:subscribers].each_with_index do |subscriber, sub_index|
                    subscriber_block = "subscriber_#{sub_index}".to_sym
                    
                    public_send(subscriber_block) do
                      subscription_type subscriber[:subscription_type]
                      address subscriber[:address]
                    end
                  end
                end
              end
            end
          end
          
          # Apply tags for resource organization and cost allocation
          if budget_attrs.tags&.any?
            tags do
              budget_attrs.tags.each do |key, value|
                public_send(key, value)
              end
            end
          end
        end
        
        # Return resource reference with comprehensive cost management insights
        ResourceReference.new(
          type: 'aws_budgets_budget',
          name: name,
          resource_attributes: budget_attrs.to_h,
          outputs: {
            # Core budget identifiers
            budget_name: "${aws_budgets_budget.#{name}.budget_name}",
            budget_arn: "${aws_budgets_budget.#{name}.arn}",
            
            # Budget configuration
            budget_type: "${aws_budgets_budget.#{name}.budget_type}",
            time_unit: "${aws_budgets_budget.#{name}.time_unit}",
            limit_amount: "${aws_budgets_budget.#{name}.limit_amount}",
            limit_unit: "${aws_budgets_budget.#{name}.limit_unit}",
            
            # Computed financial insights
            monthly_budget_estimate: budget_attrs.monthly_budget_estimate,
            annual_budget_estimate: budget_attrs.annual_budget_estimate,
            cost_optimization_score: budget_attrs.cost_optimization_score,
            governance_compliance_level: budget_attrs.governance_compliance_level,
            
            # Budget capabilities
            has_cost_tracking: budget_attrs.has_cost_tracking?,
            has_usage_tracking: budget_attrs.has_usage_tracking?,
            has_ri_tracking: budget_attrs.has_ri_tracking?,
            has_savings_plans_tracking: budget_attrs.has_savings_plans_tracking?,
            
            # Notification insights
            notification_count: budget_attrs.notification_count,
            has_email_notifications: budget_attrs.has_email_notifications?,
            has_sns_notifications: budget_attrs.has_sns_notifications?,
            
            # Advanced features status
            has_cost_filters: !budget_attrs.cost_filters.nil?,
            has_planned_limits: !budget_attrs.planned_budget_limits.nil?,
            has_auto_adjustment: !budget_attrs.auto_adjust_data.nil?
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)