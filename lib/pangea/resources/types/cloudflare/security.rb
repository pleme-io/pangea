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

require_relative '../core'

module Pangea
  module Resources
    module Types
      # Cloudflare Firewall rule action
      CloudflareFirewallAction = String.enum(
        'block', 'challenge', 'js_challenge', 'managed_challenge', 'allow', 'log', 'bypass'
      )

      # Cloudflare Filter expression (Wirefilter syntax)
      CloudflareFilterExpression = String.constructor { |value|
        if value.strip.empty?
          raise Dry::Types::ConstraintError, "Filter expression cannot be empty"
        end
        value
      }

      # Cloudflare Access application type
      CloudflareAccessApplicationType = String.enum('self_hosted', 'saas', 'ssh', 'vnc', 'app_launcher', 'warp', 'biso', 'bookmark')

      # Cloudflare Access session duration
      CloudflareAccessSessionDuration = String.constructor { |value|
        unless value.match?(/\A\d+[mhd]\z/)
          raise Dry::Types::ConstraintError, "Access session duration must be in format like '24h', '30m', '7d'"
        end
        value
      }

      # Cloudflare Access policy decision
      CloudflareAccessPolicyDecision = String.enum('allow', 'deny', 'non_identity', 'bypass')

      # Cloudflare Access identity provider type
      CloudflareAccessIdentityProviderType = String.enum(
        'onetimepin', 'azureAD', 'saml', 'centrify', 'facebook',
        'github', 'google-apps', 'google', 'linkedin', 'oidc',
        'okta', 'onelogin', 'pingone', 'yandex'
      )

      # Cloudflare Rate Limit threshold
      CloudflareRateLimitThreshold = Integer.constrained(gteq: 2, lteq: 1000000)

      # Cloudflare Rate Limit period (in seconds)
      CloudflareRateLimitPeriod = Integer.constrained(gteq: 1, lteq: 86400)

      # Cloudflare Rate Limit action mode
      CloudflareRateLimitActionMode = String.enum('simulate', 'ban', 'challenge', 'js_challenge', 'managed_challenge')

      # Cloudflare Rate Limit action timeout (in seconds)
      CloudflareRateLimitActionTimeout = Integer.constrained(gteq: 10, lteq: 86400)

      # Cloudflare WAF rule mode
      CloudflareWafRuleMode = String.enum('default', 'disable', 'simulate', 'block', 'challenge')

      # Cloudflare WAF package sensitivity
      CloudflareWafPackageSensitivity = String.enum('high', 'medium', 'low', 'off')

      # Cloudflare WAF package action mode
      CloudflareWafPackageActionMode = String.enum('simulate', 'block', 'challenge')

      # Cloudflare Access CORS headers
      CloudflareAccessCorsHeaders = Hash.schema(
        allowed_methods?: Array.of(String).optional,
        allowed_origins?: Array.of(String).optional,
        allow_credentials?: Bool.optional,
        max_age?: Integer.optional
      )

      # Cloudflare Access include/exclude configuration
      CloudflareAccessRuleConfiguration = Hash.schema(
        email?: Array.of(String).optional,
        email_domain?: Array.of(String).optional,
        ip?: Array.of(String).optional,
        ip_list?: Array.of(String).optional,
        everyone?: Bool.optional,
        certificate?: Bool.optional,
        common_name?: String.optional,
        auth_method?: String.optional,
        geo?: Array.of(String).optional,
        login_method?: Array.of(String).optional,
        service_token?: Array.of(String).optional,
        any_valid_service_token?: Bool.optional,
        group?: Array.of(String).optional,
        azure?: Array.of(Hash).optional,
        github?: Array.of(Hash).optional,
        google?: Array.of(Hash).optional,
        okta?: Array.of(Hash).optional,
        saml?: Array.of(Hash).optional
      )
    end
  end
end
