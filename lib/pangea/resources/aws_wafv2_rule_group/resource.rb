# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/aws_wafv2_rule_group/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      def aws_wafv2_rule_group(name, attributes = {})
        rule_group_attrs = Types::WafV2RuleGroupAttributes.new(attributes)

        resource(:aws_wafv2_rule_group, name) do
          name rule_group_attrs.name
          scope rule_group_attrs.scope.downcase
          capacity rule_group_attrs.capacity
          description rule_group_attrs.description if rule_group_attrs.description

          rule_group_attrs.rules.each do |rule_attrs|
            rule do
              name rule_attrs[:name]
              priority rule_attrs[:priority]
              action { generate_rule_group_action(rule_attrs[:action]) }
              statement { generate_rule_group_statement_block(rule_attrs[:statement]) }
              visibility_config do
                cloudwatch_metrics_enabled rule_attrs[:visibility_config][:cloudwatch_metrics_enabled]
                metric_name rule_attrs[:visibility_config][:metric_name]
                sampled_requests_enabled rule_attrs[:visibility_config][:sampled_requests_enabled]
              end
              rule_attrs[:rule_labels]&.each { |label| rule_label { name label[:name] } }
              captcha_config { immunity_time_property { immunity_time rule_attrs[:captcha_config][:immunity_time_property][:immunity_time] } } if rule_attrs[:captcha_config]
              challenge_config { immunity_time_property { immunity_time rule_attrs[:challenge_config][:immunity_time_property][:immunity_time] } } if rule_attrs[:challenge_config]
            end
          end

          visibility_config do
            cloudwatch_metrics_enabled rule_group_attrs.visibility_config[:cloudwatch_metrics_enabled]
            metric_name rule_group_attrs.visibility_config[:metric_name]
            sampled_requests_enabled rule_group_attrs.visibility_config[:sampled_requests_enabled]
          end

          rule_group_attrs.custom_response_bodies.each do |key, body|
            custom_response_body { self.key key.to_s; content body[:content]; content_type body[:content_type] }
          end

          tags { rule_group_attrs.tags.each { |k, v| public_send(k, v) } } if rule_group_attrs.tags.any?
        end

        ResourceReference.new(
          type: 'aws_wafv2_rule_group', name: name, resource_attributes: rule_group_attrs.to_h,
          outputs: { id: "${aws_wafv2_rule_group.#{name}.id}", arn: "${aws_wafv2_rule_group.#{name}.arn}",
                     capacity: "${aws_wafv2_rule_group.#{name}.capacity}", lock_token: "${aws_wafv2_rule_group.#{name}.lock_token}" },
          computed: { total_rule_count: rule_group_attrs.total_rule_count, has_rate_limiting: rule_group_attrs.has_rate_limiting?,
                      has_geo_blocking: rule_group_attrs.has_geo_blocking?, has_string_matching: rule_group_attrs.has_string_matching?,
                      has_size_constraints: rule_group_attrs.has_size_constraints?, uses_custom_responses: rule_group_attrs.uses_custom_responses?,
                      rule_priorities: rule_group_attrs.rule_priorities, cloudfront_compatible: rule_group_attrs.cloudfront_compatible?,
                      scope: rule_group_attrs.scope, capacity: rule_group_attrs.capacity }
        )
      end

      private

      def generate_rule_group_action(action_config)
        if action_config[:allow]
          allow { build_custom_request_handling(action_config[:allow][:custom_request_handling]) if action_config[:allow][:custom_request_handling] }
        elsif action_config[:block]
          block { build_custom_response(action_config[:block][:custom_response]) if action_config[:block][:custom_response] }
        elsif action_config[:count]
          count { build_custom_request_handling(action_config[:count][:custom_request_handling]) if action_config[:count][:custom_request_handling] }
        elsif action_config[:captcha]
          captcha { build_custom_request_handling(action_config[:captcha][:custom_request_handling]) if action_config[:captcha][:custom_request_handling] }
        elsif action_config[:challenge]
          challenge { build_custom_request_handling(action_config[:challenge][:custom_request_handling]) if action_config[:challenge][:custom_request_handling] }
        end
      end

      def build_custom_request_handling(config)
        return unless config
        custom_request_handling { config[:insert_headers].each { |h| insert_header { name h[:name]; value h[:value] } } }
      end

      def build_custom_response(config)
        return unless config
        custom_response do
          response_code config[:response_code]
          custom_response_body_key config[:custom_response_body_key] if config[:custom_response_body_key]
          config[:response_headers]&.each { |h| response_header { name h[:name]; value h[:value] } }
        end
      end

      def generate_rule_group_statement_block(stmt)
        return unless stmt
        if stmt[:byte_match_statement] then byte_match_statement { build_byte_match(stmt[:byte_match_statement]) }
        elsif stmt[:sqli_match_statement] then sqli_match_statement { build_match_with_transforms(stmt[:sqli_match_statement]) }
        elsif stmt[:xss_match_statement] then xss_match_statement { build_match_with_transforms(stmt[:xss_match_statement]) }
        elsif stmt[:size_constraint_statement] then size_constraint_statement { build_size_constraint(stmt[:size_constraint_statement]) }
        elsif stmt[:geo_match_statement] then geo_match_statement { build_geo_match(stmt[:geo_match_statement]) }
        elsif stmt[:ip_set_reference_statement] then ip_set_reference_statement { build_ip_set_ref(stmt[:ip_set_reference_statement]) }
        elsif stmt[:regex_pattern_set_reference_statement] then regex_pattern_set_reference_statement { build_regex_ref(stmt[:regex_pattern_set_reference_statement]) }
        elsif stmt[:rate_based_statement] then rate_based_statement { build_rate_based(stmt[:rate_based_statement]) }
        elsif stmt[:and_statement] then and_statement { stmt[:and_statement][:statements].each { |s| statement { generate_rule_group_statement_block(s) } } }
        elsif stmt[:or_statement] then or_statement { stmt[:or_statement][:statements].each { |s| statement { generate_rule_group_statement_block(s) } } }
        elsif stmt[:not_statement] then not_statement { statement { generate_rule_group_statement_block(stmt[:not_statement][:statement]) } }
        elsif stmt[:label_match_statement] then label_match_statement { scope stmt[:label_match_statement][:scope]; key stmt[:label_match_statement][:key] }
        end
      end

      def build_byte_match(c)
        positional_constraint c[:positional_constraint]; search_string c[:search_string]
        field_to_match { generate_rule_group_field_to_match_block(c[:field_to_match]) }
        c[:text_transformations].each { |t| text_transformation { priority t[:priority]; type t[:type] } }
      end

      def build_match_with_transforms(c)
        field_to_match { generate_rule_group_field_to_match_block(c[:field_to_match]) }
        c[:text_transformations].each { |t| text_transformation { priority t[:priority]; type t[:type] } }
      end

      def build_size_constraint(c)
        comparison_operator c[:comparison_operator]; size c[:size]
        field_to_match { generate_rule_group_field_to_match_block(c[:field_to_match]) }
        c[:text_transformations].each { |t| text_transformation { priority t[:priority]; type t[:type] } }
      end

      def build_geo_match(c)
        country_codes c[:country_codes]
        forwarded_ip_config { header_name c[:forwarded_ip_config][:header_name]; fallback_behavior c[:forwarded_ip_config][:fallback_behavior] } if c[:forwarded_ip_config]
      end

      def build_ip_set_ref(c)
        arn c[:arn]
        if c[:ip_set_forwarded_ip_config]
          ip_set_forwarded_ip_config { header_name c[:ip_set_forwarded_ip_config][:header_name]; fallback_behavior c[:ip_set_forwarded_ip_config][:fallback_behavior]; position c[:ip_set_forwarded_ip_config][:position] }
        end
      end

      def build_regex_ref(c)
        arn c[:arn]
        field_to_match { generate_rule_group_field_to_match_block(c[:field_to_match]) }
        c[:text_transformations].each { |t| text_transformation { priority t[:priority]; type t[:type] } }
      end

      def build_rate_based(c)
        limit c[:limit]; aggregate_key_type c[:aggregate_key_type]
        forwarded_ip_config { header_name c[:forwarded_ip_config][:header_name]; fallback_behavior c[:forwarded_ip_config][:fallback_behavior] } if c[:forwarded_ip_config]
        scope_down_statement { generate_rule_group_statement_block(c[:scope_down_statement]) } if c[:scope_down_statement]
      end

      def generate_rule_group_field_to_match_block(f)
        return unless f
        if f[:all_query_arguments] then all_query_arguments
        elsif f[:body] then body { oversize_handling f[:body][:oversize_handling] if f[:body][:oversize_handling] }
        elsif f[:method] then method
        elsif f[:query_string] then query_string
        elsif f[:single_header] then single_header { name f[:single_header][:name] }
        elsif f[:single_query_argument] then single_query_argument { name f[:single_query_argument][:name] }
        elsif f[:uri_path] then uri_path
        elsif f[:json_body] then json_body { build_json_body(f[:json_body]) }
        end
      end

      def build_json_body(c)
        match_scope c[:match_scope]
        match_pattern { c[:match_pattern][:all] ? all : c[:match_pattern][:included_paths]&.each { |p| included_paths p } }
        invalid_fallback_behavior c[:invalid_fallback_behavior] if c[:invalid_fallback_behavior]
        oversize_handling c[:oversize_handling] if c[:oversize_handling]
      end
    end
  end
end

Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)
