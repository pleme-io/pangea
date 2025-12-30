# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

module Pangea
  module Resources
    module AWS
      module Types
        # Pre-configured identity pool templates for common scenarios
        module IdentityPoolTemplates
          extend self

          def basic_authenticated(pool_name, user_pool_id, user_pool_client_id)
            { identity_pool_name: pool_name, allow_unauthenticated_identities: false,
              cognito_identity_providers: [{ client_id: user_pool_client_id, provider_name: user_pool_id }] }
          end

          def social_login(pool_name, social_providers = {})
            { identity_pool_name: pool_name, allow_unauthenticated_identities: false,
              supported_login_providers: social_providers }
          end

          def mixed_authentication(pool_name, user_pool_config, social_providers = {})
            { identity_pool_name: pool_name, allow_unauthenticated_identities: false,
              cognito_identity_providers: [user_pool_config], supported_login_providers: social_providers }
          end

          def enterprise_saml(pool_name, saml_provider_arns)
            { identity_pool_name: pool_name, allow_unauthenticated_identities: false,
              saml_provider_arns: saml_provider_arns }
          end

          def mobile_app(pool_name, user_pool_config = nil, allow_unauthenticated = true)
            config = { identity_pool_name: pool_name, allow_unauthenticated_identities: allow_unauthenticated }
            config[:cognito_identity_providers] = [user_pool_config] if user_pool_config
            config
          end

          def development(pool_name, user_pool_config = nil)
            config = { identity_pool_name: pool_name, allow_unauthenticated_identities: true,
                       allow_classic_flow: true,
                       supported_login_providers: {
                         'accounts.google.com' => 'test-google-client-id.apps.googleusercontent.com',
                         'graph.facebook.com' => '123456789', 'www.amazon.com' => 'testAmazonAppId'
                       } }
            config[:cognito_identity_providers] = [user_pool_config] if user_pool_config
            config
          end

          def iot_devices(pool_name, certificate_based = false)
            if certificate_based
              { identity_pool_name: pool_name, allow_unauthenticated_identities: false,
                developer_provider_name: "#{pool_name.downcase}_iot_provider" }
            else
              { identity_pool_name: pool_name, allow_unauthenticated_identities: true }
            end
          end

          def web_application(pool_name, user_pool_config, google_client_id = nil)
            config = { identity_pool_name: pool_name, allow_unauthenticated_identities: false,
                       cognito_identity_providers: [user_pool_config] }
            config[:supported_login_providers] = { 'accounts.google.com' => google_client_id } if google_client_id
            config
          end

          def analytics(pool_name, user_pool_config = nil)
            config = { identity_pool_name: pool_name, allow_unauthenticated_identities: true }
            config[:cognito_identity_providers] = [user_pool_config] if user_pool_config
            config
          end
        end
      end
    end
  end
end
