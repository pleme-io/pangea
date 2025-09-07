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
require 'pangea/resources/aws_wafv2_regex_pattern_set/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS WAFv2 Regex Pattern Set with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] WAFv2 regex pattern set attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_wafv2_regex_pattern_set(name, attributes = {})
        # Validate attributes using dry-struct
        regex_attrs = Types::WafV2RegexPatternSetAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_wafv2_regex_pattern_set, name) do
          name regex_attrs.name
          description regex_attrs.description if regex_attrs.description
          scope regex_attrs.scope
          
          # Configure regular expressions
          regex_attrs.regular_expression.each do |pattern|
            regular_expression do
              regex_string pattern[:regex_string]
            end
          end
          
          # Apply tags if present
          if regex_attrs.tags.any?
            tags do
              regex_attrs.tags.each do |key, value|
                public_send(key, value)
              end
            end
          end
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_wafv2_regex_pattern_set',
          name: name,
          resource_attributes: regex_attrs.to_h,
          outputs: {
            id: "${aws_wafv2_regex_pattern_set.#{name}.id}",
            arn: "${aws_wafv2_regex_pattern_set.#{name}.arn}",
            name: "${aws_wafv2_regex_pattern_set.#{name}.name}",
            description: "${aws_wafv2_regex_pattern_set.#{name}.description}",
            scope: "${aws_wafv2_regex_pattern_set.#{name}.scope}",
            regular_expression: "${aws_wafv2_regex_pattern_set.#{name}.regular_expression}",
            tags_all: "${aws_wafv2_regex_pattern_set.#{name}.tags_all}"
          },
          computed_properties: {
            pattern_count: regex_attrs.pattern_count,
            cloudfront_scope: regex_attrs.cloudfront_scope?,
            regional_scope: regex_attrs.regional_scope?,
            patterns: regex_attrs.get_patterns,
            pattern_complexity: regex_attrs.pattern_complexity,
            security_patterns: regex_attrs.security_patterns?,
            primary_use_case: regex_attrs.primary_use_case,
            configuration_warnings: regex_attrs.validate_configuration,
            estimated_monthly_cost: regex_attrs.estimated_monthly_cost
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)