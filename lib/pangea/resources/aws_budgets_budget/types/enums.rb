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
        # Budget time unit types
        BudgetTimeUnit = String.enum('DAILY', 'MONTHLY', 'QUARTERLY', 'ANNUALLY')

        # Budget type enumeration
        BudgetType = String.enum(
          'USAGE', 'COST', 'RI_UTILIZATION', 'RI_COVERAGE',
          'SAVINGS_PLANS_UTILIZATION', 'SAVINGS_PLANS_COVERAGE'
        )

        # Cost currency types
        BudgetCurrency = String.enum(
          'USD', 'EUR', 'GBP', 'JPY', 'CNY', 'CAD', 'AUD', 'BRL', 'INR'
        )

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
      end
    end
  end
end
