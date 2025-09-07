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


require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/aws_cognito_identity_pool/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS Cognito Identity Pool with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Cognito identity pool attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_cognito_identity_pool(name, attributes = {})
        # Validate attributes using dry-struct
        identity_pool_attrs = Types::CognitoIdentityPoolAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_cognito_identity_pool, name) do
          identity_pool_name identity_pool_attrs.identity_pool_name
          allow_unauthenticated_identities identity_pool_attrs.allow_unauthenticated_identities
          allow_classic_flow identity_pool_attrs.allow_classic_flow

          # Cognito identity providers (user pools)
          if identity_pool_attrs.cognito_identity_providers
            identity_pool_attrs.cognito_identity_providers.each do |provider|
              cognito_identity_providers do
                client_id provider.client_id if provider.client_id
                provider_name provider.provider_name if provider.provider_name
                server_side_token_check provider.server_side_token_check if provider.server_side_token_check
              end
            end
          end

          # Supported login providers (social/OAuth)
          if identity_pool_attrs.supported_login_providers && identity_pool_attrs.supported_login_providers.any?
            supported_login_providers do
              identity_pool_attrs.supported_login_providers.each do |provider_name, app_id|
                public_send(provider_name.gsub('.', '_').gsub('@', '_at_'), app_id)
              end
            end
          end

          # OpenID Connect provider ARNs
          if identity_pool_attrs.openid_connect_provider_arns
            openid_connect_provider_arns identity_pool_attrs.openid_connect_provider_arns
          end

          # SAML provider ARNs
          if identity_pool_attrs.saml_provider_arns
            saml_provider_arns identity_pool_attrs.saml_provider_arns
          end

          # Developer provider name
          developer_provider_name identity_pool_attrs.developer_provider_name if identity_pool_attrs.developer_provider_name

          # Apply tags if present
          if identity_pool_attrs.tags.any?
            tags do
              identity_pool_attrs.tags.each do |key, value|
                public_send(key, value)
              end
            end
          end
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_cognito_identity_pool',
          name: name,
          resource_attributes: identity_pool_attrs.to_h,
          outputs: {
            id: "${aws_cognito_identity_pool.#{name}.id}",
            arn: "${aws_cognito_identity_pool.#{name}.arn}"
          },
          computed_properties: {
            has_authentication: identity_pool_attrs.has_authentication?,
            uses_cognito_user_pools: identity_pool_attrs.uses_cognito_user_pools?,
            uses_social_providers: identity_pool_attrs.uses_social_providers?,
            uses_saml_providers: identity_pool_attrs.uses_saml_providers?,
            uses_oidc_providers: identity_pool_attrs.uses_oidc_providers?,
            uses_developer_auth: identity_pool_attrs.uses_developer_auth?,
            authentication_methods: identity_pool_attrs.authentication_methods,
            social_providers: identity_pool_attrs.social_providers,
            security_level: identity_pool_attrs.security_level
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)