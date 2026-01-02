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
        # Main WAF v2 Web ACL attributes
        class WafV2WebAclAttributes < Dry::Struct
          transform_keys(&:to_sym)

          attribute :name, String.constrained(format: /\A[a-zA-Z0-9_-]{1,128}\z/)
          attribute :scope, Resources::Types::WafV2Scope
          attribute :default_action, WafV2DefaultAction
          attribute :description, String.constrained(max_size: 256).optional
          attribute :rules, Array.of(WafV2Rule).default([].freeze)
          attribute :visibility_config, WafV2VisibilityConfig
          attribute :tags, Resources::Types::AwsTags
          attribute :custom_response_bodies, Hash.map(
            String.constrained(format: /\A[a-zA-Z0-9_-]{1,64}\z/),
            Hash.schema(
              content: String.constrained(max_size: 10_240),
              content_type: String.enum('TEXT_PLAIN', 'TEXT_HTML', 'APPLICATION_JSON')
            )
          ).default({}.freeze)
          attribute :token_domains, Array.of(String.constrained(format: /\A[a-zA-Z0-9.-]+\z/)).default([].freeze)
          attribute :challenge_config, Hash.schema(
            immunity_time_property: Hash.schema(immunity_time: Integer.constrained(gteq: 60, lteq: 259_200))
          ).optional
          attribute :captcha_config, Hash.schema(
            immunity_time_property: Hash.schema(immunity_time: Integer.constrained(gteq: 60, lteq: 259_200))
          ).optional

          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}

            validate_rule_priorities(attrs)
            validate_custom_response_bodies(attrs)
            validate_scope_constraints(attrs)

            super(attrs)
          end

          def self.validate_rule_priorities(attrs)
            return unless attrs[:rules]&.any?

            priorities = attrs[:rules].map { |rule| rule[:priority] }
            return unless priorities.size != priorities.uniq.size

            raise Dry::Struct::Error, 'WAF v2 Web ACL rule priorities must be unique'
          end

          def self.validate_custom_response_bodies(attrs)
            return unless attrs[:custom_response_bodies]&.any?

            referenced_keys = collect_custom_response_keys(attrs)
            defined_keys = attrs[:custom_response_bodies].keys.map(&:to_s)

            validate_referenced_keys(referenced_keys, defined_keys)
            validate_defined_keys(defined_keys, referenced_keys)
          end

          def self.collect_custom_response_keys(attrs)
            keys = []

            if attrs[:default_action]&.dig(:block, :custom_response)
              key = attrs[:default_action][:block][:custom_response][:custom_response_body_key]
              keys << key if key
            end

            attrs[:rules]&.each do |rule|
              next unless rule[:action]&.dig(:block, :custom_response)

              key = rule[:action][:block][:custom_response][:custom_response_body_key]
              keys << key if key
            end

            keys
          end

          def self.validate_referenced_keys(referenced_keys, defined_keys)
            undefined_keys = referenced_keys - defined_keys
            return if undefined_keys.empty?

            raise Dry::Struct::Error, "Custom response body keys #{undefined_keys.join(', ')} are referenced but not defined"
          end

          def self.validate_defined_keys(defined_keys, referenced_keys)
            unreferenced_keys = defined_keys - referenced_keys
            return if unreferenced_keys.empty?

            raise Dry::Struct::Error, "Custom response bodies #{unreferenced_keys.join(', ')} are defined but not referenced"
          end

          def self.validate_scope_constraints(attrs)
            return unless attrs[:scope] == 'CLOUDFRONT'

            attrs[:rules]&.each do |rule|
              next unless rule[:action]&.key?(:captcha) || rule[:action]&.key?(:challenge)

              raise Dry::Struct::Error, 'CAPTCHA and Challenge actions are not supported for CloudFront scope'
            end
          end

          def total_capacity_units_estimate
            1 + rules.sum { |rule| estimate_rule_capacity(rule) }
          end

          def has_rate_limiting?
            rules.any? { |rule| rule.statement.rate_based_statement }
          end

          def has_geo_blocking?
            rules.any? { |rule| rule.statement.geo_match_statement }
          end

          def has_managed_rules?
            rules.any? { |rule| rule.statement.managed_rule_group_statement }
          end

          def uses_custom_responses?
            custom_response_bodies.any?
          end

          private

          def estimate_rule_capacity(rule)
            statement = rule.statement

            if statement.managed_rule_group_statement then 100
            elsif statement.rate_based_statement then 50
            elsif statement.and_statement || statement.or_statement then 30
            elsif statement.geo_match_statement || statement.ip_set_reference_statement then 10
            elsif statement.byte_match_statement || statement.sqli_match_statement || statement.xss_match_statement then 20
            else 5
            end
          end
        end
      end
    end
  end
end
