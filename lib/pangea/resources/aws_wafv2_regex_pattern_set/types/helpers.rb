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
        # Helper methods for WAFv2 Regex Pattern Set attributes
        module WafV2RegexPatternSetHelpers
          def pattern_count
            regular_expression.length
          end

          def cloudfront_scope?
            scope == 'CLOUDFRONT'
          end

          def regional_scope?
            scope == 'REGIONAL'
          end

          def get_patterns
            regular_expression.map { |p| p[:regex_string] }
          end

          def estimated_monthly_cost
            "$1.00/month per regex pattern set + $0.60 per million requests evaluated"
          end

          def validate_configuration
            warnings = []

            get_patterns.each_with_index do |pattern, index|
              if pattern.length > 200
                warnings << "Very long regex pattern at index #{index} - may impact performance"
              end

              if pattern.include?('*') && !pattern.include?('\\*')
                warnings << "Unescaped wildcard in pattern at index #{index} - ensure this is intentional"
              end

              if pattern.include?('.*.*') || pattern.include?('.+.+')
                warnings << "Potentially expensive nested quantifiers in pattern at index #{index}"
              end
            end

            if pattern_count == 1
              warnings << "Pattern set contains only one regex - consider consolidating with other sets"
            end

            warnings
          end

          def pattern_complexity
            complex_patterns = get_patterns.count do |pattern|
              pattern.include?('(?') || pattern.include?('[') || pattern.length > 50
            end

            case complex_patterns
            when 0
              'simple'
            when 1..2
              'moderate'
            else
              'complex'
            end
          end

          def security_patterns?
            get_patterns.any? do |pattern|
              pattern.downcase.include?('script') ||
                pattern.include?('<') ||
                pattern.include?('sql') ||
                pattern.include?('union') ||
                pattern.include?('eval')
            end
          end

          def primary_use_case
            patterns = get_patterns.join(' ').downcase

            return 'xss_protection' if patterns.include?('script') || patterns.include?('<')
            return 'sql_injection_protection' if patterns.include?('sql') || patterns.include?('union')
            return 'path_validation' if patterns.include?('/')
            return 'input_validation' if patterns.include?('[a-z')

            'general_filtering'
          end
        end
      end
    end
  end
end
