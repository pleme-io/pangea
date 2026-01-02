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
          # Authentication configuration building methods
          module AuthenticationConfig
            def build_username_config(ctx)
              ctx.alias_attributes attrs.alias_attributes if attrs.alias_attributes
              ctx.username_attributes attrs.username_attributes if attrs.username_attributes

              return unless attrs.username_configuration

              ctx.username_configuration do
                case_sensitive attrs.username_configuration[:case_sensitive]
              end
            end

            def build_password_policy(ctx)
              return unless attrs.password_policy

              policy = attrs.password_policy
              ctx.password_policy do
                minimum_length policy.minimum_length
                require_lowercase policy.require_lowercase if policy.require_lowercase
                require_numbers policy.require_numbers if policy.require_numbers
                require_symbols policy.require_symbols if policy.require_symbols
                require_uppercase policy.require_uppercase if policy.require_uppercase
                temporary_password_validity_days policy.temporary_password_validity_days if policy.temporary_password_validity_days
              end
            end

            def build_device_configuration(ctx)
              return unless attrs.device_configuration

              config = attrs.device_configuration
              ctx.device_configuration do
                challenge_required_on_new_device config.challenge_required_on_new_device if config.challenge_required_on_new_device
                device_only_remembered_on_user_prompt config.device_only_remembered_on_user_prompt if config.device_only_remembered_on_user_prompt
              end
            end
          end
        end
      end
    end
  end
end
