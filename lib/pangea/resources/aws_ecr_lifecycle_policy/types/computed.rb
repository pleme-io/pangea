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

require 'json'

module Pangea
  module Resources
    module AWS
      module Types
        class ECRLifecyclePolicyAttributes
          # Computed properties for ECR lifecycle policy
          module Computed
            def lifecycle_policy_hash
              return nil if is_terraform_reference?

              begin
                JSON.parse(policy)
              rescue JSON::ParserError
                nil
              end
            end

            def rule_count
              doc = lifecycle_policy_hash
              return 0 unless doc && doc['rules']
              doc['rules'].size
            end

            def rule_priorities
              doc = lifecycle_policy_hash
              return [] unless doc && doc['rules']
              doc['rules'].map { |rule| rule['rulePriority'] }.compact.sort
            end

            def has_tagged_image_rules?
              doc = lifecycle_policy_hash
              return false unless doc && doc['rules']
              doc['rules'].any? { |rule| rule.dig('selection', 'tagStatus') == 'tagged' }
            end

            def has_untagged_image_rules?
              doc = lifecycle_policy_hash
              return false unless doc && doc['rules']
              doc['rules'].any? { |rule| rule.dig('selection', 'tagStatus') == 'untagged' }
            end

            def has_count_based_rules?
              doc = lifecycle_policy_hash
              return false unless doc && doc['rules']
              doc['rules'].any? { |rule| rule.dig('selection', 'countType') == 'imageCountMoreThan' }
            end

            def has_age_based_rules?
              doc = lifecycle_policy_hash
              return false unless doc && doc['rules']
              doc['rules'].any? { |rule| rule.dig('selection', 'countType') == 'sinceImagePushed' }
            end

            def estimated_retention_days
              doc = lifecycle_policy_hash
              return nil unless doc && doc['rules']

              max_days = 0
              doc['rules'].each do |rule|
                if rule.dig('selection', 'countType') == 'sinceImagePushed'
                  days = calculate_days_from_rule(rule)
                  max_days = [max_days, days].max
                end
              end

              max_days > 0 ? max_days : nil
            end

            def is_terraform_reference?
              policy.match?(/^\$\{/) || policy.match?(/^jsonencode\(/)
            end

            private

            def calculate_days_from_rule(rule)
              unit = rule.dig('selection', 'countUnit')
              number = rule.dig('selection', 'countNumber')
              return 0 unless unit && number

              case unit
              when 'days' then number
              when 'weeks' then number * 7
              when 'months' then number * 30
              else 0
              end
            end
          end
        end
      end
    end
  end
end
