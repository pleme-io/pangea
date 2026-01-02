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

module Pangea
  module Resources
    module AWS
      module Types
        # Validation logic for WAF v2 Rule Group attributes
        module WafV2Validators
          def self.validate_attributes(attrs)
            validate_unique_priorities(attrs)
            validate_capacity(attrs)
            validate_custom_response_bodies(attrs)
            validate_scope_constraints(attrs)
          end

          def self.validate_unique_priorities(attrs)
            return unless attrs[:rules]&.any?

            priorities = attrs[:rules].map { |rule| rule[:priority] }
            return if priorities.size == priorities.uniq.size

            raise Dry::Struct::Error, 'Rule group rule priorities must be unique'
          end

          def self.validate_capacity(attrs)
            return unless attrs[:rules] && attrs[:capacity]

            estimated = estimate_required_capacity(attrs[:rules])
            return unless attrs[:capacity] < estimated

            raise Dry::Struct::Error,
                  "Specified capacity #{attrs[:capacity]} is likely insufficient " \
                  "for #{attrs[:rules].size} rules (estimated: #{estimated})"
          end

          def self.validate_custom_response_bodies(attrs)
            return unless attrs[:custom_response_bodies]&.any? && attrs[:rules]&.any?

            referenced = collect_referenced_body_keys(attrs[:rules])
            defined = attrs[:custom_response_bodies].keys.map(&:to_s)

            validate_all_bodies_defined(referenced, defined)
            validate_all_bodies_referenced(referenced, defined)
          end

          def self.collect_referenced_body_keys(rules)
            rules.filter_map do |rule|
              rule.dig(:action, :block, :custom_response, :custom_response_body_key)
            end
          end

          def self.validate_all_bodies_defined(referenced, defined)
            undefined = referenced - defined
            return if undefined.empty?

            raise Dry::Struct::Error,
                  "Custom response body keys #{undefined.join(', ')} are referenced but not defined"
          end

          def self.validate_all_bodies_referenced(referenced, defined)
            unreferenced = defined - referenced
            return if unreferenced.empty?

            raise Dry::Struct::Error,
                  "Custom response bodies #{unreferenced.join(', ')} are defined but not referenced"
          end

          def self.validate_scope_constraints(attrs)
            return unless attrs[:scope] == 'CLOUDFRONT'

            attrs[:rules]&.each do |rule|
              next unless rule.dig(:action, :captcha) || rule.dig(:action, :challenge)

              raise Dry::Struct::Error,
                    'CAPTCHA and Challenge actions are not supported for CloudFront scope'
            end
          end

          def self.estimate_required_capacity(rules)
            base_capacity = 1
            rules_capacity = rules.sum { |rule| capacity_for_statement(rule[:statement]) }
            base_capacity + rules_capacity
          end

          def self.capacity_for_statement(statement)
            return 5 unless statement

            case
            when statement[:rate_based_statement] then 50
            when statement[:and_statement], statement[:or_statement] then 30
            when statement[:not_statement] then 25
            when statement[:byte_match_statement],
                 statement[:sqli_match_statement],
                 statement[:xss_match_statement] then 20
            when statement[:size_constraint_statement] then 15
            when statement[:geo_match_statement],
                 statement[:ip_set_reference_statement] then 10
            else 10
            end
          end
        end
      end
    end
  end
end
