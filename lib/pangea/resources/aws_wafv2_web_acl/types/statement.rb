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
        # WAF v2 Rule statement configuration
        class WafV2Statement < Dry::Struct
          STATEMENT_TYPES = %i[
            byte_match_statement sqli_match_statement xss_match_statement
            size_constraint_statement geo_match_statement ip_set_reference_statement
            rule_group_reference_statement managed_rule_group_statement
            rate_based_statement and_statement or_statement not_statement
          ].freeze

          transform_keys(&:to_sym)

          attribute :byte_match_statement, Hash.schema(
            field_to_match: Hash.schema(
              all_query_arguments?: Hash.schema({}).optional,
              body?: Hash.schema(oversize_handling?: String.enum('CONTINUE', 'MATCH', 'NO_MATCH').optional).optional,
              method?: Hash.schema({}).optional,
              query_string?: Hash.schema({}).optional,
              single_header?: Hash.schema(name: String).optional,
              single_query_argument?: Hash.schema(name: String).optional,
              uri_path?: Hash.schema({}).optional,
              json_body?: Hash.schema(
                match_pattern: Resources::Types::WafV2JsonBodyMatchPattern,
                match_scope: String.enum('ALL', 'KEY', 'VALUE'),
                invalid_fallback_behavior?: String.enum('MATCH', 'NO_MATCH', 'EVALUATE_AS_STRING').optional,
                oversize_handling?: String.enum('CONTINUE', 'MATCH', 'NO_MATCH').optional
              ).optional
            ),
            positional_constraint: Resources::Types::WafV2PositionalConstraint,
            search_string: String,
            text_transformations: Array.of(Hash.schema(
                                             priority: Integer.constrained(gteq: 0),
                                             type: Resources::Types::WafV2TextTransformation
                                           )).constrained(min_size: 1)
          ).optional

          attribute :sqli_match_statement, Hash.schema(
            field_to_match: Hash.schema(
              all_query_arguments?: Hash.schema({}).optional,
              body?: Hash.schema(oversize_handling?: String.enum('CONTINUE', 'MATCH', 'NO_MATCH').optional).optional,
              method?: Hash.schema({}).optional,
              query_string?: Hash.schema({}).optional,
              single_header?: Hash.schema(name: String).optional,
              single_query_argument?: Hash.schema(name: String).optional,
              uri_path?: Hash.schema({}).optional
            ),
            text_transformations: Array.of(Hash.schema(
                                             priority: Integer.constrained(gteq: 0),
                                             type: Resources::Types::WafV2TextTransformation
                                           )).constrained(min_size: 1)
          ).optional

          attribute :xss_match_statement, Hash.schema(
            field_to_match: Hash.schema(
              all_query_arguments?: Hash.schema({}).optional,
              body?: Hash.schema(oversize_handling?: String.enum('CONTINUE', 'MATCH', 'NO_MATCH').optional).optional,
              method?: Hash.schema({}).optional,
              query_string?: Hash.schema({}).optional,
              single_header?: Hash.schema(name: String).optional,
              single_query_argument?: Hash.schema(name: String).optional,
              uri_path?: Hash.schema({}).optional
            ),
            text_transformations: Array.of(Hash.schema(
                                             priority: Integer.constrained(gteq: 0),
                                             type: Resources::Types::WafV2TextTransformation
                                           )).constrained(min_size: 1)
          ).optional

          attribute :size_constraint_statement, Hash.schema(
            field_to_match: Hash.schema(
              all_query_arguments?: Hash.schema({}).optional,
              body?: Hash.schema(oversize_handling?: String.enum('CONTINUE', 'MATCH', 'NO_MATCH').optional).optional,
              method?: Hash.schema({}).optional,
              query_string?: Hash.schema({}).optional,
              single_header?: Hash.schema(name: String).optional,
              single_query_argument?: Hash.schema(name: String).optional,
              uri_path?: Hash.schema({}).optional
            ),
            comparison_operator: Resources::Types::WafV2ComparisonOperator,
            size: Integer.constrained(gteq: 0, lteq: 21_474_836_480),
            text_transformations: Array.of(Hash.schema(
                                             priority: Integer.constrained(gteq: 0),
                                             type: Resources::Types::WafV2TextTransformation
                                           )).constrained(min_size: 1)
          ).optional

          attribute :geo_match_statement, Hash.schema(
            country_codes: Array.of(String.constrained(format: /\A[A-Z]{2}\z/)).constrained(min_size: 1),
            forwarded_ip_config?: Hash.schema(
              header_name: String,
              fallback_behavior: String.enum('MATCH', 'NO_MATCH')
            ).optional
          ).optional

          attribute :ip_set_reference_statement, Hash.schema(
            arn: String.constrained(format: /\Aarn:aws:wafv2:/),
            ip_set_forwarded_ip_config?: Hash.schema(
              header_name: String,
              fallback_behavior: String.enum('MATCH', 'NO_MATCH'),
              position: String.enum('FIRST', 'LAST', 'ANY')
            ).optional
          ).optional

          attribute :rule_group_reference_statement, Hash.schema(
            arn: String.constrained(format: /\Aarn:aws:wafv2:/),
            excluded_rules?: Array.of(Hash.schema(name: String)).optional
          ).optional

          attribute :managed_rule_group_statement, Hash.schema(
            vendor_name: String,
            name: String,
            version?: String.optional,
            excluded_rules?: Array.of(Hash.schema(name: String)).optional,
            scope_down_statement?: Hash.optional,
            managed_rule_group_configs?: Array.of(Hash).optional
          ).optional

          attribute :rate_based_statement, Hash.schema(
            limit: Resources::Types::WafV2RateLimit,
            aggregate_key_type: String.enum('IP', 'FORWARDED_IP'),
            forwarded_ip_config?: Hash.schema(
              header_name: String,
              fallback_behavior: String.enum('MATCH', 'NO_MATCH')
            ).optional,
            scope_down_statement?: Hash.optional
          ).optional

          attribute :and_statement, Hash.schema(
            statements: Array.of(Hash).constrained(min_size: 2)
          ).optional

          attribute :or_statement, Hash.schema(
            statements: Array.of(Hash).constrained(min_size: 2)
          ).optional

          attribute :not_statement, Hash.schema(
            statement: Hash
          ).optional

          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}
            provided_statements = STATEMENT_TYPES.select { |type| attrs.key?(type) }

            raise Dry::Struct::Error, 'WAF v2 statement must specify exactly one statement type' if provided_statements.empty?

            raise Dry::Struct::Error, "WAF v2 statement must specify exactly one statement type, got: #{provided_statements.join(', ')}" if provided_statements.size > 1

            super(attrs)
          end
        end
      end
    end
  end
end
