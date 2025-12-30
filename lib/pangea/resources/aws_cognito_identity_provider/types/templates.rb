# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

module Pangea
  module Resources
    module AWS
      module Types
        # Pre-configured identity provider templates
        module IdentityProviderTemplates
          def self.google(provider_name, user_pool_id, client_id, client_secret, scopes = 'profile email openid')
            { provider_name: provider_name, provider_type: 'Google', user_pool_id: user_pool_id,
              provider_details: { 'client_id' => client_id, 'client_secret' => client_secret, 'authorize_scopes' => scopes },
              attribute_mapping: { 'email' => 'email', 'email_verified' => 'email_verified', 'given_name' => 'given_name', 'family_name' => 'family_name', 'picture' => 'picture' } }
          end

          def self.facebook(provider_name, user_pool_id, app_id, app_secret, api_version = 'v12.0')
            { provider_name: provider_name, provider_type: 'Facebook', user_pool_id: user_pool_id,
              provider_details: { 'client_id' => app_id, 'client_secret' => app_secret, 'api_version' => api_version, 'authorize_scopes' => 'public_profile,email' },
              attribute_mapping: { 'email' => 'email', 'given_name' => 'first_name', 'family_name' => 'last_name', 'picture' => 'picture' } }
          end

          def self.apple(provider_name, user_pool_id, client_id, team_id, key_id, private_key)
            { provider_name: provider_name, provider_type: 'Apple', user_pool_id: user_pool_id,
              provider_details: { 'client_id' => client_id, 'team_id' => team_id, 'key_id' => key_id, 'private_key' => private_key },
              attribute_mapping: { 'email' => 'email', 'given_name' => 'firstName', 'family_name' => 'lastName' } }
          end

          def self.amazon(provider_name, user_pool_id, client_id, client_secret)
            { provider_name: provider_name, provider_type: 'LoginWithAmazon', user_pool_id: user_pool_id,
              provider_details: { 'client_id' => client_id, 'client_secret' => client_secret, 'authorize_scopes' => 'profile' },
              attribute_mapping: { 'email' => 'email', 'given_name' => 'name' } }
          end

          def self.saml(provider_name, user_pool_id, metadata_url, identifiers = [])
            { provider_name: provider_name, provider_type: 'SAML', user_pool_id: user_pool_id,
              provider_details: { 'MetadataURL' => metadata_url },
              attribute_mapping: { 'email' => 'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress',
                                   'given_name' => 'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/givenname',
                                   'family_name' => 'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/surname' },
              idp_identifiers: identifiers.any? ? identifiers : [provider_name] }
          end

          def self.oidc(provider_name, user_pool_id, client_id, client_secret, issuer_url, scopes = 'openid email profile')
            { provider_name: provider_name, provider_type: 'OIDC', user_pool_id: user_pool_id,
              provider_details: { 'client_id' => client_id, 'client_secret' => client_secret, 'oidc_issuer' => issuer_url,
                                  'authorize_scopes' => scopes, 'attributes_request_method' => 'GET' },
              attribute_mapping: { 'email' => 'email', 'email_verified' => 'email_verified', 'given_name' => 'given_name', 'family_name' => 'family_name' } }
          end

          def self.azure_ad(provider_name, user_pool_id, client_id, client_secret, tenant_id)
            oidc(provider_name, user_pool_id, client_id, client_secret, "https://login.microsoftonline.com/#{tenant_id}/v2.0", 'openid email profile')
          end

          def self.okta_saml(provider_name, user_pool_id, okta_domain, app_name)
            saml(provider_name, user_pool_id, "https://#{okta_domain}.okta.com/app/#{app_name}/sso/saml/metadata", [provider_name, "okta_#{provider_name}"])
          end

          def self.development_oidc(provider_name, user_pool_id, issuer_url)
            { provider_name: provider_name, provider_type: 'OIDC', user_pool_id: user_pool_id,
              provider_details: { 'client_id' => 'development-client-id', 'client_secret' => 'development-client-secret',
                                  'oidc_issuer' => issuer_url, 'authorize_scopes' => 'openid email profile', 'attributes_request_method' => 'GET' },
              attribute_mapping: { 'email' => 'email', 'given_name' => 'given_name', 'family_name' => 'family_name' } }
          end
        end
      end
    end
  end
end
