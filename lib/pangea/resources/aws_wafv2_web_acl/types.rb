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
        # WAF v2 Web ACL visibility configuration
        class WafV2VisibilityConfig < Dry::Struct
          transform_keys(&:to_sym)
          
          attribute :cloudwatch_metrics_enabled, Resources::Types::Bool
          attribute :metric_name, String.constrained(format: /\A[a-zA-Z0-9_-]{1,128}\z/)
          attribute :sampled_requests_enabled, Resources::Types::Bool
        end
        
        # WAF v2 Rule statement configuration
        class WafV2Statement < Dry::Struct
          transform_keys(&:to_sym)
          
          # Basic statement types
          attribute :byte_match_statement, Hash.schema(
            field_to_match: Hash.schema(
              all_query_arguments?: Hash.schema({}).optional,
              body?: Hash.schema(
                oversize_handling?: String.enum('CONTINUE', 'MATCH', 'NO_MATCH').optional
              ).optional,
              method?: Hash.schema({}).optional,
              query_string?: Hash.schema({}).optional,
              single_header?: Hash.schema(
                name: String
              ).optional,
              single_query_argument?: Hash.schema(
                name: String
              ).optional,
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
            text_transformations: Array.of(
              Hash.schema(
                priority: Integer.constrained(gteq: 0),
                type: Resources::Types::WafV2TextTransformation
              )
            ).constrained(min_size: 1)
          ).optional
          
          attribute :sqli_match_statement, Hash.schema(
            field_to_match: Hash.schema(
              all_query_arguments?: Hash.schema({}).optional,
              body?: Hash.schema(
                oversize_handling?: String.enum('CONTINUE', 'MATCH', 'NO_MATCH').optional
              ).optional,
              method?: Hash.schema({}).optional,
              query_string?: Hash.schema({}).optional,
              single_header?: Hash.schema(
                name: String
              ).optional,
              single_query_argument?: Hash.schema(
                name: String
              ).optional,
              uri_path?: Hash.schema({}).optional
            ),
            text_transformations: Array.of(
              Hash.schema(
                priority: Integer.constrained(gteq: 0),
                type: Resources::Types::WafV2TextTransformation
              )
            ).constrained(min_size: 1)
          ).optional
          
          attribute :xss_match_statement, Hash.schema(
            field_to_match: Hash.schema(
              all_query_arguments?: Hash.schema({}).optional,
              body?: Hash.schema(
                oversize_handling?: String.enum('CONTINUE', 'MATCH', 'NO_MATCH').optional
              ).optional,
              method?: Hash.schema({}).optional,
              query_string?: Hash.schema({}).optional,
              single_header?: Hash.schema(
                name: String
              ).optional,
              single_query_argument?: Hash.schema(
                name: String
              ).optional,
              uri_path?: Hash.schema({}).optional
            ),
            text_transformations: Array.of(
              Hash.schema(
                priority: Integer.constrained(gteq: 0),
                type: Resources::Types::WafV2TextTransformation
              )
            ).constrained(min_size: 1)
          ).optional
          
          attribute :size_constraint_statement, Hash.schema(
            field_to_match: Hash.schema(
              all_query_arguments?: Hash.schema({}).optional,
              body?: Hash.schema(
                oversize_handling?: String.enum('CONTINUE', 'MATCH', 'NO_MATCH').optional
              ).optional,
              method?: Hash.schema({}).optional,
              query_string?: Hash.schema({}).optional,
              single_header?: Hash.schema(
                name: String
              ).optional,
              single_query_argument?: Hash.schema(
                name: String
              ).optional,
              uri_path?: Hash.schema({}).optional
            ),
            comparison_operator: Resources::Types::WafV2ComparisonOperator,
            size: Integer.constrained(gteq: 0, lteq: 21474836480),
            text_transformations: Array.of(
              Hash.schema(
                priority: Integer.constrained(gteq: 0),
                type: Resources::Types::WafV2TextTransformation
              )
            ).constrained(min_size: 1)
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
            excluded_rules?: Array.of(
              Hash.schema(
                name: String
              )
            ).optional
          ).optional
          
          attribute :managed_rule_group_statement, Hash.schema(
            vendor_name: String,
            name: String,
            version?: String.optional,
            excluded_rules?: Array.of(
              Hash.schema(
                name: String
              )
            ).optional,
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
          
          # Logical statement types
          attribute :and_statement, Hash.schema(
            statements: Array.of(Hash).constrained(min_size: 2)
          ).optional
          
          attribute :or_statement, Hash.schema(
            statements: Array.of(Hash).constrained(min_size: 2)
          ).optional
          
          attribute :not_statement, Hash.schema(
            statement: Hash
          ).optional
          
          # Validation: exactly one statement type must be provided
          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}
            statement_types = [
              :byte_match_statement, :sqli_match_statement, :xss_match_statement,
              :size_constraint_statement, :geo_match_statement, :ip_set_reference_statement,
              :rule_group_reference_statement, :managed_rule_group_statement,
              :rate_based_statement, :and_statement, :or_statement, :not_statement
            ]
            
            provided_statements = statement_types.select { |type| attrs.key?(type) }
            
            if provided_statements.empty?
              raise Dry::Struct::Error, "WAF v2 statement must specify exactly one statement type"
            elsif provided_statements.size > 1
              raise Dry::Struct::Error, "WAF v2 statement must specify exactly one statement type, got: #{provided_statements.join(', ')}"
            end
            
            super(attrs)
          end
        end
        
        # WAF v2 Rule action configuration
        class WafV2RuleAction < Dry::Struct
          transform_keys(&:to_sym)
          
          attribute :allow, Hash.schema(
            custom_request_handling?: Hash.schema(
              insert_headers: Array.of(
                Hash.schema(
                  name: String,
                  value: String
                )
              )
            ).optional
          ).optional
          
          attribute :block, Hash.schema(
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
          ).optional
          
          attribute :count, Hash.schema(
            custom_request_handling?: Hash.schema(
              insert_headers: Array.of(
                Hash.schema(
                  name: String,
                  value: String
                )
              )
            ).optional
          ).optional
          
          attribute :captcha, Hash.schema(
            custom_request_handling?: Hash.schema(
              insert_headers: Array.of(
                Hash.schema(
                  name: String,
                  value: String
                )
              )
            ).optional
          ).optional
          
          attribute :challenge, Hash.schema(
            custom_request_handling?: Hash.schema(
              insert_headers: Array.of(
                Hash.schema(
                  name: String,
                  value: String
                )
              )
            ).optional
          ).optional
          
          # Validation: exactly one action type must be provided
          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}
            action_types = [:allow, :block, :count, :captcha, :challenge]
            
            provided_actions = action_types.select { |type| attrs.key?(type) }
            
            if provided_actions.empty?
              raise Dry::Struct::Error, "WAF v2 rule action must specify exactly one action type"
            elsif provided_actions.size > 1
              raise Dry::Struct::Error, "WAF v2 rule action must specify exactly one action type, got: #{provided_actions.join(', ')}"
            end
            
            super(attrs)
          end
        end
        
        # WAF v2 Rule configuration
        class WafV2Rule < Dry::Struct
          transform_keys(&:to_sym)
          
          attribute :name, String.constrained(format: /\A[a-zA-Z0-9_-]{1,128}\z/)
          attribute :priority, Integer.constrained(gteq: 0)
          attribute :action, WafV2RuleAction
          attribute :statement, WafV2Statement
          attribute :visibility_config, WafV2VisibilityConfig
          attribute :rule_labels, Array.of(
            Hash.schema(
              name: String.constrained(format: /\A[a-zA-Z0-9_:-]{1,1024}\z/)
            )
          ).default([].freeze)
          attribute :captcha_config, Hash.schema(
            immunity_time_property: Hash.schema(
              immunity_time: Integer.constrained(gteq: 60, lteq: 259200) # 1 min to 3 days
            )
          ).optional
          attribute :challenge_config, Hash.schema(
            immunity_time_property: Hash.schema(
              immunity_time: Integer.constrained(gteq: 60, lteq: 259200) # 1 min to 3 days
            )
          ).optional
          
          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}
            
            # Validate that captcha_config is only present with captcha action
            if attrs[:captcha_config] && (!attrs[:action] || !attrs[:action][:captcha])
              raise Dry::Struct::Error, "captcha_config can only be specified with captcha action"
            end
            
            # Validate that challenge_config is only present with challenge action
            if attrs[:challenge_config] && (!attrs[:action] || !attrs[:action][:challenge])
              raise Dry::Struct::Error, "challenge_config can only be specified with challenge action"
            end
            
            super(attrs)
          end
        end
        
        # WAF v2 Default action configuration
        class WafV2DefaultAction < Dry::Struct
          transform_keys(&:to_sym)
          
          attribute :allow, Hash.schema(
            custom_request_handling?: Hash.schema(
              insert_headers: Array.of(
                Hash.schema(
                  name: String,
                  value: String
                )
              )
            ).optional
          ).optional
          
          attribute :block, Hash.schema(
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
          ).optional
          
          # Validation: exactly one action type must be provided
          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}
            action_types = [:allow, :block]
            
            provided_actions = action_types.select { |type| attrs.key?(type) }
            
            if provided_actions.empty?
              raise Dry::Struct::Error, "WAF v2 default action must specify either allow or block"
            elsif provided_actions.size > 1
              raise Dry::Struct::Error, "WAF v2 default action must specify either allow or block, not both"
            end
            
            super(attrs)
          end
        end
        
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
          
          # Custom response bodies for blocked requests
          attribute :custom_response_bodies, Hash.map(
            String.constrained(format: /\A[a-zA-Z0-9_-]{1,64}\z/),
            Hash.schema(
              content: String.constrained(max_size: 10240),
              content_type: String.enum('TEXT_PLAIN', 'TEXT_HTML', 'APPLICATION_JSON')
            )
          ).default({}.freeze)
          
          # Token domains for CAPTCHA/Challenge
          attribute :token_domains, Array.of(
            String.constrained(format: /\A[a-zA-Z0-9.-]+\z/)
          ).default([].freeze)
          
          # Challenge config for the Web ACL
          attribute :challenge_config, Hash.schema(
            immunity_time_property: Hash.schema(
              immunity_time: Integer.constrained(gteq: 60, lteq: 259200)
            )
          ).optional
          
          # Captcha config for the Web ACL  
          attribute :captcha_config, Hash.schema(
            immunity_time_property: Hash.schema(
              immunity_time: Integer.constrained(gteq: 60, lteq: 259200)
            )
          ).optional
          
          # Custom validation
          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}
            
            # Validate rule priorities are unique
            if attrs[:rules]&.any?
              priorities = attrs[:rules].map { |rule| rule[:priority] }
              if priorities.size != priorities.uniq.size
                raise Dry::Struct::Error, "WAF v2 Web ACL rule priorities must be unique"
              end
            end
            
            # Validate that custom_response_bodies are only used when block actions specify custom responses
            if attrs[:custom_response_bodies]&.any?
              block_actions_with_custom_response = []
              
              # Check default action
              if attrs[:default_action]&.dig(:block, :custom_response)
                custom_body_key = attrs[:default_action][:block][:custom_response][:custom_response_body_key]
                block_actions_with_custom_response << custom_body_key if custom_body_key
              end
              
              # Check rule actions
              attrs[:rules]&.each do |rule|
                if rule[:action]&.dig(:block, :custom_response)
                  custom_body_key = rule[:action][:block][:custom_response][:custom_response_body_key]
                  block_actions_with_custom_response << custom_body_key if custom_body_key
                end
              end
              
              # Validate that all custom_response_body_keys reference defined bodies
              undefined_keys = block_actions_with_custom_response - attrs[:custom_response_bodies].keys.map(&:to_s)
              unless undefined_keys.empty?
                raise Dry::Struct::Error, "Custom response body keys #{undefined_keys.join(', ')} are referenced but not defined"
              end
              
              # Validate that all defined bodies are referenced
              unreferenced_keys = attrs[:custom_response_bodies].keys.map(&:to_s) - block_actions_with_custom_response
              unless unreferenced_keys.empty?
                raise Dry::Struct::Error, "Custom response bodies #{unreferenced_keys.join(', ')} are defined but not referenced"
              end
            end
            
            # Validate scope-specific constraints
            if attrs[:scope] == 'CLOUDFRONT'
              # For CloudFront, certain features are limited
              attrs[:rules]&.each do |rule|
                if rule[:action]&.key?(:captcha) || rule[:action]&.key?(:challenge)
                  raise Dry::Struct::Error, "CAPTCHA and Challenge actions are not supported for CloudFront scope"
                end
              end
            end
            
            super(attrs)
          end
          
          # Computed properties
          def total_capacity_units_estimate
            # Base capacity for Web ACL
            base_capacity = 1
            
            # Add capacity for each rule (rough estimate)
            rules_capacity = rules.sum do |rule|
              estimate_rule_capacity(rule)
            end
            
            base_capacity + rules_capacity
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
            # Simplified capacity estimation based on statement types
            statement = rule.statement
            
            if statement.managed_rule_group_statement
              100 # Managed rule groups typically consume more capacity
            elsif statement.rate_based_statement
              50  # Rate-based rules consume moderate capacity
            elsif statement.and_statement || statement.or_statement
              30  # Logical statements consume moderate capacity
            elsif statement.geo_match_statement
              10  # Geo match is relatively lightweight
            elsif statement.ip_set_reference_statement
              10  # IP set reference is lightweight
            elsif statement.byte_match_statement || statement.sqli_match_statement || statement.xss_match_statement
              20  # String matching statements consume moderate capacity
            else
              5   # Default capacity for other statements
            end
          end
        end
      end
    end
  end
end