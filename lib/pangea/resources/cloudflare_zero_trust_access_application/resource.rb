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
require 'pangea/resources/cloudflare_zero_trust_access_application/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    # Cloudflare Zero Trust Access Application resource module that self-registers
    module CloudflareZeroTrustAccessApplication
      # Create a Cloudflare Zero Trust Access Application
      #
      # Zero Trust Access Applications secure web applications, SSH, VNC,
      # and SaaS apps with identity-based access control. Replaces traditional
      # VPN with per-app authentication.
      #
      # Supports self-hosted apps, SaaS integrations, SSH/VNC, and browser isolation.
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Access application attributes
      # @option attributes [String] :account_id Account ID (required)
      # @option attributes [String] :name Application name (required)
      # @option attributes [String] :type Application type
      # @option attributes [String] :domain Application domain
      # @option attributes [String] :session_duration Session timeout
      # @option attributes [Hash] :cors_headers CORS configuration
      # @option attributes [Array<Hash>] :destinations Application destinations
      # @option attributes [Hash] :saas_app SaaS app configuration
      # @option attributes [Hash] :scim_config SCIM provisioning
      #
      # @return [ResourceReference] Reference object with outputs
      #
      # @example Self-hosted application
      #   cloudflare_zero_trust_access_application(:internal_app, {
      #     account_id: "a" * 32,
      #     name: "Internal Dashboard",
      #     type: "self_hosted",
      #     domain: "dash.example.com",
      #     session_duration: "24h",
      #     auto_redirect_to_identity: true,
      #     enable_binding_cookie: true
      #   })
      #
      # @example SaaS application with SAML
      #   cloudflare_zero_trust_access_application(:salesforce, {
      #     account_id: "a" * 32,
      #     name: "Salesforce",
      #     type: "saas",
      #     saas_app: {
      #       auth_type: "saml",
      #       sp_entity_id: "salesforce-entity",
      #       sso_endpoint: "https://salesforce.com/sso",
      #       name_id_format: "email"
      #     }
      #   })
      #
      # @example SSH application with destinations
      #   cloudflare_zero_trust_access_application(:ssh_servers, {
      #     account_id: "a" * 32,
      #     name: "Production SSH",
      #     type: "ssh",
      #     destinations: [
      #       { hostname: "server1.internal.com" },
      #       { hostname: "server2.internal.com" }
      #     ]
      #   })
      def cloudflare_zero_trust_access_application(name, attributes = {})
        # Validate attributes using dry-struct
        app_attrs = Cloudflare::Types::ZeroTrustAccessApplicationAttributes.new(attributes)

        # Generate terraform resource block via terraform-synthesizer
        resource(:cloudflare_zero_trust_access_application, name) do
          account_id app_attrs.account_id
          name app_attrs.name
          type app_attrs.type if app_attrs.type
          domain app_attrs.domain if app_attrs.domain
          zone_id app_attrs.zone_id if app_attrs.zone_id
          session_duration app_attrs.session_duration if app_attrs.session_duration

          # Authentication settings
          auto_redirect_to_identity app_attrs.auto_redirect_to_identity if app_attrs.auto_redirect_to_identity
          allow_authenticate_via_warp app_attrs.allow_authenticate_via_warp if app_attrs.allow_authenticate_via_warp
          allow_iframe app_attrs.allow_iframe if app_attrs.allow_iframe
          service_auth_401_redirect app_attrs.service_auth_401_redirect if app_attrs.service_auth_401_redirect

          # Cookie settings
          enable_binding_cookie app_attrs.enable_binding_cookie if app_attrs.enable_binding_cookie
          http_only_cookie_attribute app_attrs.http_only_cookie_attribute if app_attrs.http_only_cookie_attribute
          same_site_cookie_attribute app_attrs.same_site_cookie_attribute if app_attrs.same_site_cookie_attribute
          path_cookie_attribute app_attrs.path_cookie_attribute if app_attrs.path_cookie_attribute

          # UI settings
          skip_interstitial app_attrs.skip_interstitial if app_attrs.skip_interstitial
          app_launcher_visible app_attrs.app_launcher_visible if app_attrs.app_launcher_visible
          app_launcher_logo_url app_attrs.app_launcher_logo_url if app_attrs.app_launcher_logo_url
          logo_url app_attrs.logo_url if app_attrs.logo_url
          skip_app_launcher_login_page app_attrs.skip_app_launcher_login_page if app_attrs.skip_app_launcher_login_page
          bg_color app_attrs.bg_color if app_attrs.bg_color
          header_bg_color app_attrs.header_bg_color if app_attrs.header_bg_color

          # Custom error pages
          custom_deny_message app_attrs.custom_deny_message if app_attrs.custom_deny_message
          custom_deny_url app_attrs.custom_deny_url if app_attrs.custom_deny_url
          custom_non_identity_deny_url app_attrs.custom_non_identity_deny_url if app_attrs.custom_non_identity_deny_url
          custom_pages app_attrs.custom_pages if app_attrs.custom_pages

          # Advanced settings
          options_preflight_bypass app_attrs.options_preflight_bypass if app_attrs.options_preflight_bypass
          allowed_idps app_attrs.allowed_idps if app_attrs.allowed_idps
          tags app_attrs.tags if app_attrs.tags
          self_hosted_domains app_attrs.self_hosted_domains if app_attrs.self_hosted_domains

          # CORS headers
          if app_attrs.cors_headers
            cors_headers do
              allow_all_headers app_attrs.cors_headers.allow_all_headers if app_attrs.cors_headers.allow_all_headers
              allow_all_methods app_attrs.cors_headers.allow_all_methods if app_attrs.cors_headers.allow_all_methods
              allow_all_origins app_attrs.cors_headers.allow_all_origins if app_attrs.cors_headers.allow_all_origins
              allow_credentials app_attrs.cors_headers.allow_credentials if app_attrs.cors_headers.allow_credentials
              allowed_headers app_attrs.cors_headers.allowed_headers if app_attrs.cors_headers.allowed_headers
              allowed_methods app_attrs.cors_headers.allowed_methods if app_attrs.cors_headers.allowed_methods
              allowed_origins app_attrs.cors_headers.allowed_origins if app_attrs.cors_headers.allowed_origins
              max_age app_attrs.cors_headers.max_age if app_attrs.cors_headers.max_age
            end
          end

          # Destinations
          if app_attrs.destinations
            app_attrs.destinations.each do |dest|
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
          end

          # Landing page design
          if app_attrs.landing_page_design
            landing_page_design do
              title app_attrs.landing_page_design.title if app_attrs.landing_page_design.title
              message app_attrs.landing_page_design.message if app_attrs.landing_page_design.message
              button_color app_attrs.landing_page_design.button_color if app_attrs.landing_page_design.button_color
              button_text_color app_attrs.landing_page_design.button_text_color if app_attrs.landing_page_design.button_text_color
              image_url app_attrs.landing_page_design.image_url if app_attrs.landing_page_design.image_url
            end
          end

          # Footer links
          if app_attrs.footer_links
            app_attrs.footer_links.each do |link|
              footer_links do
                name link.name
                url link.url
              end
            end
          end

          # SaaS app configuration
          if app_attrs.saas_app
            saas_app do
              auth_type app_attrs.saas_app.auth_type if app_attrs.saas_app.auth_type
              client_id app_attrs.saas_app.client_id if app_attrs.saas_app.client_id
              client_secret app_attrs.saas_app.client_secret if app_attrs.saas_app.client_secret
              redirect_uris app_attrs.saas_app.redirect_uris if app_attrs.saas_app.redirect_uris
              grant_types app_attrs.saas_app.grant_types if app_attrs.saas_app.grant_types
              scopes app_attrs.saas_app.scopes if app_attrs.saas_app.scopes
              sp_entity_id app_attrs.saas_app.sp_entity_id if app_attrs.saas_app.sp_entity_id
              idp_entity_id app_attrs.saas_app.idp_entity_id if app_attrs.saas_app.idp_entity_id
              sso_endpoint app_attrs.saas_app.sso_endpoint if app_attrs.saas_app.sso_endpoint
              public_key app_attrs.saas_app.public_key if app_attrs.saas_app.public_key
              name_id_format app_attrs.saas_app.name_id_format if app_attrs.saas_app.name_id_format
              name_id_transform_jsonata app_attrs.saas_app.name_id_transform_jsonata if app_attrs.saas_app.name_id_transform_jsonata
              access_token_lifetime app_attrs.saas_app.access_token_lifetime if app_attrs.saas_app.access_token_lifetime
              default_relay_state app_attrs.saas_app.default_relay_state if app_attrs.saas_app.default_relay_state
              allow_pkce_without_client_secret app_attrs.saas_app.allow_pkce_without_client_secret if app_attrs.saas_app.allow_pkce_without_client_secret
            end
          end

          # SCIM configuration
          if app_attrs.scim_config
            scim_config do
              enabled app_attrs.scim_config.enabled
              remote_uri app_attrs.scim_config.remote_uri
              idp_uid app_attrs.scim_config.idp_uid if app_attrs.scim_config.idp_uid
              deactivate_on_delete app_attrs.scim_config.deactivate_on_delete if app_attrs.scim_config.deactivate_on_delete

              if app_attrs.scim_config.authentication
                authentication do
                  app_attrs.scim_config.authentication.each do |key, value|
                    send(key.to_sym, value)
                  end
                end
              end

              if app_attrs.scim_config.mappings
                app_attrs.scim_config.mappings.each do |mapping|
                  mappings do
                    mapping.each do |key, value|
                      send(key.to_sym, value)
                    end
                  end
                end
              end
            end
          end
        end

        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'cloudflare_zero_trust_access_application',
          name: name,
          resource_attributes: app_attrs.to_h,
          outputs: {
            id: "${cloudflare_zero_trust_access_application.#{name}.id}",
            aud: "${cloudflare_zero_trust_access_application.#{name}.aud}"
          }
        )
      end
    end

    # Maintain backward compatibility by extending Cloudflare module
    module Cloudflare
      include CloudflareZeroTrustAccessApplication
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
