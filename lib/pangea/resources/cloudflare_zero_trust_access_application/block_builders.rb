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

module Pangea
  module Resources
    module CloudflareZeroTrustAccessApplication
      # Block builders for nested Terraform resource configurations
      module BlockBuilders
        # Build CORS headers nested block
        def build_cors_headers(cors)
          cors_headers do
            allow_all_headers cors.allow_all_headers if cors.allow_all_headers
            allow_all_methods cors.allow_all_methods if cors.allow_all_methods
            allow_all_origins cors.allow_all_origins if cors.allow_all_origins
            allow_credentials cors.allow_credentials if cors.allow_credentials
            allowed_headers cors.allowed_headers if cors.allowed_headers
            allowed_methods cors.allowed_methods if cors.allowed_methods
            allowed_origins cors.allowed_origins if cors.allowed_origins
            max_age cors.max_age if cors.max_age
          end
        end

        # Build destinations nested block
        def build_destination(dest)
          destinations do
            type dest.type if dest.type
            uri dest.uri if dest.uri
            hostname dest.hostname if dest.hostname
            cidr dest.cidr if dest.cidr
            port_range dest.port_range if dest.port_range
            l4_protocol dest.l4_protocol if dest.l4_protocol
            vnet_id dest.vnet_id if dest.vnet_id
            mcp_server_id dest.mcp_server_id if dest.mcp_server_id
          end
        end

        # Build landing page design nested block
        def build_landing_page_design(lpd)
          landing_page_design do
            title lpd.title if lpd.title
            message lpd.message if lpd.message
            button_color lpd.button_color if lpd.button_color
            button_text_color lpd.button_text_color if lpd.button_text_color
            image_url lpd.image_url if lpd.image_url
          end
        end

        # Build footer link nested block
        def build_footer_link(link)
          footer_links do
            name link.name
            url link.url
          end
        end

        # Build SaaS app configuration nested block
        def build_saas_app(saas)
          saas_app do
            auth_type saas.auth_type if saas.auth_type
            client_id saas.client_id if saas.client_id
            client_secret saas.client_secret if saas.client_secret
            redirect_uris saas.redirect_uris if saas.redirect_uris
            grant_types saas.grant_types if saas.grant_types
            scopes saas.scopes if saas.scopes
            sp_entity_id saas.sp_entity_id if saas.sp_entity_id
            idp_entity_id saas.idp_entity_id if saas.idp_entity_id
            sso_endpoint saas.sso_endpoint if saas.sso_endpoint
            public_key saas.public_key if saas.public_key
            name_id_format saas.name_id_format if saas.name_id_format
            name_id_transform_jsonata saas.name_id_transform_jsonata if saas.name_id_transform_jsonata
            access_token_lifetime saas.access_token_lifetime if saas.access_token_lifetime
            default_relay_state saas.default_relay_state if saas.default_relay_state
            allow_pkce_without_client_secret saas.allow_pkce_without_client_secret if saas.allow_pkce_without_client_secret
          end
        end

        # Build SCIM configuration nested block
        def build_scim_config(scim)
          scim_config do
            enabled scim.enabled
            remote_uri scim.remote_uri
            idp_uid scim.idp_uid if scim.idp_uid
            deactivate_on_delete scim.deactivate_on_delete if scim.deactivate_on_delete

            if scim.authentication
              authentication do
                scim.authentication.each { |key, value| send(key.to_sym, value) }
              end
            end

            if scim.mappings
              scim.mappings.each do |mapping|
                mappings do
                  mapping.each { |key, value| send(key.to_sym, value) }
                end
              end
            end
          end
        end
      end
    end
  end
end
