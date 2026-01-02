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
    module Cloudflare
      module Types
        # Type-safe attributes for Cloudflare Zero Trust Access Application
        class ZeroTrustAccessApplicationAttributes < Dry::Struct
          transform_keys(&:to_sym)

          # Core attributes
          attribute :account_id, ::Pangea::Resources::Types::CloudflareAccountId
          attribute :name, Dry::Types['strict.string'].constrained(min_size: 1)
          attribute :type, ZeroTrustAccessApplicationType.optional.default(nil)
          attribute :domain, Dry::Types['strict.string'].optional.default(nil)
          attribute :zone_id, ::Pangea::Resources::Types::CloudflareZoneId.optional.default(nil)

          # Session and authentication
          attribute :session_duration, Dry::Types['strict.string'].optional.default(nil)
          attribute :auto_redirect_to_identity, Dry::Types['strict.bool'].optional.default(nil)
          attribute :enable_binding_cookie, Dry::Types['strict.bool'].optional.default(nil)
          attribute :http_only_cookie_attribute, Dry::Types['strict.bool'].optional.default(nil)
          attribute :same_site_cookie_attribute, ZeroTrustSameSiteCookieAttribute.optional.default(nil)
          attribute :service_auth_401_redirect, Dry::Types['strict.bool'].optional.default(nil)
          attribute :path_cookie_attribute, Dry::Types['strict.bool'].optional.default(nil)
          attribute :allow_authenticate_via_warp, Dry::Types['strict.bool'].optional.default(nil)

          # UI and display
          attribute :skip_interstitial, Dry::Types['strict.bool'].optional.default(nil)
          attribute :app_launcher_visible, Dry::Types['strict.bool'].optional.default(nil)
          attribute :app_launcher_logo_url, Dry::Types['strict.string'].optional.default(nil)
          attribute :logo_url, Dry::Types['strict.string'].optional.default(nil)
          attribute :skip_app_launcher_login_page, Dry::Types['strict.bool'].optional.default(nil)
          attribute :allow_iframe, Dry::Types['strict.bool'].optional.default(nil)

          # Custom pages and messages
          attribute :custom_deny_message, Dry::Types['strict.string'].optional.default(nil)
          attribute :custom_deny_url, Dry::Types['strict.string'].optional.default(nil)
          attribute :custom_non_identity_deny_url, Dry::Types['strict.string'].optional.default(nil)
          attribute :custom_pages, Dry::Types['strict.array'].of(Dry::Types['strict.string']).optional.default(nil)

          # Colors and styling
          attribute :bg_color, Dry::Types['strict.string'].optional.default(nil)
          attribute :header_bg_color, Dry::Types['strict.string'].optional.default(nil)

          # CORS and security
          attribute :options_preflight_bypass, Dry::Types['strict.bool'].optional.default(nil)
          attribute :allowed_idps, Dry::Types['strict.array'].of(Dry::Types['strict.string']).optional.default(nil)
          attribute :tags, Dry::Types['strict.array'].of(Dry::Types['strict.string']).optional.default(nil)
          attribute :self_hosted_domains, Dry::Types['strict.array'].of(Dry::Types['strict.string']).optional.default(nil)

          # Complex nested types
          attribute :cors_headers, ZeroTrustAccessCorsHeaders.optional.default(nil)
          attribute :destinations, Dry::Types['strict.array'].of(ZeroTrustAccessDestination).optional.default(nil)
          attribute :landing_page_design, ZeroTrustAccessLandingPageDesign.optional.default(nil)
          attribute :footer_links, Dry::Types['strict.array'].of(ZeroTrustAccessFooterLink).optional.default(nil)
          attribute :saas_app, ZeroTrustAccessSaasApp.optional.default(nil)
          attribute :scim_config, ZeroTrustAccessScimConfig.optional.default(nil)

          # Helper methods
          def self_hosted?
            type == 'self_hosted'
          end

          def saas?
            type == 'saas'
          end

          def ssh?
            type == 'ssh'
          end

          def has_cors?
            !cors_headers.nil?
          end

          def has_destinations?
            !destinations.nil? && !destinations.empty?
          end

          def scim_enabled?
            scim_config&.enabled == true
          end
        end
      end
    end
  end
end
