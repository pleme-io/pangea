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
require 'pangea/resources/aws_wafv2_rule_group/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS WAF v2 Rule Group with reusable security rules
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] WAF v2 Rule Group attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_wafv2_rule_group(name, attributes = {})
        # Validate attributes using dry-struct
        rule_group_attrs = Types::WafV2RuleGroupAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_wafv2_rule_group, name) do
          name rule_group_attrs.name
          scope rule_group_attrs.scope.downcase
          capacity rule_group_attrs.capacity
          
          # Description if provided
          if rule_group_attrs.description
            description rule_group_attrs.description
          end
          
          # Rules configuration
          rule_group_attrs.rules.each do |rule_attrs|
            rule do
              name rule_attrs[:name]
              priority rule_attrs[:priority]
              
              # Rule action
              action do
                if rule_attrs[:action][:allow]
                  allow do
                    if rule_attrs[:action][:allow][:custom_request_handling]
                      custom_request_handling do
                        rule_attrs[:action][:allow][:custom_request_handling][:insert_headers].each do |header|
                          insert_header do
                            name header[:name]
                            value header[:value]
                          end
                        end
                      end
                    end
                  end
                elsif rule_attrs[:action][:block]
                  block do
                    if rule_attrs[:action][:block][:custom_response]
                      custom_response do
                        response_code rule_attrs[:action][:block][:custom_response][:response_code]
                        
                        if rule_attrs[:action][:block][:custom_response][:custom_response_body_key]
                          custom_response_body_key rule_attrs[:action][:block][:custom_response][:custom_response_body_key]
                        end
                        
                        if rule_attrs[:action][:block][:custom_response][:response_headers]
                          rule_attrs[:action][:block][:custom_response][:response_headers].each do |header|
                            response_header do
                              name header[:name]
                              value header[:value]
                            end
                          end
                        end
                      end
                    end
                  end
                elsif rule_attrs[:action][:count]
                  count do
                    if rule_attrs[:action][:count][:custom_request_handling]
                      custom_request_handling do
                        rule_attrs[:action][:count][:custom_request_handling][:insert_headers].each do |header|
                          insert_header do
                            name header[:name]
                            value header[:value]
                          end
                        end
                      end
                    end
                  end
                elsif rule_attrs[:action][:captcha]
                  captcha do
                    if rule_attrs[:action][:captcha][:custom_request_handling]
                      custom_request_handling do
                        rule_attrs[:action][:captcha][:custom_request_handling][:insert_headers].each do |header|
                          insert_header do
                            name header[:name]
                            value header[:value]
                          end
                        end
                      end
                    end
                  end
                elsif rule_attrs[:action][:challenge]
                  challenge do
                    if rule_attrs[:action][:challenge][:custom_request_handling]
                      custom_request_handling do
                        rule_attrs[:action][:challenge][:custom_request_handling][:insert_headers].each do |header|
                          insert_header do
                            name header[:name]
                            value header[:value]
                          end
                        end
                      end
                    end
                  end
                end
              end
              
              # Statement configuration - use shared method from web_acl
              statement do
                generate_rule_group_statement_block(rule_attrs[:statement])
              end
              
              # Visibility config
              visibility_config do
                cloudwatch_metrics_enabled rule_attrs[:visibility_config][:cloudwatch_metrics_enabled]
                metric_name rule_attrs[:visibility_config][:metric_name]
                sampled_requests_enabled rule_attrs[:visibility_config][:sampled_requests_enabled]
              end
              
              # Rule labels
              if rule_attrs[:rule_labels]&.any?
                rule_attrs[:rule_labels].each do |label|
                  rule_label do
                    name label[:name]
                  end
                end
              end
              
              # CAPTCHA config
              if rule_attrs[:captcha_config]
                captcha_config do
                  immunity_time_property do
                    immunity_time rule_attrs[:captcha_config][:immunity_time_property][:immunity_time]
                  end
                end
              end
              
              # Challenge config
              if rule_attrs[:challenge_config]
                challenge_config do
                  immunity_time_property do
                    immunity_time rule_attrs[:challenge_config][:immunity_time_property][:immunity_time]
                  end
                end
              end
            end
          end
          
          # Visibility config for the Rule Group
          visibility_config do
            cloudwatch_metrics_enabled rule_group_attrs.visibility_config[:cloudwatch_metrics_enabled]
            metric_name rule_group_attrs.visibility_config[:metric_name]
            sampled_requests_enabled rule_group_attrs.visibility_config[:sampled_requests_enabled]
          end
          
          # Custom response bodies
          rule_group_attrs.custom_response_bodies.each do |key, body|
            custom_response_body do
              key key.to_s
              content body[:content]
              content_type body[:content_type]
            end
          end
          
          # Apply tags if present
          if rule_group_attrs.tags.any?
            tags do
              rule_group_attrs.tags.each do |key, value|
                public_send(key, value)
              end
            end
          end
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_wafv2_rule_group',
          name: name,
          resource_attributes: rule_group_attrs.to_h,
          outputs: {
            id: "${aws_wafv2_rule_group.#{name}.id}",
            arn: "${aws_wafv2_rule_group.#{name}.arn}",
            capacity: "${aws_wafv2_rule_group.#{name}.capacity}",
            lock_token: "${aws_wafv2_rule_group.#{name}.lock_token}"
          },
          computed: {
            total_rule_count: rule_group_attrs.total_rule_count,
            has_rate_limiting: rule_group_attrs.has_rate_limiting?,
            has_geo_blocking: rule_group_attrs.has_geo_blocking?,
            has_string_matching: rule_group_attrs.has_string_matching?,
            has_size_constraints: rule_group_attrs.has_size_constraints?,
            uses_custom_responses: rule_group_attrs.uses_custom_responses?,
            rule_priorities: rule_group_attrs.rule_priorities,
            cloudfront_compatible: rule_group_attrs.cloudfront_compatible?,
            scope: rule_group_attrs.scope,
            capacity: rule_group_attrs.capacity
          }
        )
      end
      
      private
      
      # Generate statement block configuration for rule groups
      def generate_rule_group_statement_block(statement)
        return unless statement
        
        if statement[:byte_match_statement]
          byte_match_statement do
            positional_constraint statement[:byte_match_statement][:positional_constraint]
            search_string statement[:byte_match_statement][:search_string]
            
            field_to_match do
              generate_rule_group_field_to_match_block(statement[:byte_match_statement][:field_to_match])
            end
            
            statement[:byte_match_statement][:text_transformations].each do |transform|
              text_transformation do
                priority transform[:priority]
                type transform[:type]
              end
            end
          end
        elsif statement[:sqli_match_statement]
          sqli_match_statement do
            field_to_match do
              generate_rule_group_field_to_match_block(statement[:sqli_match_statement][:field_to_match])
            end
            
            statement[:sqli_match_statement][:text_transformations].each do |transform|
              text_transformation do
                priority transform[:priority]
                type transform[:type]
              end
            end
          end
        elsif statement[:xss_match_statement]
          xss_match_statement do
            field_to_match do
              generate_rule_group_field_to_match_block(statement[:xss_match_statement][:field_to_match])
            end
            
            statement[:xss_match_statement][:text_transformations].each do |transform|
              text_transformation do
                priority transform[:priority]
                type transform[:type]
              end
            end
          end
        elsif statement[:size_constraint_statement]
          size_constraint_statement do
            comparison_operator statement[:size_constraint_statement][:comparison_operator]
            size statement[:size_constraint_statement][:size]
            
            field_to_match do
              generate_rule_group_field_to_match_block(statement[:size_constraint_statement][:field_to_match])
            end
            
            statement[:size_constraint_statement][:text_transformations].each do |transform|
              text_transformation do
                priority transform[:priority]
                type transform[:type]
              end
            end
          end
        elsif statement[:geo_match_statement]
          geo_match_statement do
            country_codes statement[:geo_match_statement][:country_codes]
            
            if statement[:geo_match_statement][:forwarded_ip_config]
              forwarded_ip_config do
                header_name statement[:geo_match_statement][:forwarded_ip_config][:header_name]
                fallback_behavior statement[:geo_match_statement][:forwarded_ip_config][:fallback_behavior]
              end
            end
          end
        elsif statement[:ip_set_reference_statement]
          ip_set_reference_statement do
            arn statement[:ip_set_reference_statement][:arn]
            
            if statement[:ip_set_reference_statement][:ip_set_forwarded_ip_config]
              ip_set_forwarded_ip_config do
                header_name statement[:ip_set_reference_statement][:ip_set_forwarded_ip_config][:header_name]
                fallback_behavior statement[:ip_set_reference_statement][:ip_set_forwarded_ip_config][:fallback_behavior]
                position statement[:ip_set_reference_statement][:ip_set_forwarded_ip_config][:position]
              end
            end
          end
        elsif statement[:regex_pattern_set_reference_statement]
          regex_pattern_set_reference_statement do
            arn statement[:regex_pattern_set_reference_statement][:arn]
            
            field_to_match do
              generate_rule_group_field_to_match_block(statement[:regex_pattern_set_reference_statement][:field_to_match])
            end
            
            statement[:regex_pattern_set_reference_statement][:text_transformations].each do |transform|
              text_transformation do
                priority transform[:priority]
                type transform[:type]
              end
            end
          end
        elsif statement[:rate_based_statement]
          rate_based_statement do
            limit statement[:rate_based_statement][:limit]
            aggregate_key_type statement[:rate_based_statement][:aggregate_key_type]
            
            if statement[:rate_based_statement][:forwarded_ip_config]
              forwarded_ip_config do
                header_name statement[:rate_based_statement][:forwarded_ip_config][:header_name]
                fallback_behavior statement[:rate_based_statement][:forwarded_ip_config][:fallback_behavior]
              end
            end
            
            if statement[:rate_based_statement][:scope_down_statement]
              scope_down_statement do
                generate_rule_group_statement_block(statement[:rate_based_statement][:scope_down_statement])
              end
            end
          end
        elsif statement[:and_statement]
          and_statement do
            statement[:and_statement][:statements].each do |sub_statement|
              statement do
                generate_rule_group_statement_block(sub_statement)
              end
            end
          end
        elsif statement[:or_statement]
          or_statement do
            statement[:or_statement][:statements].each do |sub_statement|
              statement do
                generate_rule_group_statement_block(sub_statement)
              end
            end
          end
        elsif statement[:not_statement]
          not_statement do
            statement do
              generate_rule_group_statement_block(statement[:not_statement][:statement])
            end
          end
        elsif statement[:label_match_statement]
          label_match_statement do
            scope statement[:label_match_statement][:scope]
            key statement[:label_match_statement][:key]
          end
        end
      end
      
      # Generate field_to_match block configuration for rule groups
      def generate_rule_group_field_to_match_block(field_config)
        return unless field_config
        
        if field_config[:all_query_arguments]
          all_query_arguments
        elsif field_config[:body]
          body do
            if field_config[:body][:oversize_handling]
              oversize_handling field_config[:body][:oversize_handling]
            end
          end
        elsif field_config[:method]
          method
        elsif field_config[:query_string]
          query_string
        elsif field_config[:single_header]
          single_header do
            name field_config[:single_header][:name]
          end
        elsif field_config[:single_query_argument]
          single_query_argument do
            name field_config[:single_query_argument][:name]
          end
        elsif field_config[:uri_path]
          uri_path
        elsif field_config[:json_body]
          json_body do
            match_scope field_config[:json_body][:match_scope]
            
            match_pattern do
              if field_config[:json_body][:match_pattern][:all]
                all
              elsif field_config[:json_body][:match_pattern][:included_paths]
                field_config[:json_body][:match_pattern][:included_paths].each do |path|
                  included_paths path
                end
              end
            end
            
            if field_config[:json_body][:invalid_fallback_behavior]
              invalid_fallback_behavior field_config[:json_body][:invalid_fallback_behavior]
            end
            
            if field_config[:json_body][:oversize_handling]
              oversize_handling field_config[:json_body][:oversize_handling]
            end
          end
        end
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)