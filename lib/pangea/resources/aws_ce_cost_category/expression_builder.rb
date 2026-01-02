# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

module Pangea
  module Resources
    module AWS
      # Builds cost category expressions recursively for Terraform synthesis
      module CostCategoryExpressionBuilder
        module_function

        # Build cost category expression recursively
        # @param expression [Hash] The expression configuration
        # @param builder [Object] The Terraform DSL builder context
        def build(expression, builder)
          build_logical_operators(expression, builder)
          build_filter_types(expression, builder)
        end

        # Handle logical operators (and, or, not)
        def build_logical_operators(expression, builder)
          if expression[:and]
            builder.and do
              expression[:and].each_with_index do |sub_expr, index|
                builder.public_send(index) do
                  CostCategoryExpressionBuilder.build(sub_expr, self)
                end
              end
            end
          elsif expression[:or]
            builder.or do
              expression[:or].each_with_index do |sub_expr, index|
                builder.public_send(index) do
                  CostCategoryExpressionBuilder.build(sub_expr, self)
                end
              end
            end
          elsif expression[:not]
            builder.not do
              CostCategoryExpressionBuilder.build(expression[:not], self)
            end
          end
        end

        # Handle filter types (dimension, tags, cost_category)
        def build_filter_types(expression, builder)
          build_dimension_filter(expression, builder)
          build_tags_filter(expression, builder)
          build_cost_category_filter(expression, builder)
        end

        def build_dimension_filter(expression, builder)
          return unless expression[:dimension]

          builder.dimension do
            key expression[:dimension][:key]
            values expression[:dimension][:values]
            match_options expression[:dimension][:match_options] if expression[:dimension][:match_options]
          end
        end

        def build_tags_filter(expression, builder)
          return unless expression[:tags]

          builder.tags do
            key expression[:tags][:key]
            values expression[:tags][:values] if expression[:tags][:values]
            match_options expression[:tags][:match_options] if expression[:tags][:match_options]
          end
        end

        def build_cost_category_filter(expression, builder)
          return unless expression[:cost_category]

          builder.cost_category do
            key expression[:cost_category][:key]
            values expression[:cost_category][:values]
            match_options expression[:cost_category][:match_options] if expression[:cost_category][:match_options]
          end
        end
      end
    end
  end
end
