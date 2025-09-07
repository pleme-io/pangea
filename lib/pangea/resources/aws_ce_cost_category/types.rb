# frozen_string_literal: true

require 'dry-struct'
require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
        # Cost category rule types
        CostCategoryRuleType = String.enum('REGULAR', 'INHERITED')
        
        # Cost category split charge rule methods
        SplitChargeMethod = String.enum('FIXED', 'PROPORTIONAL', 'EVEN')
        
        # Cost category dimension key types (extended for cost categorization)
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
          # Logical operators
          and?: Array.of(Hash).optional,
          or?: Array.of(Hash).optional,
          not?: Hash.optional,
          
          # Filter types  
          dimension?: CostCategoryDimensionFilter.optional,
          tags?: CostCategoryTagFilter.optional,
          cost_category?: CostCategoryCostCategoryFilter.optional
        ).constructor { |value|
          # Validate that exactly one expression type is specified at each level
          expression_types = [:and, :or, :not, :dimension, :tags, :cost_category]
          specified_types = expression_types.select { |type| value.key?(type) && value[type] }
          
          if specified_types.empty?
            raise Dry::Types::ConstraintError, "Cost category expression must specify at least one condition"
          end
          
          # Validate logical operator usage
          if value[:and] && value[:and].size < 2
            raise Dry::Types::ConstraintError, "AND expression must have at least 2 conditions"
          end
          
          if value[:or] && value[:or].size < 2
            raise Dry::Types::ConstraintError, "OR expression must have at least 2 conditions" 
          end
          
          value
        end
        
        # Cost category rule definition
        CostCategoryRule = Hash.schema(
          value: String.constrained(min_size: 1, max_size: 50).constructor { |value|
            # Cost category values must be unique within the category
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
          # Inherited rules require inherited_value configuration
          if value[:type] == 'INHERITED' && !value[:inherited_value]
            raise Dry::Types::ConstraintError, "INHERITED rule type requires inherited_value configuration"
          end
          
          # Regular rules should not have inherited_value
          if value[:type] == 'REGULAR' && value[:inherited_value]
            raise Dry::Types::ConstraintError, "REGULAR rule type cannot have inherited_value configuration"
          end
          
          value
        end
        
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
          # Validate split charge parameters based on method
          case value[:method]
          when 'FIXED', 'PROPORTIONAL'
            if value[:parameters].nil? || value[:parameters].empty?
              raise Dry::Types::ConstraintError, "#{value[:method]} split charge method requires parameters"
            end
            
            # Validate percentage allocation for FIXED method
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
            # EVEN method should not have parameters
            if value[:parameters] && !value[:parameters].empty?
              raise Dry::Types::ConstraintError, "EVEN split charge method should not have parameters"
            end
          end
          
          # Validate that source is not in targets
          if value[:targets].include?(value[:source])
            raise Dry::Types::ConstraintError, "Split charge source cannot be in targets list"
          end
          
          # Validate targets are unique
          if value[:targets].size != value[:targets].uniq.size
            raise Dry::Types::ConstraintError, "Split charge targets must be unique"
          end
          
          value
        end
        
        # Cost category resource attributes with comprehensive validation
        class CostCategoryAttributes < Dry::Struct
          transform_keys(&:to_sym)
          
          attribute :name, String.constrained(format: /\A[a-zA-Z0-9\s\-_\.]{1,50}\z/).constructor { |value|
            # Cost category names must be unique within an account
            cleaned = value.strip
            if cleaned.empty?
              raise Dry::Struct::Error, "Cost category name cannot be empty"
            end
            
            # Validate name doesn't conflict with AWS reserved names
            reserved_names = ['BLENDED_COST', 'UNBLENDED_COST', 'AMORTIZED_COST', 'NET_UNBLENDED_COST', 'NET_AMORTIZED_COST']
            if reserved_names.include?(cleaned.upcase)
              raise Dry::Struct::Error, "Cost category name cannot be a reserved AWS name: #{reserved_names.join(', ')}"
            end
            
            cleaned
          }
          
          attribute :rules, Array.of(CostCategoryRule).constrained(min_size: 1, max_size: 500).constructor { |rules|
            # Validate rule values are unique within the cost category
            values = rules.map { |rule| rule[:value] }
            if values.size != values.uniq.size
              raise Dry::Struct::Error, "Cost category rule values must be unique within the category"
            end
            
            # Validate at least one regular rule exists
            regular_rules = rules.select { |rule| rule[:type] != 'INHERITED' }
            if regular_rules.empty?
              raise Dry::Struct::Error, "Cost category must have at least one REGULAR rule"
            end
            
            rules
          }
          
          attribute :rule_version_arn?, String.constrained(format: /\Aarn:aws:ce::[0-9]{12}:cost-category\/[a-zA-Z0-9\-]+\z/).optional
          
          # Default value for uncategorized costs
          attribute :default_value?, String.constrained(min_size: 1, max_size: 50).optional
          
          # Split charge rules for cost allocation
          attribute :split_charge_rules?, Array.of(CostCategorySplitChargeRule).constrained(max_size: 10).optional
          
          # Effective dates for the cost category
          attribute :effective_start?, String.constrained(format: /\A\d{4}-\d{2}-\d{2}\z/).optional
          attribute :effective_end?: String.constrained(format: /\A\d{4}-\d{2}-\d{2}\z/).optional
          
          attribute :tags?, AwsTags.optional
          
          # Custom validation for date ranges and rule consistency
          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}
            
            # Validate effective date range
            if attrs[:effective_start] && attrs[:effective_end]
              start_date = Date.parse(attrs[:effective_start])
              end_date = Date.parse(attrs[:effective_end])
              
              if end_date <= start_date
                raise Dry::Struct::Error, "Effective end date must be after start date"
              end
              
              # Cost categories can't be applied retroactively beyond AWS data retention
              if start_date < Date.today - 365
                raise Dry::Struct::Error, "Effective start date cannot be more than 1 year in the past"
              end
            end
            
            # Validate split charge rules reference valid category values
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
          
          # Computed properties for cost category analysis
          def rule_count
            rules.length
          end
          
          def regular_rule_count
            rules.count { |rule| rule[:type] != 'INHERITED' }
          end
          
          def inherited_rule_count
            rules.count { |rule| rule[:type] == 'INHERITED' }
          end
          
          def has_default_value?
            !default_value.nil?
          end
          
          def has_split_charge_rules?
            split_charge_rules && !split_charge_rules.empty?
          end
          
          def split_charge_rule_count
            split_charge_rules&.length || 0
          end
          
          def has_effective_dates?
            effective_start || effective_end
          end
          
          def is_time_limited?
            effective_end
          end
          
          # Category complexity analysis
          def complexity_score
            score = 0
            
            # Base complexity from number of rules
            score += rule_count * 5
            
            # Additional complexity for inherited rules
            score += inherited_rule_count * 3
            
            # Complexity from split charge rules
            score += split_charge_rule_count * 10
            
            # Complexity from expression nesting
            rules.each do |rule|
              score += expression_complexity(rule[:rule])
            end
            
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
          
          # Cost allocation effectiveness
          def allocation_coverage_estimate
            coverage = 0
            
            # Base coverage from having rules
            coverage += 60 if rule_count > 0
            
            # Coverage from default value (catches uncategorized costs)
            coverage += 20 if has_default_value?
            
            # Coverage from multiple rules (better categorization)
            coverage += [rule_count * 2, 15].min
            
            # Coverage from split charge rules (better allocation)
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
            
            # Logical operators add complexity
            complexity += 5 if expression[:and]
            complexity += 5 if expression[:or]  
            complexity += 3 if expression[:not]
            
            # Recursive complexity for nested expressions
            if expression[:and]
              expression[:and].each { |sub_expr| complexity += expression_complexity(sub_expr) }
            end
            
            if expression[:or]
              expression[:or].each { |sub_expr| complexity += expression_complexity(sub_expr) }
            end
            
            if expression[:not]
              complexity += expression_complexity(expression[:not])
            end
            
            complexity
          end
        end
      end
    end
  end
end