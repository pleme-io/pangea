# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

module Pangea
  module Resources
    module AWS
      module Types
        # Pre-configured client templates for common scenarios
        module UserPoolClientTemplates
          def self.web_app_client(client_name, user_pool_id, callback_urls, logout_urls = [])
            {
              name: client_name, user_pool_id: user_pool_id, generate_secret: false,
              allowed_oauth_flows: ['code'], allowed_oauth_flows_user_pool_client: true,
              allowed_oauth_scopes: ['phone', 'email', 'openid', 'profile'],
              callback_urls: callback_urls, logout_urls: logout_urls,
              supported_identity_providers: ['COGNITO'], prevent_user_existence_errors: 'ENABLED',
              explicit_auth_flows: ['ALLOW_USER_SRP_AUTH', 'ALLOW_REFRESH_TOKEN_AUTH']
            }
          end

          def self.mobile_app_client(client_name, user_pool_id)
            {
              name: client_name, user_pool_id: user_pool_id, generate_secret: false,
              prevent_user_existence_errors: 'ENABLED',
              explicit_auth_flows: ['ALLOW_USER_SRP_AUTH', 'ALLOW_REFRESH_TOKEN_AUTH', 'ALLOW_USER_PASSWORD_AUTH'],
              access_token_validity: 60, id_token_validity: 60, refresh_token_validity: 30,
              token_validity_units: { access_token: 'minutes', id_token: 'minutes', refresh_token: 'days' }
            }
          end

          def self.machine_to_machine_client(client_name, user_pool_id, scopes = [])
            {
              name: client_name, user_pool_id: user_pool_id, generate_secret: true,
              allowed_oauth_flows: ['client_credentials'], allowed_oauth_flows_user_pool_client: true,
              allowed_oauth_scopes: scopes.any? ? scopes : ['email', 'profile'],
              supported_identity_providers: ['COGNITO'], prevent_user_existence_errors: 'ENABLED',
              explicit_auth_flows: ['ALLOW_REFRESH_TOKEN_AUTH'],
              access_token_validity: 12, refresh_token_validity: 7,
              token_validity_units: { access_token: 'hours', refresh_token: 'days' }
            }
          end

          def self.spa_client(client_name, user_pool_id, callback_urls, logout_urls = [])
            {
              name: client_name, user_pool_id: user_pool_id, generate_secret: false,
              allowed_oauth_flows: ['code'], allowed_oauth_flows_user_pool_client: true,
              allowed_oauth_scopes: ['phone', 'email', 'openid', 'profile'],
              callback_urls: callback_urls, logout_urls: logout_urls,
              supported_identity_providers: ['COGNITO'], prevent_user_existence_errors: 'ENABLED',
              explicit_auth_flows: ['ALLOW_USER_SRP_AUTH', 'ALLOW_REFRESH_TOKEN_AUTH'],
              access_token_validity: 30, id_token_validity: 30, refresh_token_validity: 1,
              token_validity_units: { access_token: 'minutes', id_token: 'minutes', refresh_token: 'days' }
            }
          end

          def self.admin_client(client_name, user_pool_id, callback_urls, logout_urls = [])
            {
              name: client_name, user_pool_id: user_pool_id, generate_secret: true,
              allowed_oauth_flows: ['code'], allowed_oauth_flows_user_pool_client: true,
              allowed_oauth_scopes: ['phone', 'email', 'openid', 'profile', 'aws.cognito.signin.user.admin'],
              callback_urls: callback_urls, logout_urls: logout_urls,
              supported_identity_providers: ['COGNITO'], prevent_user_existence_errors: 'ENABLED',
              explicit_auth_flows: ['ALLOW_USER_SRP_AUTH', 'ALLOW_ADMIN_USER_PASSWORD_AUTH', 'ALLOW_REFRESH_TOKEN_AUTH'],
              access_token_validity: 8, id_token_validity: 8, refresh_token_validity: 30,
              token_validity_units: { access_token: 'hours', id_token: 'hours', refresh_token: 'days' }
            }
          end

          def self.development_client(client_name, user_pool_id)
            {
              name: client_name, user_pool_id: user_pool_id, generate_secret: false,
              allowed_oauth_flows: ['code', 'implicit'], allowed_oauth_flows_user_pool_client: true,
              allowed_oauth_scopes: ['phone', 'email', 'openid', 'profile', 'aws.cognito.signin.user.admin'],
              callback_urls: ['http://localhost:3000/callback', 'http://localhost:8080/callback', 'https://oauth.pstmn.io/v1/callback'],
              logout_urls: ['http://localhost:3000/', 'http://localhost:8080/'],
              supported_identity_providers: ['COGNITO'],
              explicit_auth_flows: ['ALLOW_USER_SRP_AUTH', 'ALLOW_USER_PASSWORD_AUTH', 'ALLOW_ADMIN_USER_PASSWORD_AUTH', 'ALLOW_CUSTOM_AUTH', 'ALLOW_REFRESH_TOKEN_AUTH']
            }
          end
        end
      end
    end
  end
end
