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


require 'dry-struct'
require 'pangea/resources/types'

module Pangea
  module Resources
    module Cloudflare
      module Types
        # Application type for Zero Trust Access
        ZeroTrustAccessApplicationType = Dry::Types['strict.string'].enum(
          'self_hosted',     # Self-hosted application
          'saas',            # SaaS application
          'ssh',             # SSH application
          'vnc',             # VNC application
          'app_launcher',    # App launcher
          'warp',            # WARP application
          'biso',            # Browser isolation
          'bookmark',        # Bookmark application
          'dash_sso'         # Dashboard SSO
        )

        # SameSite cookie attribute
        ZeroTrustSameSiteCookieAttribute = Dry::Types['strict.string'].enum(
          'none',
          'lax',
          'strict'
        )

        # CORS headers configuration
        class ZeroTrustAccessCorsHeaders < Dry::Struct
          transform_keys(&:to_sym)

          # @!attribute allow_all_headers
          #   @return [Boolean, nil] Allow all headers
          attribute :allow_all_headers, Dry::Types['strict.bool'].optional.default(nil)

          # @!attribute allow_all_methods
          #   @return [Boolean, nil] Allow all methods
          attribute :allow_all_methods, Dry::Types['strict.bool'].optional.default(nil)

          # @!attribute allow_all_origins
          #   @return [Boolean, nil] Allow all origins
          attribute :allow_all_origins, Dry::Types['strict.bool'].optional.default(nil)

          # @!attribute allow_credentials
          #   @return [Boolean, nil] Allow credentials
          attribute :allow_credentials, Dry::Types['strict.bool'].optional.default(nil)

          # @!attribute allowed_headers
          #   @return [Array<String>, nil] Allowed headers
          attribute :allowed_headers, Dry::Types['strict.array']
            .of(Dry::Types['strict.string'])
            .optional
            .default(nil)

          # @!attribute allowed_methods
          #   @return [Array<String>, nil] Allowed methods
          attribute :allowed_methods, Dry::Types['strict.array']
            .of(Dry::Types['strict.string'])
            .optional
            .default(nil)

          # @!attribute allowed_origins
          #   @return [Array<String>, nil] Allowed origins
          attribute :allowed_origins, Dry::Types['strict.array']
            .of(Dry::Types['strict.string'])
            .optional
            .default(nil)

          # @!attribute max_age
          #   @return [Integer, nil] Max age for CORS preflight cache
          attribute :max_age, Dry::Types['coercible.integer']
            .constrained(gteq: -1)
            .optional
            .default(nil)
        end

        # Application destination
        class ZeroTrustAccessDestination < Dry::Struct
          transform_keys(&:to_sym)

          # @!attribute type
          #   @return [String, nil] Destination type
          attribute :type, Dry::Types['strict.string'].optional.default(nil)

          # @!attribute uri
          #   @return [String, nil] URI
          attribute :uri, Dry::Types['strict.string'].optional.default(nil)

          # @!attribute hostname
          #   @return [String, nil] Hostname
          attribute :hostname, Dry::Types['strict.string'].optional.default(nil)

          # @!attribute cidr
          #   @return [String, nil] CIDR block
          attribute :cidr, Dry::Types['strict.string'].optional.default(nil)

          # @!attribute port_range
          #   @return [String, nil] Port range
          attribute :port_range, Dry::Types['strict.string'].optional.default(nil)

          # @!attribute l4_protocol
          #   @return [String, nil] Layer 4 protocol
          attribute :l4_protocol, Dry::Types['strict.string'].optional.default(nil)

          # @!attribute vnet_id
          #   @return [String, nil] Virtual network ID
          attribute :vnet_id, Dry::Types['strict.string'].optional.default(nil)

          # @!attribute mcp_server_id
          #   @return [String, nil] MCP server ID
          attribute :mcp_server_id, Dry::Types['strict.string'].optional.default(nil)
        end

        # Landing page design
        class ZeroTrustAccessLandingPageDesign < Dry::Struct
          transform_keys(&:to_sym)

          # @!attribute title
          #   @return [String, nil] Landing page title
          attribute :title, Dry::Types['strict.string'].optional.default(nil)

          # @!attribute message
          #   @return [String, nil] Landing page message
          attribute :message, Dry::Types['strict.string'].optional.default(nil)

          # @!attribute button_color
          #   @return [String, nil] Button color (hex)
          attribute :button_color, Dry::Types['strict.string'].optional.default(nil)

          # @!attribute button_text_color
          #   @return [String, nil] Button text color (hex)
          attribute :button_text_color, Dry::Types['strict.string'].optional.default(nil)

          # @!attribute image_url
          #   @return [String, nil] Image URL
          attribute :image_url, Dry::Types['strict.string'].optional.default(nil)
        end

        # Footer link configuration
        class ZeroTrustAccessFooterLink < Dry::Struct
          transform_keys(&:to_sym)

          # @!attribute name
          #   @return [String] Link name
          attribute :name, Dry::Types['strict.string']

          # @!attribute url
          #   @return [String] Link URL
          attribute :url, Dry::Types['strict.string']
        end

        # SaaS application configuration
        class ZeroTrustAccessSaasApp < Dry::Struct
          transform_keys(&:to_sym)

          # @!attribute auth_type
          #   @return [String, nil] Authentication type (saml or oidc)
          attribute :auth_type, Dry::Types['strict.string']
            .enum('saml', 'oidc')
            .optional
            .default(nil)

          # @!attribute client_id
          #   @return [String, nil] OAuth client ID
          attribute :client_id, Dry::Types['strict.string'].optional.default(nil)

          # @!attribute client_secret
          #   @return [String, nil] OAuth client secret
          attribute :client_secret, Dry::Types['strict.string'].optional.default(nil)

          # @!attribute redirect_uris
          #   @return [Array<String>, nil] OAuth redirect URIs
          attribute :redirect_uris, Dry::Types['strict.array']
            .of(Dry::Types['strict.string'])
            .optional
            .default(nil)

          # @!attribute grant_types
          #   @return [Array<String>, nil] OAuth grant types
          attribute :grant_types, Dry::Types['strict.array']
            .of(Dry::Types['strict.string'])
            .optional
            .default(nil)

          # @!attribute scopes
          #   @return [Array<String>, nil] OAuth scopes
          attribute :scopes, Dry::Types['strict.array']
            .of(Dry::Types['strict.string'])
            .optional
            .default(nil)

          # @!attribute sp_entity_id
          #   @return [String, nil] SAML service provider entity ID
          attribute :sp_entity_id, Dry::Types['strict.string'].optional.default(nil)

          # @!attribute idp_entity_id
          #   @return [String, nil] SAML IdP entity ID
          attribute :idp_entity_id, Dry::Types['strict.string'].optional.default(nil)

          # @!attribute sso_endpoint
          #   @return [String, nil] SSO endpoint URL
          attribute :sso_endpoint, Dry::Types['strict.string'].optional.default(nil)

          # @!attribute public_key
          #   @return [String, nil] Public key for validation
          attribute :public_key, Dry::Types['strict.string'].optional.default(nil)

          # @!attribute name_id_format
          #   @return [String, nil] SAML NameID format
          attribute :name_id_format, Dry::Types['strict.string'].optional.default(nil)

          # @!attribute name_id_transform_jsonata
          #   @return [String, nil] JSONata transformation for NameID
          attribute :name_id_transform_jsonata, Dry::Types['strict.string'].optional.default(nil)

          # @!attribute access_token_lifetime
          #   @return [String, nil] Access token lifetime
          attribute :access_token_lifetime, Dry::Types['strict.string'].optional.default(nil)

          # @!attribute default_relay_state
          #   @return [String, nil] Default relay state
          attribute :default_relay_state, Dry::Types['strict.string'].optional.default(nil)

          # @!attribute allow_pkce_without_client_secret
          #   @return [Boolean, nil] Allow PKCE without client secret
          attribute :allow_pkce_without_client_secret, Dry::Types['strict.bool'].optional.default(nil)
        end

        # SCIM configuration
        class ZeroTrustAccessScimConfig < Dry::Struct
          transform_keys(&:to_sym)

          # @!attribute enabled
          #   @return [Boolean] Enable SCIM provisioning
          attribute :enabled, Dry::Types['strict.bool']

          # @!attribute remote_uri
          #   @return [String] SCIM endpoint URL
          attribute :remote_uri, Dry::Types['strict.string']

          # @!attribute idp_uid
          #   @return [String, nil] Identity provider UID mapping
          attribute :idp_uid, Dry::Types['strict.string'].optional.default(nil)

          # @!attribute deactivate_on_delete
          #   @return [Boolean, nil] Deactivate on user removal
          attribute :deactivate_on_delete, Dry::Types['strict.bool'].optional.default(nil)

          # @!attribute authentication
          #   @return [Hash, nil] SCIM authentication credentials
          attribute :authentication, Dry::Types['strict.hash'].optional.default(nil)

          # @!attribute mappings
          #   @return [Array<Hash>, nil] Attribute mappings
          attribute :mappings, Dry::Types['strict.array']
            .of(Dry::Types['strict.hash'])
            .optional
            .default(nil)
        end

        # Type-safe attributes for Cloudflare Zero Trust Access Application
        #
        # Zero Trust Access Applications secure web applications, SSH, VNC,
        # and SaaS apps with identity-based access control.
        #
        # @example Self-hosted web application
        #   ZeroTrustAccessApplicationAttributes.new(
        #     account_id: "a" * 32,
        #     name: "Internal Dashboard",
        #     type: "self_hosted",
        #     domain: "dash.example.com",
        #     session_duration: "24h",
        #     auto_redirect_to_identity: true
        #   )
        #
        # @example SaaS application with SAML
        #   ZeroTrustAccessApplicationAttributes.new(
        #     account_id: "a" * 32,
        #     name: "Salesforce",
        #     type: "saas",
        #     saas_app: {
        #       auth_type: "saml",
        #       sp_entity_id: "salesforce-entity",
        #       sso_endpoint: "https://salesforce.com/sso"
        #     }
        #   )
        class ZeroTrustAccessApplicationAttributes < Dry::Struct
          transform_keys(&:to_sym)

          # @!attribute account_id
          #   @return [String] The account ID
          attribute :account_id, ::Pangea::Resources::Types::CloudflareAccountId

          # @!attribute name
          #   @return [String] Application name
          attribute :name, Dry::Types['strict.string'].constrained(min_size: 1)

          # @!attribute type
          #   @return [String, nil] Application type
          attribute :type, ZeroTrustAccessApplicationType.optional.default(nil)

          # @!attribute domain
          #   @return [String, nil] Application domain
          attribute :domain, Dry::Types['strict.string'].optional.default(nil)

          # @!attribute zone_id
          #   @return [String, nil] Zone ID
          attribute :zone_id, ::Pangea::Resources::Types::CloudflareZoneId.optional.default(nil)

          # @!attribute session_duration
          #   @return [String, nil] Session duration
          attribute :session_duration, Dry::Types['strict.string'].optional.default(nil)

          # @!attribute auto_redirect_to_identity
          #   @return [Boolean, nil] Auto redirect to IdP
          attribute :auto_redirect_to_identity, Dry::Types['strict.bool'].optional.default(nil)

          # @!attribute enable_binding_cookie
          #   @return [Boolean, nil] Bind session to device
          attribute :enable_binding_cookie, Dry::Types['strict.bool'].optional.default(nil)

          # @!attribute http_only_cookie_attribute
          #   @return [Boolean, nil] HttpOnly cookie flag
          attribute :http_only_cookie_attribute, Dry::Types['strict.bool'].optional.default(nil)

          # @!attribute same_site_cookie_attribute
          #   @return [String, nil] SameSite cookie policy
          attribute :same_site_cookie_attribute, ZeroTrustSameSiteCookieAttribute.optional.default(nil)

          # @!attribute service_auth_401_redirect
          #   @return [Boolean, nil] Redirect on 401 for service auth
          attribute :service_auth_401_redirect, Dry::Types['strict.bool'].optional.default(nil)

          # @!attribute skip_interstitial
          #   @return [Boolean, nil] Skip interstitial page
          attribute :skip_interstitial, Dry::Types['strict.bool'].optional.default(nil)

          # @!attribute app_launcher_visible
          #   @return [Boolean, nil] Show in app launcher
          attribute :app_launcher_visible, Dry::Types['strict.bool'].optional.default(nil)

          # @!attribute app_launcher_logo_url
          #   @return [String, nil] App launcher logo URL
          attribute :app_launcher_logo_url, Dry::Types['strict.string'].optional.default(nil)

          # @!attribute logo_url
          #   @return [String, nil] Application logo URL
          attribute :logo_url, Dry::Types['strict.string'].optional.default(nil)

          # @!attribute skip_app_launcher_login_page
          #   @return [Boolean, nil] Skip app launcher login page
          attribute :skip_app_launcher_login_page, Dry::Types['strict.bool'].optional.default(nil)

          # @!attribute allow_authenticate_via_warp
          #   @return [Boolean, nil] Allow WARP authentication
          attribute :allow_authenticate_via_warp, Dry::Types['strict.bool'].optional.default(nil)

          # @!attribute allow_iframe
          #   @return [Boolean, nil] Allow iframe embedding
          attribute :allow_iframe, Dry::Types['strict.bool'].optional.default(nil)

          # @!attribute custom_deny_message
          #   @return [String, nil] Custom denial message
          attribute :custom_deny_message, Dry::Types['strict.string'].optional.default(nil)

          # @!attribute custom_deny_url
          #   @return [String, nil] Custom denial URL
          attribute :custom_deny_url, Dry::Types['strict.string'].optional.default(nil)

          # @!attribute custom_non_identity_deny_url
          #   @return [String, nil] Non-identity denial URL
          attribute :custom_non_identity_deny_url, Dry::Types['strict.string'].optional.default(nil)

          # @!attribute custom_pages
          #   @return [Array<String>, nil] Custom page IDs
          attribute :custom_pages, Dry::Types['strict.array']
            .of(Dry::Types['strict.string'])
            .optional
            .default(nil)

          # @!attribute bg_color
          #   @return [String, nil] Background color (hex)
          attribute :bg_color, Dry::Types['strict.string'].optional.default(nil)

          # @!attribute header_bg_color
          #   @return [String, nil] Header background color (hex)
          attribute :header_bg_color, Dry::Types['strict.string'].optional.default(nil)

          # @!attribute path_cookie_attribute
          #   @return [Boolean, nil] Include path in cookie
          attribute :path_cookie_attribute, Dry::Types['strict.bool'].optional.default(nil)

          # @!attribute options_preflight_bypass
          #   @return [Boolean, nil] Bypass CORS preflight
          attribute :options_preflight_bypass, Dry::Types['strict.bool'].optional.default(nil)

          # @!attribute allowed_idps
          #   @return [Array<String>, nil] Allowed identity provider IDs
          attribute :allowed_idps, Dry::Types['strict.array']
            .of(Dry::Types['strict.string'])
            .optional
            .default(nil)

          # @!attribute tags
          #   @return [Array<String>, nil] Resource tags
          attribute :tags, Dry::Types['strict.array']
            .of(Dry::Types['strict.string'])
            .optional
            .default(nil)

          # @!attribute self_hosted_domains
          #   @return [Array<String>, nil] Self-hosted domains (deprecated)
          attribute :self_hosted_domains, Dry::Types['strict.array']
            .of(Dry::Types['strict.string'])
            .optional
            .default(nil)

          # @!attribute cors_headers
          #   @return [ZeroTrustAccessCorsHeaders, nil] CORS configuration
          attribute :cors_headers, ZeroTrustAccessCorsHeaders.optional.default(nil)

          # @!attribute destinations
          #   @return [Array<ZeroTrustAccessDestination>, nil] Application destinations
          attribute :destinations, Dry::Types['strict.array']
            .of(ZeroTrustAccessDestination)
            .optional
            .default(nil)

          # @!attribute landing_page_design
          #   @return [ZeroTrustAccessLandingPageDesign, nil] Landing page design
          attribute :landing_page_design, ZeroTrustAccessLandingPageDesign.optional.default(nil)

          # @!attribute footer_links
          #   @return [Array<ZeroTrustAccessFooterLink>, nil] Footer links
          attribute :footer_links, Dry::Types['strict.array']
            .of(ZeroTrustAccessFooterLink)
            .optional
            .default(nil)

          # @!attribute saas_app
          #   @return [ZeroTrustAccessSaasApp, nil] SaaS app configuration
          attribute :saas_app, ZeroTrustAccessSaasApp.optional.default(nil)

          # @!attribute scim_config
          #   @return [ZeroTrustAccessScimConfig, nil] SCIM configuration
          attribute :scim_config, ZeroTrustAccessScimConfig.optional.default(nil)

          # Check if self-hosted application
          # @return [Boolean] true if self-hosted
          def self_hosted?
            type == 'self_hosted'
          end

          # Check if SaaS application
          # @return [Boolean] true if SaaS
          def saas?
            type == 'saas'
          end

          # Check if SSH application
          # @return [Boolean] true if SSH
          def ssh?
            type == 'ssh'
          end

          # Check if has CORS configuration
          # @return [Boolean] true if CORS configured
          def has_cors?
            !cors_headers.nil?
          end

          # Check if has destinations
          # @return [Boolean] true if destinations configured
          def has_destinations?
            !destinations.nil? && !destinations.empty?
          end

          # Check if SCIM provisioning enabled
          # @return [Boolean] true if SCIM enabled
          def scim_enabled?
            scim_config&.enabled == true
          end
        end
      end
    end
  end
end
