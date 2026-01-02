# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

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
      end
    end
  end
end
