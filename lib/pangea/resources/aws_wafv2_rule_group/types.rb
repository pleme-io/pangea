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
require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
        # WAF v2 Rule Group attributes with validation
        class WafV2RuleGroupAttributes < Dry::Struct
          transform_keys(&:to_sym)
          
          attribute :name, String.constrained(format: /\A[a-zA-Z0-9_-]{1,128}\z/)
          attribute :scope, Resources::Types::WafV2Scope
          attribute :capacity, Resources::Types::WafV2CapacityUnits
          attribute :description, String.constrained(max_size: 256).optional
          attribute :rules, Array.of(
            Hash.schema(
              name: String.constrained(format: /\A[a-zA-Z0-9_-]{1,128}\z/),
              priority: Integer.constrained(gteq: 0),
              action: Hash.schema(
                allow?: Hash.schema(
                  custom_request_handling?: Hash.schema(
                    insert_headers: Array.of(
                      Hash.schema(
                        name: String,
                        value: String
                      )
                    )
                  ).optional
                ).optional,
                block?: Hash.schema(
                  custom_response?: Hash.schema(
                    response_code: Integer.constrained(gteq: 200, lteq: 599),
                    custom_response_body_key?: String.optional,
                    response_headers?: Array.of(
                      Hash.schema(
                        name: String,
                        value: String
                      )
                    ).optional
                  ).optional
                ).optional,
                count?: Hash.schema(
                  custom_request_handling?: Hash.schema(
                    insert_headers: Array.of(
                      Hash.schema(
                        name: String,
                        value: String
                      )
                    )
                  ).optional
                ).optional,
                captcha?: Hash.schema(
                  custom_request_handling?: Hash.schema(
                    insert_headers: Array.of(
                      Hash.schema(
                        name: String,
                        value: String
                      )
                    )
                  ).optional
                ).optional,
                challenge?: Hash.schema(
                  custom_request_handling?: Hash.schema(
                    insert_headers: Array.of(
                      Hash.schema(
                        name: String,
                        value: String
                      )
                    )
                  ).optional
                ).optional
              ).constructor { |attrs|
                # Validate that exactly one action type is provided
                action_types = [:allow, :block, :count, :captcha, :challenge]
                provided_actions = action_types.select { |type| attrs.key?(type) }
                
                if provided_actions.empty?
                  raise Dry::Types::ConstraintError, "Rule action must specify exactly one action type"
                elsif provided_actions.size > 1
                  raise Dry::Types::ConstraintError, "Rule action must specify exactly one action type, got: #{provided_actions.join(', ')}"
                end
                
                attrs
              },
              statement: Hash, # Complex nested statement structure
              visibility_config: Hash.schema(
                cloudwatch_metrics_enabled: Resources::Types::Bool,
                metric_name: String.constrained(format: /\A[a-zA-Z0-9_-]{1,128}\z/),
                sampled_requests_enabled: Resources::Types::Bool
              ),
              rule_labels?: Array.of(
                Hash.schema(
                  name: String.constrained(format: /\A[a-zA-Z0-9_:-]{1,1024}\z/)
                )
              ).optional,
              captcha_config?: Hash.schema(
                immunity_time_property: Hash.schema(
                  immunity_time: Integer.constrained(gteq: 60, lteq: 259200)
                )
              ).optional,
              challenge_config?: Hash.schema(
                immunity_time_property: Hash.schema(
                  immunity_time: Integer.constrained(gteq: 60, lteq: 259200)
                )
              ).optional
            )
          ).default([].freeze)
          attribute :visibility_config, Hash.schema(
            cloudwatch_metrics_enabled: Resources::Types::Bool,
            metric_name: String.constrained(format: /\A[a-zA-Z0-9_-]{1,128}\z/),
            sampled_requests_enabled: Resources::Types::Bool
          )
          attribute :tags, Resources::Types::AwsTags
          
          # Custom response bodies for rule group
          attribute :custom_response_bodies, Hash.map(
            String.constrained(format: /\A[a-zA-Z0-9_-]{1,64}\z/),
            Hash.schema(
              content: String.constrained(max_size: 10240),
              content_type: String.enum('TEXT_PLAIN', 'TEXT_HTML', 'APPLICATION_JSON')
            )
          ).default({}.freeze)

          # Custom validation
          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}
            
            # Validate rule priorities are unique
            if attrs[:rules]&.any?
              priorities = attrs[:rules].map { |rule| rule[:priority] }
              if priorities.size != priorities.uniq.size
                raise Dry::Struct::Error, "Rule group rule priorities must be unique"
              end
            end
            
            # Validate capacity is realistic for rule count and complexity
            if attrs[:rules] && attrs[:capacity]
              estimated_capacity = estimate_required_capacity(attrs[:rules])
              if attrs[:capacity] < estimated_capacity
                raise Dry::Struct::Error, "Specified capacity #{attrs[:capacity]} is likely insufficient for #{attrs[:rules].size} rules (estimated: #{estimated_capacity})"
              end
            end
            
            # Validate custom response body references
            if attrs[:custom_response_bodies]&.any? && attrs[:rules]&.any?
              referenced_bodies = []
              
              attrs[:rules].each do |rule|
                if rule.dig(:action, :block, :custom_response, :custom_response_body_key)
                  referenced_bodies << rule[:action][:block][:custom_response][:custom_response_body_key]
                end
              end
              
              # Check that all referenced bodies are defined
              undefined_keys = referenced_bodies - attrs[:custom_response_bodies].keys.map(&:to_s)
              unless undefined_keys.empty?
                raise Dry::Struct::Error, "Custom response body keys #{undefined_keys.join(', ')} are referenced but not defined"
              end
              
              # Check that all defined bodies are referenced
              unreferenced_keys = attrs[:custom_response_bodies].keys.map(&:to_s) - referenced_bodies
              unless unreferenced_keys.empty?
                raise Dry::Struct::Error, "Custom response bodies #{unreferenced_keys.join(', ')} are defined but not referenced"
              end
            end
            
            # Validate scope-specific constraints
            if attrs[:scope] == 'CLOUDFRONT'
              attrs[:rules]&.each do |rule|
                if rule.dig(:action, :captcha) || rule.dig(:action, :challenge)
                  raise Dry::Struct::Error, "CAPTCHA and Challenge actions are not supported for CloudFront scope"
                end
              end
            end
            
            super(attrs)
          end
          
          # Computed properties
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
          
          private
          
          def self.estimate_required_capacity(rules)
            base_capacity = 1
            
            rules_capacity = rules.sum do |rule|
              statement = rule[:statement]
              next 5 unless statement # Default for empty statements
              
              if statement[:rate_based_statement]
                50
              elsif statement[:and_statement] || statement[:or_statement]
                30
              elsif statement[:geo_match_statement]
                10
              elsif statement[:ip_set_reference_statement]
                10
              elsif statement[:byte_match_statement] || statement[:sqli_match_statement] || statement[:xss_match_statement]
                20
              elsif statement[:size_constraint_statement]
                15
              elsif statement[:not_statement]
                25
              else
                10
              end
            end
            
            base_capacity + rules_capacity
          end
        end
      end
    end
  end
end