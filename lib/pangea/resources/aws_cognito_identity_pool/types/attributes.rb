# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
        # Type-safe attributes for AWS Cognito Identity Pool resources
        class CognitoIdentityPoolAttributes < Dry::Struct
          attribute :identity_pool_name, Resources::Types::String
          attribute :allow_unauthenticated_identities, Resources::Types::Bool.default(false)
          attribute :allow_classic_flow, Resources::Types::Bool.default(false)
          attribute :cognito_identity_providers, Resources::Types::Array.of(CognitoIdentityPoolProvider).optional
          attribute :supported_login_providers, Resources::Types::Hash.optional
          attribute :openid_connect_provider_arns, Resources::Types::Array.of(Types::String).optional
          attribute :saml_provider_arns, Resources::Types::Array.of(Types::String).optional
          attribute :developer_provider_name, Resources::Types::String.optional
          attribute :tags, Resources::Types::AwsTags.default({}.freeze)

          def self.new(attributes = {})
            attrs = super(attributes)
            validate_pool_name(attrs)
            validate_auth_methods(attrs)
            validate_social_providers(attrs)
            attrs
          end

          def self.validate_pool_name(attrs)
            return if attrs.identity_pool_name.length.between?(1, 128)
            raise Dry::Struct::Error, "Identity pool name must be 1-128 characters"
          end

          def self.validate_auth_methods(attrs)
            return if attrs.allow_unauthenticated_identities
            return if attrs.cognito_identity_providers&.any? || attrs.supported_login_providers&.any? ||
                      attrs.openid_connect_provider_arns&.any? || attrs.saml_provider_arns&.any? ||
                      attrs.developer_provider_name
            raise Dry::Struct::Error, "At least one auth method required when unauthenticated not allowed"
          end

          def self.validate_social_providers(attrs)
            attrs.supported_login_providers&.each do |provider, app_id|
              case provider
              when 'accounts.google.com'
                raise Dry::Struct::Error, "Invalid Google OAuth client ID" unless app_id.match?(/\A\d+-.+\.apps\.googleusercontent\.com\z/)
              when 'www.amazon.com'
                raise Dry::Struct::Error, "Invalid Amazon app ID" unless app_id.match?(/\A[a-zA-Z0-9]+\z/)
              when 'graph.facebook.com'
                raise Dry::Struct::Error, "Invalid Facebook app ID" unless app_id.match?(/\A\d+\z/)
              end
            end
          end

          def has_authentication?
            cognito_identity_providers&.any? || supported_login_providers&.any? ||
            openid_connect_provider_arns&.any? || saml_provider_arns&.any? || developer_provider_name
          end

          def uses_cognito_user_pools? = cognito_identity_providers&.any?
          def uses_social_providers? = supported_login_providers&.any?
          def uses_saml_providers? = saml_provider_arns&.any?
          def uses_oidc_providers? = openid_connect_provider_arns&.any?
          def uses_developer_auth? = !developer_provider_name.nil?

          def authentication_methods
            [].tap do |m|
              m << :cognito_user_pools if uses_cognito_user_pools?
              m << :social_providers if uses_social_providers?
              m << :saml_providers if uses_saml_providers?
              m << :oidc_providers if uses_oidc_providers?
              m << :developer_auth if uses_developer_auth?
              m << :unauthenticated if allow_unauthenticated_identities
            end
          end

          def social_providers
            return [] unless supported_login_providers
            supported_login_providers.keys.map do |p|
              { 'accounts.google.com' => :google, 'www.amazon.com' => :amazon,
                'graph.facebook.com' => :facebook, 'api.twitter.com' => :twitter }[p] || p.to_sym
            end
          end

          def has_social_provider?(provider)
            return false unless supported_login_providers
            mapping = { google: 'accounts.google.com', amazon: 'www.amazon.com',
                        facebook: 'graph.facebook.com', twitter: 'api.twitter.com' }
            supported_login_providers.key?(mapping[provider.to_sym])
          end

          def security_level
            return :low if allow_unauthenticated_identities
            return :high if uses_developer_auth? || uses_saml_providers? || uses_oidc_providers?
            return :medium_high if uses_cognito_user_pools?
            return :medium if uses_social_providers?
            :unknown
          end
        end
      end
    end
  end
end
