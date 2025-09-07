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
require 'pangea/resources/aws_cognito_identity_provider/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS Cognito Identity Provider with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Cognito identity provider attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_cognito_identity_provider(name, attributes = {})
        # Validate attributes using dry-struct
        provider_attrs = Types::CognitoIdentityProviderAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_cognito_identity_provider, name) do
          provider_name provider_attrs.provider_name
          provider_type provider_attrs.provider_type
          user_pool_id provider_attrs.user_pool_id

          # Provider details configuration
          if provider_attrs.provider_details && provider_attrs.provider_details.any?
            provider_details do
              provider_attrs.provider_details.each do |key, value|
                public_send(key, value)
              end
            end
          end

          # Attribute mapping
          if provider_attrs.attribute_mapping && provider_attrs.attribute_mapping.any?
            attribute_mapping do
              provider_attrs.attribute_mapping.each do |user_pool_attr, provider_attr|
                public_send(user_pool_attr, provider_attr)
              end
            end
          end

          # Identity provider identifiers
          if provider_attrs.idp_identifiers
            idp_identifiers provider_attrs.idp_identifiers
          end
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_cognito_identity_provider',
          name: name,
          resource_attributes: provider_attrs.to_h,
          outputs: {
            provider_name: "${aws_cognito_identity_provider.#{name}.provider_name}",
            provider_type: "${aws_cognito_identity_provider.#{name}.provider_type}"
          },
          computed_properties: {
            social_provider: provider_attrs.social_provider?,
            enterprise_provider: provider_attrs.enterprise_provider?,
            oauth_provider: provider_attrs.oauth_provider?,
            saml_provider: provider_attrs.saml_provider?,
            oidc_provider: provider_attrs.oidc_provider?,
            provider_category: provider_attrs.provider_category,
            supports_attribute_mapping: provider_attrs.supports_attribute_mapping?,
            supports_multiple_identifiers: provider_attrs.supports_multiple_identifiers?,
            provider_details_complete: provider_attrs.provider_details_complete?
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)