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
      module WafV2WebAcl
        class DSLBuilder
          # Rule building methods
          module Rules
            def build_rules(ctx)
              attrs.rules.each { |rule_attrs| build_single_rule(ctx, rule_attrs) }
            end

            def build_single_rule(ctx, rule_attrs)
              builder = self
              ctx.rule do
                name rule_attrs.name
                priority rule_attrs.priority
                builder.build_rule_action(self, rule_attrs.action)
                statement { builder.build_statement(self, rule_attrs.statement) }
                builder.build_visibility_config(self, rule_attrs.visibility_config)
                builder.build_rule_labels(self, rule_attrs.rule_labels)
                builder.build_captcha_config(self, rule_attrs.captcha_config)
                builder.build_challenge_config(self, rule_attrs.challenge_config)
              end
            end

            def build_rule_action(ctx, action)
              builder = self
              ctx.action do
                if action.allow
                  allow { builder.build_custom_request_handling(self, action.allow[:custom_request_handling]) }
                elsif action.block
                  block { builder.build_custom_response(self, action.block[:custom_response]) }
                elsif action.count
                  count { builder.build_custom_request_handling(self, action.count[:custom_request_handling]) }
                elsif action.captcha
                  captcha { builder.build_custom_request_handling(self, action.captcha[:custom_request_handling]) }
                elsif action.challenge
                  challenge { builder.build_custom_request_handling(self, action.challenge[:custom_request_handling]) }
                end
              end
            end

            def build_visibility_config(ctx, config)
              ctx.visibility_config do
                cloudwatch_metrics_enabled config.cloudwatch_metrics_enabled
                metric_name config.metric_name
                sampled_requests_enabled config.sampled_requests_enabled
              end
            end

            def build_rule_labels(ctx, labels)
              return unless labels.any?

              labels.each { |label| ctx.rule_label { name label[:name] } }
            end

            def build_captcha_config(ctx, config)
              return unless config

              ctx.captcha_config { immunity_time_property { immunity_time config[:immunity_time_property][:immunity_time] } }
            end

            def build_challenge_config(ctx, config)
              return unless config

              ctx.challenge_config { immunity_time_property { immunity_time config[:immunity_time_property][:immunity_time] } }
            end
          end
        end
      end
    end
  end
end
