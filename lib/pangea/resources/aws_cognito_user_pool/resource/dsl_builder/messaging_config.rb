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
      module CognitoUserPool
        class DSLBuilder
          # Email and Lambda configuration building methods
          module MessagingConfig
            def build_email_config(ctx)
              build_email_configuration(ctx)
              build_verification_messages(ctx)
            end

            def build_lambda_config(ctx)
              return unless attrs.lambda_config

              config = attrs.lambda_config
              ctx.lambda_config do
                create_auth_challenge config.create_auth_challenge if config.create_auth_challenge
                custom_message config.custom_message if config.custom_message
                define_auth_challenge config.define_auth_challenge if config.define_auth_challenge
                post_authentication config.post_authentication if config.post_authentication
                post_confirmation config.post_confirmation if config.post_confirmation
                pre_authentication config.pre_authentication if config.pre_authentication
                pre_sign_up config.pre_sign_up if config.pre_sign_up
                pre_token_generation config.pre_token_generation if config.pre_token_generation
                user_migration config.user_migration if config.user_migration
                verify_auth_challenge_response config.verify_auth_challenge_response if config.verify_auth_challenge_response
                kms_key_id config.kms_key_id if config.kms_key_id
              end
            end

            private

            def build_email_configuration(ctx)
              return unless attrs.email_configuration

              config = attrs.email_configuration
              ctx.email_configuration do
                configuration_set config.configuration_set if config.configuration_set
                email_sending_account config.email_sending_account
                from_email_address config.from_email_address if config.from_email_address
                reply_to_email_address config.reply_to_email_address if config.reply_to_email_address
                source_arn config.source_arn if config.source_arn
              end
            end

            def build_verification_messages(ctx)
              ctx.email_verification_message attrs.email_verification_message if attrs.email_verification_message
              ctx.email_verification_subject attrs.email_verification_subject if attrs.email_verification_subject
              ctx.sms_verification_message attrs.sms_verification_message if attrs.sms_verification_message
            end
          end
        end
      end
    end
  end
end
