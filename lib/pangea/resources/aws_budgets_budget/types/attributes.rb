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
require_relative 'enums'
require_relative 'schemas'
require_relative 'helpers'

module Pangea
  module Resources
    module AWS
      module Types
        # Budget resource attributes with comprehensive validation
        class BudgetAttributes < Dry::Struct
          include BudgetHelpers

          transform_keys(&:to_sym)

          attribute :budget_name, String.constrained(format: /\A[a-zA-Z0-9_\-. ]{1,100}\z/).constructor { |value|
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
        end
      end
    end
  end
end
