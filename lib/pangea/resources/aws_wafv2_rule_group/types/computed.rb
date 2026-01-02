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
        # Computed properties for WAF v2 Rule Group attributes
        module WafV2ComputedProperties
          def total_rule_count
            rules.size
          end

          def has_rate_limiting?
            rules.any? { |rule| rule[:statement]&.dig(:rate_based_statement) }
          end

          def has_geo_blocking?
            rules.any? { |rule| rule[:statement]&.dig(:geo_match_statement) }
          end

          def has_string_matching?
            rules.any? do |rule|
              statement = rule[:statement]
              statement&.dig(:byte_match_statement) ||
                statement&.dig(:sqli_match_statement) ||
                statement&.dig(:xss_match_statement)
            end
          end

          def has_size_constraints?
            rules.any? { |rule| rule[:statement]&.dig(:size_constraint_statement) }
          end

          def uses_custom_responses?
            custom_response_bodies.any?
          end

          def rule_priorities
            rules.map { |rule| rule[:priority] }.sort
          end

          def cloudfront_compatible?
            scope == 'CLOUDFRONT' && rules.none? do |rule|
              rule.dig(:action, :captcha) || rule.dig(:action, :challenge)
            end
          end
        end
      end
    end
  end
end
