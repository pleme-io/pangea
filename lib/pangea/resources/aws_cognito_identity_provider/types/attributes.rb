# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

module Pangea
  module Resources
    module AWS
      module Types
        # Type-safe attributes for AWS Cognito Identity Provider resources
        class CognitoIdentityProviderAttributes < Dry::Struct
          attribute :provider_name, Resources::Types::String
          attribute :provider_type, Resources::Types::String.enum('SAML', 'OIDC', 'Facebook', 'Google', 'LoginWithAmazon', 'Apple', 'Twitter')
          attribute :user_pool_id, Resources::Types::String
          attribute :provider_details, Resources::Types::Hash.optional
          attribute :attribute_mapping, Resources::Types::Hash.optional
          attribute :idp_identifiers, Resources::Types::Array.of(Types::String).optional

          def self.new(attributes = {})
            attrs = super(attributes)
            raise Dry::Struct::Error, 'Provider name must be 1-32 characters and contain only letters, numbers, periods, underscores, and hyphens' unless attrs.provider_name.match?(/\A[a-zA-Z0-9._-]{1,32}\z/)
            CognitoProviderValidation.validate(attrs)
            attrs
          end

          def social_provider? = %w[Facebook Google LoginWithAmazon Apple Twitter].include?(provider_type)
          def enterprise_provider? = %w[SAML OIDC].include?(provider_type)
          def oauth_provider? = %w[Google Facebook LoginWithAmazon Apple].include?(provider_type)
          def saml_provider? = provider_type == 'SAML'
          def oidc_provider? = provider_type == 'OIDC'
          def provider_category = social_provider? ? :social : (enterprise_provider? ? :enterprise : :other)
          def supports_attribute_mapping? = true
          def supports_multiple_identifiers? = provider_type != 'Twitter'

          def required_provider_details_keys
            { 'SAML' => %w[MetadataURL], 'OIDC' => %w[client_id client_secret oidc_issuer authorize_scopes],
              'Facebook' => %w[client_id client_secret], 'Google' => %w[client_id client_secret],
              'LoginWithAmazon' => %w[client_id client_secret], 'Apple' => %w[client_id team_id key_id private_key],
              'Twitter' => %w[client_id client_secret] }[provider_type] || []
          end

          def provider_details_complete?
            return true unless provider_details
            required_provider_details_keys.all? { |key| provider_details[key] }
          end

          def standard_attribute_mappings
            mappings = {
              'SAML' => { 'email' => 'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress',
                          'given_name' => 'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/givenname',
                          'family_name' => 'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/surname' },
              'Google' => { 'email' => 'email', 'given_name' => 'given_name', 'family_name' => 'family_name', 'picture' => 'picture' },
              'Facebook' => { 'email' => 'email', 'given_name' => 'first_name', 'family_name' => 'last_name', 'picture' => 'picture' },
              'Apple' => { 'email' => 'email', 'given_name' => 'firstName', 'family_name' => 'lastName' }
            }
            mappings[provider_type] || {}
          end
        end
      end
    end
  end
end
