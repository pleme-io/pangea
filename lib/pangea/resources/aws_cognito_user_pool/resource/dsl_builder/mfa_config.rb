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
          # MFA configuration building methods
          module MfaConfig
            def build_mfa_config(ctx)
              ctx.mfa_configuration attrs.mfa_configuration
              ctx.sms_authentication_message attrs.sms_authentication_message if attrs.sms_authentication_message

              build_sms_configuration(ctx)
              build_software_token_mfa(ctx)
            end

            private

            def build_sms_configuration(ctx)
              return unless attrs.sms_configuration

              config = attrs.sms_configuration
              ctx.sms_configuration do
                external_id config.external_id
                sns_caller_arn config.sns_caller_arn
                sns_region config.sns_region if config.sns_region
              end
            end

            def build_software_token_mfa(ctx)
              return unless attrs.software_token_mfa_configuration

              ctx.software_token_mfa_configuration do
                enabled attrs.software_token_mfa_configuration[:enabled]
              end
            end
          end
        end
      end
    end
  end
end
