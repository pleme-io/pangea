# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

module Pangea
  module Resources
    module AWS
      module WafV2RuleGroupDSL
        module Actions
          def build_action(rule_attrs)
            action do
              if rule_attrs[:action][:allow]
                build_allow_action(rule_attrs[:action][:allow])
              elsif rule_attrs[:action][:block]
                build_block_action(rule_attrs[:action][:block])
              elsif rule_attrs[:action][:count]
                build_count_action(rule_attrs[:action][:count])
              elsif rule_attrs[:action][:captcha]
                build_captcha_action(rule_attrs[:action][:captcha])
              elsif rule_attrs[:action][:challenge]
                build_challenge_action(rule_attrs[:action][:challenge])
              end
            end
          end

          def build_allow_action(allow_config)
            allow do
              build_custom_request_handling(allow_config[:custom_request_handling]) if allow_config[:custom_request_handling]
            end
          end

          def build_block_action(block_config)
            block do
              build_custom_response(block_config[:custom_response]) if block_config[:custom_response]
            end
          end

          def build_count_action(count_config)
            count do
              build_custom_request_handling(count_config[:custom_request_handling]) if count_config[:custom_request_handling]
            end
          end

          def build_captcha_action(captcha_config)
            captcha do
              build_custom_request_handling(captcha_config[:custom_request_handling]) if captcha_config[:custom_request_handling]
            end
          end

          def build_challenge_action(challenge_config)
            challenge do
              build_custom_request_handling(challenge_config[:custom_request_handling]) if challenge_config[:custom_request_handling]
            end
          end

          def build_custom_request_handling(config)
            custom_request_handling do
              config[:insert_headers].each do |header|
                insert_header do
                  name header[:name]
                  value header[:value]
                end
              end
            end
          end

          def build_custom_response(config)
            custom_response do
              response_code config[:response_code]
              custom_response_body_key config[:custom_response_body_key] if config[:custom_response_body_key]
              config[:response_headers]&.each do |header|
                response_header do
                  name header[:name]
                  value header[:value]
                end
              end
            end
          end
        end
      end
    end
  end
end
