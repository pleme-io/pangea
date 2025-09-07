# frozen_string_literal: true

require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
      # Type-safe attributes for AWS Cognito Identity Provider resources
      class CognitoIdentityProviderAttributes < Dry::Struct
        # Provider name (required)
        attribute :provider_name, Resources::Types::String

        # Provider type (required)
        attribute :provider_type, Resources::Types::String.enum('SAML', 'OIDC', 'Facebook', 'Google', 'LoginWithAmazon', 'Apple', 'Twitter')

        # User pool ID (required)
        attribute :user_pool_id, Resources::Types::String

        # Provider details (varies by provider type)
        attribute :provider_details, Resources::Types::Hash.optional

        # Attribute mapping from provider to user pool
        attribute :attribute_mapping, Resources::Types::Hash.optional

        # Identity provider identifiers
        attribute :idp_identifiers, Resources::Types::Array.of(Types::String).optional

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)

          # Validate provider name format
          unless attrs.provider_name.match?(/\A[a-zA-Z0-9._-]{1,32}\z/)
            raise Dry::Struct::Error, "Provider name must be 1-32 characters and contain only letters, numbers, periods, underscores, and hyphens"
          end

          # Provider-specific validation
          case attrs.provider_type
          when 'SAML'
            validate_saml_provider(attrs)
          when 'OIDC'
            validate_oidc_provider(attrs)
          when 'Facebook'
            validate_facebook_provider(attrs)
          when 'Google'
            validate_google_provider(attrs)
          when 'LoginWithAmazon'
            validate_amazon_provider(attrs)
          when 'Apple'
            validate_apple_provider(attrs)
          when 'Twitter'
            validate_twitter_provider(attrs)
          end

          attrs
        end

        # Provider type categorization
        def social_provider?
          %w[Facebook Google LoginWithAmazon Apple Twitter].include?(provider_type)
        end

        def enterprise_provider?
          %w[SAML OIDC].include?(provider_type)
        end

        def oauth_provider?
          %w[Google Facebook LoginWithAmazon Apple].include?(provider_type)
        end

        def saml_provider?
          provider_type == 'SAML'
        end

        def oidc_provider?
          provider_type == 'OIDC'
        end

        # Get provider category
        def provider_category
          if social_provider?
            :social
          elsif enterprise_provider?
            :enterprise
          else
            :other
          end
        end

        # Check if provider supports specific features
        def supports_attribute_mapping?
          # All providers support attribute mapping
          true
        end

        def supports_multiple_identifiers?
          # Most providers except Twitter support multiple identifiers
          provider_type != 'Twitter'
        end

        # Get required provider details keys
        def required_provider_details_keys
          case provider_type
          when 'SAML'
            %w[MetadataURL]
          when 'OIDC'
            %w[client_id client_secret oidc_issuer authorize_scopes]
          when 'Facebook'
            %w[client_id client_secret]
          when 'Google'
            %w[client_id client_secret]
          when 'LoginWithAmazon'
            %w[client_id client_secret]
          when 'Apple'
            %w[client_id team_id key_id private_key]
          when 'Twitter'
            %w[client_id client_secret]
          else
            []
          end
        end

        # Validate provider details completeness
        def provider_details_complete?
          return true unless provider_details

          required_keys = required_provider_details_keys
          return true if required_keys.empty?

          required_keys.all? { |key| provider_details[key] }
        end

        # Get standard attribute mappings for provider
        def standard_attribute_mappings
          case provider_type
          when 'SAML'
            {
              'email' => 'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress',
              'given_name' => 'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/givenname',
              'family_name' => 'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/surname'
            }
          when 'Google'
            {
              'email' => 'email',
              'given_name' => 'given_name',
              'family_name' => 'family_name',
              'picture' => 'picture'
            }
          when 'Facebook'
            {
              'email' => 'email',
              'given_name' => 'first_name',
              'family_name' => 'last_name',
              'picture' => 'picture'
            }
          when 'Apple'
            {
              'email' => 'email',
              'given_name' => 'firstName',
              'family_name' => 'lastName'
            }
          else
            {}
          end
        end

        private

        def self.validate_saml_provider(attrs)
          return unless attrs.provider_details

          details = attrs.provider_details

          # MetadataURL is required for SAML
          unless details['MetadataURL']
            raise Dry::Struct::Error, "MetadataURL is required for SAML provider"
          end

          # Validate MetadataURL format
          unless details['MetadataURL'].match?(/\Ahttps:\/\/.+\z/)
            raise Dry::Struct::Error, "MetadataURL must be a valid HTTPS URL"
          end
        end

        def self.validate_oidc_provider(attrs)
          return unless attrs.provider_details

          details = attrs.provider_details

          # Required fields for OIDC
          required_fields = %w[client_id client_secret oidc_issuer authorize_scopes]
          required_fields.each do |field|
            unless details[field]
              raise Dry::Struct::Error, "#{field} is required for OIDC provider"
            end
          end

          # Validate OIDC issuer URL
          unless details['oidc_issuer'].match?(/\Ahttps:\/\/.+\z/)
            raise Dry::Struct::Error, "oidc_issuer must be a valid HTTPS URL"
          end

          # Validate authorize_scopes format
          unless details['authorize_scopes'].match?(/\A[\w\s]+\z/)
            raise Dry::Struct::Error, "authorize_scopes must contain only letters, numbers, and spaces"
          end
        end

        def self.validate_facebook_provider(attrs)
          return unless attrs.provider_details

          details = attrs.provider_details

          # Client ID should be numeric for Facebook
          if details['client_id'] && !details['client_id'].match?(/\A\d+\z/)
            raise Dry::Struct::Error, "Facebook client_id must be numeric"
          end

          # Client secret validation
          if details['client_secret'] && details['client_secret'].length < 32
            raise Dry::Struct::Error, "Facebook client_secret appears to be invalid (too short)"
          end
        end

        def self.validate_google_provider(attrs)
          return unless attrs.provider_details

          details = attrs.provider_details

          # Google client ID format validation
          if details['client_id'] && !details['client_id'].match?(/\A\d+-.+\.apps\.googleusercontent\.com\z/)
            raise Dry::Struct::Error, "Google client_id must be in format: numbers-string.apps.googleusercontent.com"
          end
        end

        def self.validate_amazon_provider(attrs)
          return unless attrs.provider_details

          details = attrs.provider_details

          # Amazon client ID should start with amzn1.application-oa2-client
          if details['client_id'] && !details['client_id'].match?(/\Aamzn1\.application-oa2-client\..+\z/)
            raise Dry::Struct::Error, "Amazon client_id must start with 'amzn1.application-oa2-client.'"
          end
        end

        def self.validate_apple_provider(attrs)
          return unless attrs.provider_details

          details = attrs.provider_details

          # Apple requires specific fields
          required_fields = %w[client_id team_id key_id private_key]
          required_fields.each do |field|
            unless details[field]
              raise Dry::Struct::Error, "#{field} is required for Apple provider"
            end
          end

          # Team ID should be 10 characters
          if details['team_id'] && !details['team_id'].match?(/\A[A-Z0-9]{10}\z/)
            raise Dry::Struct::Error, "Apple team_id must be 10 alphanumeric characters"
          end

          # Key ID should be 10 characters
          if details['key_id'] && !details['key_id'].match?(/\A[A-Z0-9]{10}\z/)
            raise Dry::Struct::Error, "Apple key_id must be 10 alphanumeric characters"
          end
        end

        def self.validate_twitter_provider(attrs)
          # Twitter validation is minimal as it uses OAuth 1.0a
          return unless attrs.provider_details

          details = attrs.provider_details

          # Basic validation for client_id and client_secret presence
          %w[client_id client_secret].each do |field|
            unless details[field]
              raise Dry::Struct::Error, "#{field} is required for Twitter provider"
            end
          end
        end
      end

      # Pre-configured identity provider templates
      module IdentityProviderTemplates
        # Google identity provider
        def self.google(provider_name, user_pool_id, client_id, client_secret, scopes = 'profile email openid')
          {
            provider_name: provider_name,
            provider_type: 'Google',
            user_pool_id: user_pool_id,
            provider_details: {
              'client_id' => client_id,
              'client_secret' => client_secret,
              'authorize_scopes' => scopes
            },
            attribute_mapping: {
              'email' => 'email',
              'email_verified' => 'email_verified',
              'given_name' => 'given_name',
              'family_name' => 'family_name',
              'picture' => 'picture'
            }
          }
        end

        # Facebook identity provider
        def self.facebook(provider_name, user_pool_id, app_id, app_secret, api_version = 'v12.0')
          {
            provider_name: provider_name,
            provider_type: 'Facebook',
            user_pool_id: user_pool_id,
            provider_details: {
              'client_id' => app_id,
              'client_secret' => app_secret,
              'api_version' => api_version,
              'authorize_scopes' => 'public_profile,email'
            },
            attribute_mapping: {
              'email' => 'email',
              'given_name' => 'first_name',
              'family_name' => 'last_name',
              'picture' => 'picture'
            }
          }
        end

        # Apple Sign In identity provider
        def self.apple(provider_name, user_pool_id, client_id, team_id, key_id, private_key)
          {
            provider_name: provider_name,
            provider_type: 'Apple',
            user_pool_id: user_pool_id,
            provider_details: {
              'client_id' => client_id,
              'team_id' => team_id,
              'key_id' => key_id,
              'private_key' => private_key
            },
            attribute_mapping: {
              'email' => 'email',
              'given_name' => 'firstName',
              'family_name' => 'lastName'
            }
          }
        end

        # Amazon Login identity provider
        def self.amazon(provider_name, user_pool_id, client_id, client_secret)
          {
            provider_name: provider_name,
            provider_type: 'LoginWithAmazon',
            user_pool_id: user_pool_id,
            provider_details: {
              'client_id' => client_id,
              'client_secret' => client_secret,
              'authorize_scopes' => 'profile'
            },
            attribute_mapping: {
              'email' => 'email',
              'given_name' => 'name'
            }
          }
        end

        # SAML identity provider
        def self.saml(provider_name, user_pool_id, metadata_url, identifiers = [])
          {
            provider_name: provider_name,
            provider_type: 'SAML',
            user_pool_id: user_pool_id,
            provider_details: {
              'MetadataURL' => metadata_url
            },
            attribute_mapping: {
              'email' => 'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress',
              'given_name' => 'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/givenname',
              'family_name' => 'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/surname'
            },
            idp_identifiers: identifiers.any? ? identifiers : [provider_name]
          }
        end

        # OpenID Connect identity provider
        def self.oidc(provider_name, user_pool_id, client_id, client_secret, issuer_url, scopes = 'openid email profile')
          {
            provider_name: provider_name,
            provider_type: 'OIDC',
            user_pool_id: user_pool_id,
            provider_details: {
              'client_id' => client_id,
              'client_secret' => client_secret,
              'oidc_issuer' => issuer_url,
              'authorize_scopes' => scopes,
              'attributes_request_method' => 'GET'
            },
            attribute_mapping: {
              'email' => 'email',
              'email_verified' => 'email_verified',
              'given_name' => 'given_name',
              'family_name' => 'family_name'
            }
          }
        end

        # Enterprise Azure AD (OIDC) provider
        def self.azure_ad(provider_name, user_pool_id, client_id, client_secret, tenant_id)
          oidc_issuer = "https://login.microsoftonline.com/#{tenant_id}/v2.0"
          
          oidc(
            provider_name,
            user_pool_id,
            client_id,
            client_secret,
            oidc_issuer,
            'openid email profile'
          ).tap do |config|
            config[:attribute_mapping].merge!({
              'given_name' => 'given_name',
              'family_name' => 'family_name',
              'email' => 'email'
            })
          end
        end

        # Enterprise Okta (SAML) provider
        def self.okta_saml(provider_name, user_pool_id, okta_domain, app_name)
          metadata_url = "https://#{okta_domain}.okta.com/app/#{app_name}/sso/saml/metadata"
          
          saml(
            provider_name,
            user_pool_id,
            metadata_url,
            [provider_name, "okta_#{provider_name}"]
          )
        end

        # Development provider with relaxed validation
        def self.development_oidc(provider_name, user_pool_id, issuer_url)
          {
            provider_name: provider_name,
            provider_type: 'OIDC',
            user_pool_id: user_pool_id,
            provider_details: {
              'client_id' => 'development-client-id',
              'client_secret' => 'development-client-secret',
              'oidc_issuer' => issuer_url,
              'authorize_scopes' => 'openid email profile',
              'attributes_request_method' => 'GET'
            },
            attribute_mapping: {
              'email' => 'email',
              'given_name' => 'given_name',
              'family_name' => 'family_name'
            }
          }
        end
      end
    end
      end
    end
  end
end