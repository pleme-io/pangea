# frozen_string_literal: true

require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
      # Cognito identity provider configuration for identity pool
      class CognitoIdentityPoolProvider < Dry::Struct
        attribute :client_id, Resources::Types::String.optional
        attribute :provider_name, Resources::Types::String.optional
        attribute :server_side_token_check, Resources::Types::Bool.optional
      end

      # SAML identity provider configuration
      class SamlIdentityProvider < Dry::Struct
        attribute :provider_name, Resources::Types::String
        attribute :provider_arn, Resources::Types::String
      end

      # OpenID Connect identity provider configuration  
      class OpenIdConnectProvider < Dry::Struct
        attribute :provider_name, Resources::Types::String
        attribute :provider_arn, Resources::Types::String
      end

      # Developer authenticated identities configuration
      class DeveloperProvider < Dry::Struct
        attribute :provider_name, Resources::Types::String
        attribute :developer_user_identifier_name, Resources::Types::String.optional
      end

      # Type-safe attributes for AWS Cognito Identity Pool resources
      class CognitoIdentityPoolAttributes < Dry::Struct
        # Identity pool name (required)
        attribute :identity_pool_name, Resources::Types::String

        # Whether to allow unauthenticated identities
        attribute :allow_unauthenticated_identities, Resources::Types::Bool.default(false)

        # Whether to allow classic flow (not recommended for new applications)
        attribute :allow_classic_flow, Resources::Types::Bool.default(false)

        # Cognito identity providers (user pools)
        attribute :cognito_identity_providers, Resources::Types::Array.of(CognitoIdentityPoolProvider).optional

        # Supported login providers (OAuth)
        attribute :supported_login_providers, Resources::Types::Hash.optional

        # OpenID Connect providers 
        attribute :openid_connect_provider_arns, Resources::Types::Array.of(Types::String).optional

        # SAML provider ARNs
        attribute :saml_provider_arns, Resources::Types::Array.of(Types::String).optional

        # Developer provider name for custom authentication
        attribute :developer_provider_name, Resources::Types::String.optional

        # Tags for the identity pool
        attribute :tags, Resources::Types::AwsTags.default({})

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)

          # Validate identity pool name format
          if attrs.identity_pool_name.length < 1 || attrs.identity_pool_name.length > 128
            raise Dry::Struct::Error, "Identity pool name must be 1-128 characters"
          end

          # Validate at least one authentication method if not allowing unauthenticated
          if !attrs.allow_unauthenticated_identities
            has_auth_method = attrs.cognito_identity_providers&.any? ||
                              attrs.supported_login_providers&.any? ||
                              attrs.openid_connect_provider_arns&.any? ||
                              attrs.saml_provider_arns&.any? ||
                              attrs.developer_provider_name

            unless has_auth_method
              raise Dry::Struct::Error, "At least one authentication method is required when unauthenticated identities are not allowed"
            end
          end

          # Validate supported login providers format
          if attrs.supported_login_providers
            attrs.supported_login_providers.each do |provider, app_id|
              case provider
              when 'accounts.google.com'
                # Google OAuth client ID validation
                unless app_id.match?(/\A\d+-.+\.apps\.googleusercontent\.com\z/)
                  raise Dry::Struct::Error, "Invalid Google OAuth client ID format"
                end
              when 'www.amazon.com'
                # Amazon app ID validation - should be alphanumeric
                unless app_id.match?(/\A[a-zA-Z0-9]+\z/)
                  raise Dry::Struct::Error, "Invalid Amazon app ID format"
                end
              when 'graph.facebook.com'
                # Facebook app ID validation - should be numeric
                unless app_id.match?(/\A\d+\z/)
                  raise Dry::Struct::Error, "Invalid Facebook app ID format"
                end
              end
            end
          end

          attrs
        end

        # Check if pool allows any form of authentication
        def has_authentication?
          cognito_identity_providers&.any? ||
          supported_login_providers&.any? ||
          openid_connect_provider_arns&.any? ||
          saml_provider_arns&.any? ||
          developer_provider_name
        end

        # Check if pool uses Cognito User Pools
        def uses_cognito_user_pools?
          cognito_identity_providers&.any?
        end

        # Check if pool uses social login providers
        def uses_social_providers?
          supported_login_providers&.any?
        end

        # Check if pool uses SAML providers
        def uses_saml_providers?
          saml_provider_arns&.any?
        end

        # Check if pool uses OpenID Connect providers
        def uses_oidc_providers?
          openid_connect_provider_arns&.any?
        end

        # Check if pool uses developer authentication
        def uses_developer_auth?
          !developer_provider_name.nil?
        end

        # Get list of configured authentication methods
        def authentication_methods
          methods = []
          methods << :cognito_user_pools if uses_cognito_user_pools?
          methods << :social_providers if uses_social_providers?
          methods << :saml_providers if uses_saml_providers?
          methods << :oidc_providers if uses_oidc_providers?
          methods << :developer_auth if uses_developer_auth?
          methods << :unauthenticated if allow_unauthenticated_identities
          methods
        end

        # Get supported social providers
        def social_providers
          return [] unless supported_login_providers

          supported_login_providers.keys.map do |provider|
            case provider
            when 'accounts.google.com'
              :google
            when 'www.amazon.com'
              :amazon
            when 'graph.facebook.com'
              :facebook
            when 'api.twitter.com'
              :twitter
            else
              provider.to_sym
            end
          end
        end

        # Check if specific social provider is configured
        def has_social_provider?(provider)
          return false unless supported_login_providers

          case provider.to_sym
          when :google
            supported_login_providers.key?('accounts.google.com')
          when :amazon
            supported_login_providers.key?('www.amazon.com')
          when :facebook
            supported_login_providers.key?('graph.facebook.com')
          when :twitter
            supported_login_providers.key?('api.twitter.com')
          else
            false
          end
        end

        # Get security level assessment
        def security_level
          if allow_unauthenticated_identities
            :low
          elsif uses_developer_auth? || uses_saml_providers? || uses_oidc_providers?
            :high
          elsif uses_cognito_user_pools?
            :medium_high
          elsif uses_social_providers?
            :medium
          else
            :unknown
          end
        end
      end

      # Pre-configured identity pool templates for common scenarios
      module IdentityPoolTemplates
        # Basic authenticated identity pool with Cognito User Pool
        def self.basic_authenticated(pool_name, user_pool_id, user_pool_client_id)
          {
            identity_pool_name: pool_name,
            allow_unauthenticated_identities: false,
            cognito_identity_providers: [{
              client_id: user_pool_client_id,
              provider_name: user_pool_id
            }]
          }
        end

        # Identity pool with social login providers
        def self.social_login(pool_name, social_providers = {})
          {
            identity_pool_name: pool_name,
            allow_unauthenticated_identities: false,
            supported_login_providers: social_providers
          }
        end

        # Identity pool with mixed authentication methods
        def self.mixed_authentication(pool_name, user_pool_config, social_providers = {})
          {
            identity_pool_name: pool_name,
            allow_unauthenticated_identities: false,
            cognito_identity_providers: [user_pool_config],
            supported_login_providers: social_providers
          }
        end

        # Enterprise identity pool with SAML
        def self.enterprise_saml(pool_name, saml_provider_arns)
          {
            identity_pool_name: pool_name,
            allow_unauthenticated_identities: false,
            saml_provider_arns: saml_provider_arns
          }
        end

        # Mobile app identity pool (allows unauthenticated)
        def self.mobile_app(pool_name, user_pool_config = nil, allow_unauthenticated = true)
          config = {
            identity_pool_name: pool_name,
            allow_unauthenticated_identities: allow_unauthenticated
          }
          
          config[:cognito_identity_providers] = [user_pool_config] if user_pool_config
          config
        end

        # Development identity pool with all providers
        def self.development(pool_name, user_pool_config = nil)
          config = {
            identity_pool_name: pool_name,
            allow_unauthenticated_identities: true,  # For testing
            allow_classic_flow: true,  # For compatibility testing
            supported_login_providers: {
              'accounts.google.com' => 'test-google-client-id.apps.googleusercontent.com',
              'graph.facebook.com' => '123456789',
              'www.amazon.com' => 'testAmazonAppId'
            }
          }
          
          config[:cognito_identity_providers] = [user_pool_config] if user_pool_config
          config
        end

        # IoT identity pool for device authentication
        def self.iot_devices(pool_name, certificate_based = false)
          if certificate_based
            {
              identity_pool_name: pool_name,
              allow_unauthenticated_identities: false,
              developer_provider_name: "#{pool_name.downcase}_iot_provider"
            }
          else
            {
              identity_pool_name: pool_name,
              allow_unauthenticated_identities: true  # For device provisioning
            }
          end
        end

        # Web application identity pool
        def self.web_application(pool_name, user_pool_config, google_client_id = nil)
          config = {
            identity_pool_name: pool_name,
            allow_unauthenticated_identities: false,
            cognito_identity_providers: [user_pool_config]
          }
          
          if google_client_id
            config[:supported_login_providers] = {
              'accounts.google.com' => google_client_id
            }
          end
          
          config
        end

        # Analytics identity pool (allows anonymous usage tracking)
        def self.analytics(pool_name, user_pool_config = nil)
          config = {
            identity_pool_name: pool_name,
            allow_unauthenticated_identities: true  # For anonymous analytics
          }
          
          config[:cognito_identity_providers] = [user_pool_config] if user_pool_config
          config
        end
      end
    end
      end
    end
  end
end