# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

require_relative 'expressions'

module Pangea
  module Resources
    module AWS
      module Types
        # Cost category resource attributes with comprehensive validation
        class CostCategoryAttributes < Dry::Struct
          transform_keys(&:to_sym)

          attribute :name, String.constrained(format: /\A[a-zA-Z0-9\s\-_\.]{1,50}\z/).constructor { |value|
            cleaned = value.strip
            if cleaned.empty?
              raise Dry::Struct::Error, "Cost category name cannot be empty"
            end

            reserved_names = ['BLENDED_COST', 'UNBLENDED_COST', 'AMORTIZED_COST', 'NET_UNBLENDED_COST', 'NET_AMORTIZED_COST']
            if reserved_names.include?(cleaned.upcase)
              raise Dry::Struct::Error, "Cost category name cannot be a reserved AWS name: #{reserved_names.join(', ')}"
            end

            cleaned
          }

          attribute :rules, Array.of(CostCategoryRule).constrained(min_size: 1, max_size: 500).constructor { |rules|
            values = rules.map { |rule| rule[:value] }
            if values.size != values.uniq.size
              raise Dry::Struct::Error, "Cost category rule values must be unique within the category"
            end

            regular_rules = rules.select { |rule| rule[:type] != 'INHERITED' }
            if regular_rules.empty?
              raise Dry::Struct::Error, "Cost category must have at least one REGULAR rule"
            end

            rules
          }

          attribute :rule_version_arn?, String.constrained(format: /\Aarn:aws:ce::[0-9]{12}:cost-category\/[a-zA-Z0-9\-]+\z/).optional
          attribute :default_value?, String.constrained(min_size: 1, max_size: 50).optional
          attribute :split_charge_rules?, Array.of(CostCategorySplitChargeRule).constrained(max_size: 10).optional
          attribute :effective_start?, String.constrained(format: /\A\d{4}-\d{2}-\d{2}\z/).optional
          attribute :effective_end?, String.constrained(format: /\A\d{4}-\d{2}-\d{2}\z/).optional
          attribute :tags?, AwsTags.optional

          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}

            if attrs[:effective_start] && attrs[:effective_end]
              start_date = Date.parse(attrs[:effective_start])
              end_date = Date.parse(attrs[:effective_end])

              if end_date <= start_date
                raise Dry::Struct::Error, "Effective end date must be after start date"
              end

              if start_date < Date.today - 365
                raise Dry::Struct::Error, "Effective start date cannot be more than 1 year in the past"
              end
            end

            if attrs[:split_charge_rules] && attrs[:rules]
              rule_values = attrs[:rules].map { |rule| rule[:value] }
              default_value = attrs[:default_value]
              all_values = rule_values + (default_value ? [default_value] : [])

              attrs[:split_charge_rules].each do |split_rule|
                unless all_values.include?(split_rule[:source])
                  raise Dry::Struct::Error, "Split charge source '#{split_rule[:source]}' must be a valid cost category value"
                end

                split_rule[:targets].each do |target|
                  unless all_values.include?(target)
                    raise Dry::Struct::Error, "Split charge target '#{target}' must be a valid cost category value"
                  end
                end
              end
            end

            super(attrs)
          rescue Date::Error
            raise Dry::Struct::Error, "Effective dates must be in YYYY-MM-DD format"
          end

          def rule_count = rules.length
          def regular_rule_count = rules.count { |rule| rule[:type] != 'INHERITED' }
          def inherited_rule_count = rules.count { |rule| rule[:type] == 'INHERITED' }
          def has_default_value? = !default_value.nil?
          def has_split_charge_rules? = split_charge_rules && !split_charge_rules.empty?
          def split_charge_rule_count = split_charge_rules&.length || 0
          def has_effective_dates? = effective_start || effective_end
          def is_time_limited? = effective_end

          def complexity_score
            score = rule_count * 5 + inherited_rule_count * 3 + split_charge_rule_count * 10
            rules.each { |rule| score += expression_complexity(rule[:rule]) }
            [score, 100].min
          end

          def complexity_level
            case complexity_score
            when 0..20 then 'SIMPLE'
            when 21..40 then 'MODERATE'
            when 41..70 then 'COMPLEX'
            else 'VERY_COMPLEX'
            end
          end

          def allocation_coverage_estimate
            coverage = 0
            coverage += 60 if rule_count > 0
            coverage += 20 if has_default_value?
            coverage += [rule_count * 2, 15].min
            coverage += 5 if has_split_charge_rules?
            [coverage, 100].min
          end

          def governance_maturity_level
            if allocation_coverage_estimate >= 90 && has_default_value? && has_split_charge_rules?
              'ADVANCED'
            elsif allocation_coverage_estimate >= 70 && has_default_value?
              'INTERMEDIATE'
            elsif allocation_coverage_estimate >= 50
              'BASIC'
            else
              'MINIMAL'
            end
          end

          private

          def expression_complexity(expression)
            complexity = 0
            complexity += 5 if expression[:and]
            complexity += 5 if expression[:or]
            complexity += 3 if expression[:not]

            expression[:and]&.each { |sub_expr| complexity += expression_complexity(sub_expr) }
            expression[:or]&.each { |sub_expr| complexity += expression_complexity(sub_expr) }
            complexity += expression_complexity(expression[:not]) if expression[:not]

            complexity
          end
        end
      end
    end
  end
end
