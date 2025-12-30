# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

require_relative 'nested_types'

module Pangea
  module Resources
    module AWS
      module Types
        # Type-safe attributes for AWS Cognito User Pool Client resources
        class CognitoUserPoolClientAttributes < Dry::Struct
          attribute :name, Resources::Types::String
          attribute :user_pool_id, Resources::Types::String
          attribute :allowed_oauth_flows, Resources::Types::Array.of(
            Types::String.enum('code', 'implicit', 'client_credentials')
          ).optional
          attribute :allowed_oauth_flows_user_pool_client, Resources::Types::Bool.default(false)
          attribute :allowed_oauth_scopes, Resources::Types::Array.of(Types::String).optional
          attribute :supported_identity_providers, Resources::Types::Array.of(Types::String).optional
          attribute :callback_urls, Resources::Types::Array.of(Types::String).optional
          attribute :logout_urls, Resources::Types::Array.of(Types::String).optional
          attribute :default_redirect_uri, Resources::Types::String.optional
          attribute :generate_secret, Resources::Types::Bool.default(false)
          attribute :enable_token_revocation, Resources::Types::Bool.default(true)
          attribute :enable_propagate_additional_user_context_data, Resources::Types::Bool.default(false)
          attribute :explicit_auth_flows, Resources::Types::Array.of(
            Types::String.enum(
              'ADMIN_NO_SRP_AUTH', 'CUSTOM_AUTH_FLOW_ONLY', 'USER_SRP_AUTH',
              'ALLOW_ADMIN_USER_PASSWORD_AUTH', 'ALLOW_CUSTOM_AUTH', 'ALLOW_USER_PASSWORD_AUTH',
              'ALLOW_USER_SRP_AUTH', 'ALLOW_REFRESH_TOKEN_AUTH'
            )
          ).optional
          attribute :prevent_user_existence_errors, Resources::Types::String.enum('ENABLED', 'LEGACY').optional
          attribute :read_attributes, Resources::Types::Array.of(Types::String).optional
          attribute :write_attributes, Resources::Types::Array.of(Types::String).optional
          attribute :refresh_token_validity, Resources::Types::Integer.optional.constrained(gteq: 1, lteq: 315360000)
          attribute :access_token_validity, Resources::Types::Integer.optional.constrained(gteq: 5, lteq: 86400)
          attribute :id_token_validity, Resources::Types::Integer.optional.constrained(gteq: 5, lteq: 86400)
          attribute? :token_validity_units, CognitoUserPoolClientTokenValidityUnits.optional
          attribute? :analytics_configuration, CognitoUserPoolClientAnalyticsConfiguration.optional
          attribute :auth_session_validity, Resources::Types::Integer.optional.constrained(gteq: 3, lteq: 15)

          def self.new(attributes = {})
            attrs = super(attributes)

            if attrs.allowed_oauth_flows&.any?
              unless attrs.allowed_oauth_flows_user_pool_client
                raise Dry::Struct::Error, "allowed_oauth_flows_user_pool_client must be true when allowed_oauth_flows is specified"
              end

              if attrs.allowed_oauth_flows.include?('implicit') && attrs.callback_urls.nil?
                raise Dry::Struct::Error, "callback_urls are required when using implicit OAuth flow"
              end

              if attrs.allowed_oauth_flows.include?('code') && attrs.callback_urls.nil?
                raise Dry::Struct::Error, "callback_urls are required when using authorization code OAuth flow"
              end
            end

            if attrs.default_redirect_uri && attrs.callback_urls
              unless attrs.callback_urls.include?(attrs.default_redirect_uri)
                raise Dry::Struct::Error, "default_redirect_uri must be included in callback_urls"
              end
            end

            attrs
          end

          def oauth_enabled? = allowed_oauth_flows_user_pool_client && allowed_oauth_flows&.any?
          def public_client? = !generate_secret
          def confidential_client? = generate_secret

          def primary_oauth_flow
            return nil unless allowed_oauth_flows&.any?
            return 'code' if allowed_oauth_flows.include?('code')
            return 'implicit' if allowed_oauth_flows.include?('implicit')
            return 'client_credentials' if allowed_oauth_flows.include?('client_credentials')
            nil
          end

          def srp_auth_enabled?
            explicit_auth_flows&.include?('ALLOW_USER_SRP_AUTH') || explicit_auth_flows&.include?('USER_SRP_AUTH')
          end

          def custom_auth_enabled?
            explicit_auth_flows&.include?('ALLOW_CUSTOM_AUTH') || explicit_auth_flows&.include?('CUSTOM_AUTH_FLOW_ONLY')
          end

          def admin_auth_enabled?
            explicit_auth_flows&.include?('ALLOW_ADMIN_USER_PASSWORD_AUTH') || explicit_auth_flows&.include?('ADMIN_NO_SRP_AUTH')
          end

          def client_type
            if oauth_enabled?
              confidential_client? ? :oauth_confidential : :oauth_public
            else
              confidential_client? ? :native_confidential : :native_public
            end
          end

          def analytics_enabled?
            analytics_configuration&.application_id || analytics_configuration&.application_arn
          end
        end
      end
    end
  end
end
