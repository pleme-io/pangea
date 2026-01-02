# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

require_relative 'actions'
require_relative 'statements'
require_relative 'field_to_match'

module Pangea
  module Resources
    module AWS
      module WafV2RuleGroupDSL
        class DSLBuilder
          include Actions
          include Statements
          include FieldToMatch

          attr_reader :attrs, :dsl

          def initialize(rule_group_attrs, dsl_context)
            @attrs = rule_group_attrs
            @dsl = dsl_context
          end

          def build
            build_basic_config
            build_rules
            build_visibility_config
            build_custom_response_bodies
            build_tags
          end

          private

          def build_basic_config
            dsl.name attrs.name
            dsl.scope attrs.scope.downcase
            dsl.capacity attrs.capacity
            dsl.description attrs.description if attrs.description
          end

          def build_rules
            attrs.rules.each { |rule_attrs| build_rule(rule_attrs) }
          end

          def build_rule(rule_attrs)
            dsl.rule do
              name rule_attrs[:name]
              priority rule_attrs[:priority]
              instance_exec(rule_attrs, &method(:build_action))
              statement { instance_exec(rule_attrs[:statement], &method(:build_statement)) }
              build_visibility_config_block(rule_attrs[:visibility_config])
              build_rule_labels(rule_attrs[:rule_labels])
              build_captcha_config(rule_attrs[:captcha_config])
              build_challenge_config(rule_attrs[:challenge_config])
            end
          end

          def build_visibility_config_block(config)
            visibility_config do
              cloudwatch_metrics_enabled config[:cloudwatch_metrics_enabled]
              metric_name config[:metric_name]
              sampled_requests_enabled config[:sampled_requests_enabled]
            end
          end

          def build_rule_labels(labels)
            labels&.each { |label| rule_label { name label[:name] } }
          end

          def build_captcha_config(config)
            return unless config
            captcha_config { immunity_time_property { immunity_time config[:immunity_time_property][:immunity_time] } }
          end

          def build_challenge_config(config)
            return unless config
            challenge_config { immunity_time_property { immunity_time config[:immunity_time_property][:immunity_time] } }
          end

          def build_visibility_config
            dsl.visibility_config do
              cloudwatch_metrics_enabled attrs.visibility_config[:cloudwatch_metrics_enabled]
              metric_name attrs.visibility_config[:metric_name]
              sampled_requests_enabled attrs.visibility_config[:sampled_requests_enabled]
            end
          end

          def build_custom_response_bodies
            attrs.custom_response_bodies.each do |key, body|
              dsl.custom_response_body do
                self.key key.to_s
                content body[:content]
                content_type body[:content_type]
              end
            end
          end

          def build_tags
            return unless attrs.tags.any?
            dsl.tags { attrs.tags.each { |k, v| public_send(k, v) } }
          end
        end
      end
    end
  end
end
