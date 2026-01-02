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
require 'pangea/resources/aws_ce_cost_category/types'
require 'pangea/resource_registry'
require_relative 'expression_builder'

module Pangea
  module Resources
    module AWS
      # Create an AWS Cost Explorer Cost Category for advanced cost organization and allocation
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Cost category configuration attributes
      # @return [ResourceReference] Reference object with outputs and cost allocation insights
      def aws_ce_cost_category(name, attributes = {})
        # Validate attributes using dry-struct with comprehensive cost categorization validation
        category_attrs = Types::CostCategoryAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_ce_cost_category, name) do
          name category_attrs.name
          rule_version_arn category_attrs.rule_version_arn if category_attrs.rule_version_arn
          
          # Default value for uncategorized costs
          default_value category_attrs.default_value if category_attrs.default_value
          
          # Effective date range
          effective_start category_attrs.effective_start if category_attrs.effective_start
          effective_end category_attrs.effective_end if category_attrs.effective_end
          
          # Cost categorization rules
          category_attrs.rules.each_with_index do |rule_config, index|
            rule index do
              value rule_config[:value]
              type rule_config[:type] if rule_config[:type]
              
              # Rule expression configuration
              rule do
                CostCategoryExpressionBuilder.build(rule_config[:rule], self)
              end
              
              # Inherited value configuration for INHERITED rules
              if rule_config[:inherited_value]
                inherited_value do
                  dimension_key rule_config[:inherited_value][:dimension_key] if rule_config[:inherited_value][:dimension_key]
                  dimension_name rule_config[:inherited_value][:dimension_name] if rule_config[:inherited_value][:dimension_name]
                end
              end
            end
          end
          
          # Split charge rules for cost allocation
          if category_attrs.split_charge_rules
            category_attrs.split_charge_rules.each_with_index do |split_rule, index|
              split_charge_rule index do
                source split_rule[:source]
                method split_rule[:method]
                
                # Target cost categories
                split_rule[:targets].each_with_index do |target, target_index|
                  target target_index do
                    value target
                  end
                end
                
                # Parameters for FIXED and PROPORTIONAL methods
                if split_rule[:parameters]
                  split_rule[:parameters].each_with_index do |parameter, param_index|
                    parameter param_index do
                      type parameter[:type]
                      
                      parameter[:values].each_with_index do |value, value_index|
                        value value_index do
                          value value
                        end
                      end
                    end
                  end
                end
              end
            end
          end
          
          # Apply tags for resource organization and cost tracking
          if category_attrs.tags&.any?
            tags do
              category_attrs.tags.each do |key, value|
                public_send(key, value)
              end
            end
          end
        end
        
        # Return resource reference with comprehensive cost categorization insights
        ResourceReference.new(
          type: 'aws_ce_cost_category',
          name: name,
          resource_attributes: category_attrs.to_h,
          outputs: {
            # Core identifiers
            arn: "${aws_ce_cost_category.#{name}.arn}",
            cost_category_arn: "${aws_ce_cost_category.#{name}.arn}",
            name: "${aws_ce_cost_category.#{name}.name}",
            rule_version_arn: "${aws_ce_cost_category.#{name}.rule_version_arn}",
            
            # Configuration details
            default_value: "${aws_ce_cost_category.#{name}.default_value}",
            effective_start: "${aws_ce_cost_category.#{name}.effective_start}",
            effective_end: "${aws_ce_cost_category.#{name}.effective_end}",
            
            # Computed categorization insights
            rule_count: category_attrs.rule_count,
            regular_rule_count: category_attrs.regular_rule_count,
            inherited_rule_count: category_attrs.inherited_rule_count,
            split_charge_rule_count: category_attrs.split_charge_rule_count,
            
            # Category characteristics
            has_default_value: category_attrs.has_default_value?,
            has_split_charge_rules: category_attrs.has_split_charge_rules?,
            has_effective_dates: category_attrs.has_effective_dates?,
            is_time_limited: category_attrs.is_time_limited?,
            
            # Complexity and maturity analysis
            complexity_score: category_attrs.complexity_score,
            complexity_level: category_attrs.complexity_level,
            allocation_coverage_estimate: category_attrs.allocation_coverage_estimate,
            governance_maturity_level: category_attrs.governance_maturity_level
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)