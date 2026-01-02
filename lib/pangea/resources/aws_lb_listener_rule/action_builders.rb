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
      # Action builders for AWS LB Listener Rule resource
      # Extracts complex nested action building logic for cleaner resource definition
      module LbListenerRuleActionBuilders
        extend self

        def apply_action(ctx, action)
          ctx.action do
            type action[:type]
            order action[:order] if action[:order]

            case action[:type]
            when 'forward' then apply_forward(self, action)
            when 'redirect' then apply_redirect(self, action)
            when 'fixed-response' then apply_fixed_response(self, action)
            when 'authenticate-cognito' then apply_cognito_auth(self, action)
            when 'authenticate-oidc' then apply_oidc_auth(self, action)
            end
          end
        end

        def apply_forward(ctx, action)
          if action[:target_group_arn]
            ctx.target_group_arn action[:target_group_arn]
          elsif action[:forward]
            ctx.forward do
              action[:forward][:target_groups].each do |tg|
                target_group do
                  arn tg[:arn]
                  weight tg[:weight] if tg[:weight] != 100
                end
              end
              apply_stickiness(self, action[:forward][:stickiness]) if action[:forward][:stickiness]
            end
          end
        end

        def apply_stickiness(ctx, stickiness)
          ctx.stickiness do
            enabled stickiness[:enabled]
            duration stickiness[:duration] if stickiness[:duration]
          end
        end

        def apply_redirect(ctx, action)
          ctx.redirect do
            protocol action[:redirect][:protocol] if action[:redirect][:protocol]
            port action[:redirect][:port] if action[:redirect][:port]
            host action[:redirect][:host] if action[:redirect][:host]
            path action[:redirect][:path] if action[:redirect][:path]
            query action[:redirect][:query] if action[:redirect][:query]
            status_code action[:redirect][:status_code]
          end
        end

        def apply_fixed_response(ctx, action)
          ctx.fixed_response do
            content_type action[:fixed_response][:content_type] if action[:fixed_response][:content_type]
            message_body action[:fixed_response][:message_body] if action[:fixed_response][:message_body]
            status_code action[:fixed_response][:status_code]
          end
        end

        def apply_cognito_auth(ctx, action)
          cognito = action[:authenticate_cognito]
          ctx.authenticate_cognito do
            user_pool_arn cognito[:user_pool_arn]
            user_pool_client_id cognito[:user_pool_client_id]
            user_pool_domain cognito[:user_pool_domain]
            apply_auth_extras(self, cognito[:authentication_request_extra_params])
            on_unauthenticated_request cognito[:on_unauthenticated_request] if cognito[:on_unauthenticated_request]
            scope cognito[:scope] if cognito[:scope]
            session_cookie_name cognito[:session_cookie_name] if cognito[:session_cookie_name]
            session_timeout cognito[:session_timeout] if cognito[:session_timeout]
          end
        end

        def apply_oidc_auth(ctx, action)
          oidc = action[:authenticate_oidc]
          ctx.authenticate_oidc do
            authorization_endpoint oidc[:authorization_endpoint]
            client_id oidc[:client_id]
            client_secret oidc[:client_secret]
            issuer oidc[:issuer]
            token_endpoint oidc[:token_endpoint]
            user_info_endpoint oidc[:user_info_endpoint]
            apply_auth_extras(self, oidc[:authentication_request_extra_params])
            on_unauthenticated_request oidc[:on_unauthenticated_request] if oidc[:on_unauthenticated_request]
            scope oidc[:scope] if oidc[:scope]
            session_cookie_name oidc[:session_cookie_name] if oidc[:session_cookie_name]
            session_timeout oidc[:session_timeout] if oidc[:session_timeout]
          end
        end

        def apply_auth_extras(ctx, params)
          return unless params

          ctx.authentication_request_extra_params do
            params.each { |key, value| public_send(key, value) }
          end
        end
      end
    end
  end
end
