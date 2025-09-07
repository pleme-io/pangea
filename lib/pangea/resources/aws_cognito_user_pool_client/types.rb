# frozen_string_literal: true

require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
      # Token validity units configuration
      class CognitoUserPoolClientTokenValidityUnits < Dry::Struct
        attribute :access_token, Resources::Types::String.enum('seconds', 'minutes', 'hours', 'days').default('hours')
        attribute :id_token, Resources::Types::String.enum('seconds', 'minutes', 'hours', 'days').default('hours') 
        attribute :refresh_token, Resources::Types::String.enum('seconds', 'minutes', 'hours', 'days').default('days')
      end

      # Analytics configuration for user pool client
      class CognitoUserPoolClientAnalyticsConfiguration < Dry::Struct
        attribute :application_arn, Resources::Types::String.optional
        attribute :application_id, Resources::Types::String.optional
        attribute :external_id, Resources::Types::String.optional
        attribute :role_arn, Resources::Types::String.optional
        attribute :user_data_shared, Resources::Types::Bool.optional
      end

      # Type-safe attributes for AWS Cognito User Pool Client resources
      class CognitoUserPoolClientAttributes < Dry::Struct
        # Client name (required)
        attribute :name, Resources::Types::String

        # User pool ID (required)  
        attribute :user_pool_id, Resources::Types::String

        # OAuth 2.0 grant types
        attribute :allowed_oauth_flows, Resources::Types::Array.of(
          Types::String.enum('code', 'implicit', 'client_credentials')
        ).optional

        # Whether OAuth flows are enabled
        attribute :allowed_oauth_flows_user_pool_client, Resources::Types::Bool.default(false)

        # OAuth 2.0 scopes
        attribute :allowed_oauth_scopes, Resources::Types::Array.of(Types::String).optional

        # Supported identity providers
        attribute :supported_identity_providers, Resources::Types::Array.of(Types::String).optional

        # Callback URLs for OAuth flows
        attribute :callback_urls, Resources::Types::Array.of(Types::String).optional

        # Logout URLs for OAuth flows  
        attribute :logout_urls, Resources::Types::Array.of(Types::String).optional

        # Default redirect URI
        attribute :default_redirect_uri, Resources::Types::String.optional

        # Whether to generate a client secret
        attribute :generate_secret, Resources::Types::Bool.default(false)

        # Whether to enable SRP (Secure Remote Password) authentication
        attribute :enable_token_revocation, Resources::Types::Bool.default(true)

        # Whether to enable Pinpoint analytics
        attribute :enable_propagate_additional_user_context_data, Resources::Types::Bool.default(false)

        # Explicit auth flows
        attribute :explicit_auth_flows, Resources::Types::Array.of(
          Types::String.enum(
            'ADMIN_NO_SRP_AUTH',
            'CUSTOM_AUTH_FLOW_ONLY', 
            'USER_SRP_AUTH',
            'ALLOW_ADMIN_USER_PASSWORD_AUTH',
            'ALLOW_CUSTOM_AUTH',
            'ALLOW_USER_PASSWORD_AUTH',
            'ALLOW_USER_SRP_AUTH', 
            'ALLOW_REFRESH_TOKEN_AUTH'
          )
        ).optional

        # Prevent user existence errors for security
        attribute :prevent_user_existence_errors, Resources::Types::String.enum('ENABLED', 'LEGACY').optional

        # Read attributes that the client can read  
        attribute :read_attributes, Resources::Types::Array.of(Types::String).optional

        # Write attributes that the client can write
        attribute :write_attributes, Resources::Types::Array.of(Types::String).optional

        # Refresh token validity period (in days)
        attribute :refresh_token_validity, Resources::Types::Integer.optional.constrained(gteq: 1, lteq: 315360000)

        # Access token validity period  
        attribute :access_token_validity, Resources::Types::Integer.optional.constrained(gteq: 5, lteq: 86400)

        # ID token validity period
        attribute :id_token_validity, Resources::Types::Integer.optional.constrained(gteq: 5, lteq: 86400)

        # Token validity units
        attribute? :token_validity_units, CognitoUserPoolClientTokenValidityUnits.optional

        # Analytics configuration
        attribute? :analytics_configuration, CognitoUserPoolClientAnalyticsConfiguration.optional

        # Auth session validity (in minutes)
        attribute :auth_session_validity, Resources::Types::Integer.optional.constrained(gteq: 3, lteq: 15)

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)

          # OAuth flows validation
          if attrs.allowed_oauth_flows&.any?
            if !attrs.allowed_oauth_flows_user_pool_client
              raise Dry::Struct::Error, "allowed_oauth_flows_user_pool_client must be true when allowed_oauth_flows is specified"
            end

            # Implicit flow requires callback URLs
            if attrs.allowed_oauth_flows.include?('implicit') && attrs.callback_urls.nil?
              raise Dry::Struct::Error, "callback_urls are required when using implicit OAuth flow"
            end

            # Authorization code flow requires callback URLs
            if attrs.allowed_oauth_flows.include?('code') && attrs.callback_urls.nil?
              raise Dry::Struct::Error, "callback_urls are required when using authorization code OAuth flow"
            end
          end

          # Default redirect URI must be in callback URLs
          if attrs.default_redirect_uri && attrs.callback_urls
            unless attrs.callback_urls.include?(attrs.default_redirect_uri)
              raise Dry::Struct::Error, "default_redirect_uri must be included in callback_urls"
            end
          end

          # Validate explicit auth flows combinations
          if attrs.explicit_auth_flows
            # Check for deprecated flows
            deprecated_flows = ['ADMIN_NO_SRP_AUTH', 'CUSTOM_AUTH_FLOW_ONLY', 'USER_SRP_AUTH']
            if (attrs.explicit_auth_flows & deprecated_flows).any?
              # Should have corresponding ALLOW_ flows
              modern_equivalent = {
                'ADMIN_NO_SRP_AUTH' => 'ALLOW_ADMIN_USER_PASSWORD_AUTH',
                'CUSTOM_AUTH_FLOW_ONLY' => 'ALLOW_CUSTOM_AUTH',
                'USER_SRP_AUTH' => 'ALLOW_USER_SRP_AUTH'
              }
            end
          end

          attrs
        end

        # Check if client supports OAuth flows
        def oauth_enabled?
          allowed_oauth_flows_user_pool_client && allowed_oauth_flows&.any?
        end

        # Check if client is a public client (no secret)
        def public_client?
          !generate_secret
        end

        # Check if client is a confidential client (has secret)
        def confidential_client?
          generate_secret
        end

        # Get primary OAuth flow
        def primary_oauth_flow
          return nil unless allowed_oauth_flows&.any?
          
          # Prefer authorization code over implicit for security
          return 'code' if allowed_oauth_flows.include?('code')
          return 'implicit' if allowed_oauth_flows.include?('implicit')
          return 'client_credentials' if allowed_oauth_flows.include?('client_credentials')
          nil
        end

        # Check if SRP authentication is enabled
        def srp_auth_enabled?
          explicit_auth_flows&.include?('ALLOW_USER_SRP_AUTH') || 
          explicit_auth_flows&.include?('USER_SRP_AUTH')
        end

        # Check if custom authentication is enabled  
        def custom_auth_enabled?
          explicit_auth_flows&.include?('ALLOW_CUSTOM_AUTH') ||
          explicit_auth_flows&.include?('CUSTOM_AUTH_FLOW_ONLY')
        end

        # Check if admin authentication is enabled
        def admin_auth_enabled?
          explicit_auth_flows&.include?('ALLOW_ADMIN_USER_PASSWORD_AUTH') ||
          explicit_auth_flows&.include?('ADMIN_NO_SRP_AUTH')
        end

        # Get client type description
        def client_type
          if oauth_enabled?
            if confidential_client?
              :oauth_confidential
            else
              :oauth_public  
            end
          else
            if confidential_client?
              :native_confidential
            else
              :native_public
            end
          end
        end

        # Check if analytics is configured
        def analytics_enabled?
          analytics_configuration&.application_id || analytics_configuration&.application_arn
        end
      end

      # Pre-configured client templates for common scenarios
      module UserPoolClientTemplates
        # Web application client (OAuth authorization code flow)
        def self.web_app_client(client_name, user_pool_id, callback_urls, logout_urls = [])
          {
            name: client_name,
            user_pool_id: user_pool_id,
            generate_secret: false,
            allowed_oauth_flows: ['code'],
            allowed_oauth_flows_user_pool_client: true,
            allowed_oauth_scopes: ['phone', 'email', 'openid', 'profile'],
            callback_urls: callback_urls,
            logout_urls: logout_urls,
            supported_identity_providers: ['COGNITO'],
            prevent_user_existence_errors: 'ENABLED',
            explicit_auth_flows: [
              'ALLOW_USER_SRP_AUTH',
              'ALLOW_REFRESH_TOKEN_AUTH'
            ]
          }
        end

        # Mobile application client (native app)
        def self.mobile_app_client(client_name, user_pool_id)
          {
            name: client_name,
            user_pool_id: user_pool_id,
            generate_secret: false,  # Public client for mobile
            prevent_user_existence_errors: 'ENABLED',
            explicit_auth_flows: [
              'ALLOW_USER_SRP_AUTH',
              'ALLOW_REFRESH_TOKEN_AUTH',
              'ALLOW_USER_PASSWORD_AUTH'  # For mobile convenience
            ],
            # Shorter token validity for mobile security
            access_token_validity: 60,   # 1 hour
            id_token_validity: 60,       # 1 hour
            refresh_token_validity: 30,  # 30 days
            token_validity_units: {
              access_token: 'minutes',
              id_token: 'minutes', 
              refresh_token: 'days'
            }
          }
        end

        # Server-to-server client (machine-to-machine)
        def self.machine_to_machine_client(client_name, user_pool_id, scopes = [])
          {
            name: client_name,
            user_pool_id: user_pool_id,
            generate_secret: true,  # Confidential client
            allowed_oauth_flows: ['client_credentials'],
            allowed_oauth_flows_user_pool_client: true,
            allowed_oauth_scopes: scopes.any? ? scopes : ['email', 'profile'],
            supported_identity_providers: ['COGNITO'],
            prevent_user_existence_errors: 'ENABLED',
            explicit_auth_flows: [
              'ALLOW_REFRESH_TOKEN_AUTH'
            ],
            # Longer validity for server applications
            access_token_validity: 12,   # 12 hours
            refresh_token_validity: 7,   # 7 days
            token_validity_units: {
              access_token: 'hours',
              refresh_token: 'days'
            }
          }
        end

        # Single Page Application client (SPA)
        def self.spa_client(client_name, user_pool_id, callback_urls, logout_urls = [])
          {
            name: client_name,
            user_pool_id: user_pool_id,
            generate_secret: false,  # Public client for SPA
            allowed_oauth_flows: ['code'],  # Use authorization code with PKCE
            allowed_oauth_flows_user_pool_client: true,
            allowed_oauth_scopes: ['phone', 'email', 'openid', 'profile'],
            callback_urls: callback_urls,
            logout_urls: logout_urls,
            supported_identity_providers: ['COGNITO'],
            prevent_user_existence_errors: 'ENABLED',
            explicit_auth_flows: [
              'ALLOW_USER_SRP_AUTH',
              'ALLOW_REFRESH_TOKEN_AUTH'
            ],
            # Short-lived tokens for SPA security
            access_token_validity: 30,   # 30 minutes
            id_token_validity: 30,       # 30 minutes  
            refresh_token_validity: 1,   # 1 day
            token_validity_units: {
              access_token: 'minutes',
              id_token: 'minutes',
              refresh_token: 'days'
            }
          }
        end

        # Admin/dashboard client with elevated permissions
        def self.admin_client(client_name, user_pool_id, callback_urls, logout_urls = [])
          {
            name: client_name,
            user_pool_id: user_pool_id,
            generate_secret: true,  # Confidential client for admin access
            allowed_oauth_flows: ['code'],
            allowed_oauth_flows_user_pool_client: true,
            allowed_oauth_scopes: ['phone', 'email', 'openid', 'profile', 'aws.cognito.signin.user.admin'],
            callback_urls: callback_urls,
            logout_urls: logout_urls,
            supported_identity_providers: ['COGNITO'],
            prevent_user_existence_errors: 'ENABLED',
            explicit_auth_flows: [
              'ALLOW_USER_SRP_AUTH',
              'ALLOW_ADMIN_USER_PASSWORD_AUTH',
              'ALLOW_REFRESH_TOKEN_AUTH'
            ],
            # Standard token validity for admin apps
            access_token_validity: 8,    # 8 hours
            id_token_validity: 8,        # 8 hours
            refresh_token_validity: 30,  # 30 days
            token_validity_units: {
              access_token: 'hours',
              id_token: 'hours',
              refresh_token: 'days'
            }
          }
        end

        # Development/testing client with relaxed security
        def self.development_client(client_name, user_pool_id)
          {
            name: client_name,
            user_pool_id: user_pool_id,
            generate_secret: false,
            allowed_oauth_flows: ['code', 'implicit'],
            allowed_oauth_flows_user_pool_client: true,
            allowed_oauth_scopes: ['phone', 'email', 'openid', 'profile', 'aws.cognito.signin.user.admin'],
            callback_urls: [
              'http://localhost:3000/callback',
              'http://localhost:8080/callback',
              'https://oauth.pstmn.io/v1/callback'  # Postman testing
            ],
            logout_urls: [
              'http://localhost:3000/',
              'http://localhost:8080/'
            ],
            supported_identity_providers: ['COGNITO'],
            explicit_auth_flows: [
              'ALLOW_USER_SRP_AUTH',
              'ALLOW_USER_PASSWORD_AUTH',
              'ALLOW_ADMIN_USER_PASSWORD_AUTH',
              'ALLOW_CUSTOM_AUTH',
              'ALLOW_REFRESH_TOKEN_AUTH'
            ]
          }
        end
      end
    end
      end
    end
  end
end