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
require 'pangea/resources/aws_cognito_user_pool_client/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS Cognito User Pool Client with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Cognito user pool client attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_cognito_user_pool_client(name, attributes = {})
        # Validate attributes using dry-struct
        client_attrs = Types::CognitoUserPoolClientAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_cognito_user_pool_client, name) do
          name client_attrs.name
          user_pool_id client_attrs.user_pool_id
          
          # OAuth configuration
          if client_attrs.allowed_oauth_flows
            allowed_oauth_flows client_attrs.allowed_oauth_flows
          end
          
          allowed_oauth_flows_user_pool_client client_attrs.allowed_oauth_flows_user_pool_client
          
          if client_attrs.allowed_oauth_scopes
            allowed_oauth_scopes client_attrs.allowed_oauth_scopes
          end

          if client_attrs.supported_identity_providers
            supported_identity_providers client_attrs.supported_identity_providers
          end

          if client_attrs.callback_urls
            callback_urls client_attrs.callback_urls
          end

          if client_attrs.logout_urls
            logout_urls client_attrs.logout_urls
          end

          default_redirect_uri client_attrs.default_redirect_uri if client_attrs.default_redirect_uri

          # Client configuration
          generate_secret client_attrs.generate_secret
          enable_token_revocation client_attrs.enable_token_revocation
          enable_propagate_additional_user_context_data client_attrs.enable_propagate_additional_user_context_data

          if client_attrs.explicit_auth_flows
            explicit_auth_flows client_attrs.explicit_auth_flows
          end

          prevent_user_existence_errors client_attrs.prevent_user_existence_errors if client_attrs.prevent_user_existence_errors

          # Attribute permissions
          if client_attrs.read_attributes
            read_attributes client_attrs.read_attributes
          end

          if client_attrs.write_attributes  
            write_attributes client_attrs.write_attributes
          end

          # Token validity configuration
          refresh_token_validity client_attrs.refresh_token_validity if client_attrs.refresh_token_validity
          access_token_validity client_attrs.access_token_validity if client_attrs.access_token_validity
          id_token_validity client_attrs.id_token_validity if client_attrs.id_token_validity

          if client_attrs.token_validity_units
            token_validity_units do
              access_token client_attrs.token_validity_units.access_token
              id_token client_attrs.token_validity_units.id_token
              refresh_token client_attrs.token_validity_units.refresh_token
            end
          end

          # Analytics configuration
          if client_attrs.analytics_configuration
            analytics_configuration do
              application_arn client_attrs.analytics_configuration.application_arn if client_attrs.analytics_configuration.application_arn
              application_id client_attrs.analytics_configuration.application_id if client_attrs.analytics_configuration.application_id  
              external_id client_attrs.analytics_configuration.external_id if client_attrs.analytics_configuration.external_id
              role_arn client_attrs.analytics_configuration.role_arn if client_attrs.analytics_configuration.role_arn
              user_data_shared client_attrs.analytics_configuration.user_data_shared if client_attrs.analytics_configuration.user_data_shared
            end
          end

          auth_session_validity client_attrs.auth_session_validity if client_attrs.auth_session_validity
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_cognito_user_pool_client',
          name: name,
          resource_attributes: client_attrs.to_h,
          outputs: {
            id: "${aws_cognito_user_pool_client.#{name}.id}",
            client_secret: "${aws_cognito_user_pool_client.#{name}.client_secret}",
            name: "${aws_cognito_user_pool_client.#{name}.name}"
          },
          computed_properties: {
            oauth_enabled: client_attrs.oauth_enabled?,
            public_client: client_attrs.public_client?,
            confidential_client: client_attrs.confidential_client?,
            primary_oauth_flow: client_attrs.primary_oauth_flow,
            srp_auth_enabled: client_attrs.srp_auth_enabled?,
            custom_auth_enabled: client_attrs.custom_auth_enabled?,
            admin_auth_enabled: client_attrs.admin_auth_enabled?,
            client_type: client_attrs.client_type,
            analytics_enabled: client_attrs.analytics_enabled?
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)