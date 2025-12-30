# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

module Pangea
  module Resources
    module AWS
      module Types
        # Cost category rule types
        CostCategoryRuleType = String.enum('REGULAR', 'INHERITED')

        # Cost category split charge rule methods
        SplitChargeMethod = String.enum('FIXED', 'PROPORTIONAL', 'EVEN')

        # Cost category dimension key types
        CostCategoryDimensionKey = String.enum(
          'AZ', 'INSTANCE_TYPE', 'LINKED_ACCOUNT', 'LINKED_ACCOUNT_NAME', 'OPERATION',
          'PURCHASE_TYPE', 'REGION', 'SERVICE', 'SERVICE_CODE', 'USAGE_TYPE',
          'USAGE_TYPE_GROUP', 'RECORD_TYPE', 'OPERATING_SYSTEM', 'TENANCY',
          'SCOPE', 'PLATFORM', 'SUBSCRIPTION_ID', 'LEGAL_ENTITY_NAME',
          'DEPLOYMENT_OPTION', 'DATABASE_ENGINE', 'CACHE_ENGINE',
          'INSTANCE_TYPE_FAMILY', 'BILLING_ENTITY', 'RESERVATION_ID',
          'RESOURCE_ID', 'RIGHTSIZING_TYPE', 'SAVINGS_PLANS_TYPE',
          'SAVINGS_PLAN_ARN', 'PAYMENT_OPTION'
        )

        # Match options for cost category filters
        CostCategoryMatchOptions = String.enum(
          'EQUALS', 'ABSENT', 'STARTS_WITH', 'ENDS_WITH', 'CONTAINS',
          'CASE_SENSITIVE', 'CASE_INSENSITIVE'
        )

        # Cost category dimension filter
        CostCategoryDimensionFilter = Hash.schema(
          key: CostCategoryDimensionKey,
          values: Array.of(String).constrained(min_size: 1, max_size: 10000),
          match_options?: Array.of(CostCategoryMatchOptions).constrained(max_size: 1).optional
        )

        # Cost category tag filter
        CostCategoryTagFilter = Hash.schema(
          key: String.constrained(min_size: 1, max_size: 128),
          values?: Array.of(String).constrained(max_size: 1000).optional,
          match_options?: Array.of(CostCategoryMatchOptions).constrained(max_size: 1).optional
        )

        # Cost category cost category filter (for nested categories)
        CostCategoryCostCategoryFilter = Hash.schema(
          key: String.constrained(min_size: 1, max_size: 50),
          values: Array.of(String).constrained(min_size: 1, max_size: 20),
          match_options?: Array.of(CostCategoryMatchOptions).constrained(max_size: 1).optional
        )

        # Cost category expression for complex filtering
        CostCategoryExpression = Hash.schema(
          and?: Array.of(Hash).optional,
          or?: Array.of(Hash).optional,
          not?: Hash.optional,
          dimension?: CostCategoryDimensionFilter.optional,
          tags?: CostCategoryTagFilter.optional,
          cost_category?: CostCategoryCostCategoryFilter.optional
        ).constructor { |value|
          expression_types = [:and, :or, :not, :dimension, :tags, :cost_category]
          specified_types = expression_types.select { |type| value.key?(type) && value[type] }

          if specified_types.empty?
            raise Dry::Types::ConstraintError, "Cost category expression must specify at least one condition"
          end

          if value[:and] && value[:and].size < 2
            raise Dry::Types::ConstraintError, "AND expression must have at least 2 conditions"
          end

          if value[:or] && value[:or].size < 2
            raise Dry::Types::ConstraintError, "OR expression must have at least 2 conditions"
          end

          value
        }

        # Cost category rule definition
        CostCategoryRule = Hash.schema(
          value: String.constrained(min_size: 1, max_size: 50).constructor { |value|
            unless value.match?(/\A[a-zA-Z0-9\s\-_\.]+\z/)
              raise Dry::Types::ConstraintError, "Cost category value must contain only alphanumeric characters, spaces, hyphens, underscores, and periods"
            end
            value.strip
          },
          rule: CostCategoryExpression,
          type?: CostCategoryRuleType.default('REGULAR').optional,
          inherited_value?: Hash.schema(
            dimension_key?: CostCategoryDimensionKey.optional,
            dimension_name?: String.optional
          ).optional
        ).constructor { |value|
          if value[:type] == 'INHERITED' && !value[:inherited_value]
            raise Dry::Types::ConstraintError, "INHERITED rule type requires inherited_value configuration"
          end

          if value[:type] == 'REGULAR' && value[:inherited_value]
            raise Dry::Types::ConstraintError, "REGULAR rule type cannot have inherited_value configuration"
          end

          value
        }

        # Cost category split charge rule
        CostCategorySplitChargeRule = Hash.schema(
          source: String.constrained(min_size: 1, max_size: 50),
          targets: Array.of(String.constrained(min_size: 1, max_size: 50)).constrained(min_size: 1, max_size: 500),
          method: SplitChargeMethod,
          parameters?: Array.of(
            Hash.schema(
              type: String.enum('ALLOCATION_PERCENTAGES'),
              values: Array.of(String).constrained(min_size: 1)
            )
          ).constrained(max_size: 10).optional
        ).constructor { |value|
          case value[:method]
          when 'FIXED', 'PROPORTIONAL'
            if value[:parameters].nil? || value[:parameters].empty?
              raise Dry::Types::ConstraintError, "#{value[:method]} split charge method requires parameters"
            end

            if value[:method] == 'FIXED'
              percentages = value[:parameters].first[:values].map(&:to_f)
              total_percentage = percentages.sum

              unless (total_percentage - 100.0).abs < 0.01
                raise Dry::Types::ConstraintError, "FIXED split charge percentages must sum to 100%"
              end

              if percentages.size != value[:targets].size
                raise Dry::Types::ConstraintError, "FIXED split charge must have one percentage per target"
              end
            end

          when 'EVEN'
            if value[:parameters] && !value[:parameters].empty?
              raise Dry::Types::ConstraintError, "EVEN split charge method should not have parameters"
            end
          end

          if value[:targets].include?(value[:source])
            raise Dry::Types::ConstraintError, "Split charge source cannot be in targets list"
          end

          if value[:targets].size != value[:targets].uniq.size
            raise Dry::Types::ConstraintError, "Split charge targets must be unique"
          end

          value
        }
      end
    end
  end
end
