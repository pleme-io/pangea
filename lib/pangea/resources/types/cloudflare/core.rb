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
      # Cloudflare Zone Types
      CloudflareZoneType = String.default('full').enum('full', 'partial', 'secondary')
      CloudflareZonePlan = String.default('free').enum('free', 'pro', 'business', 'enterprise')
      CloudflareZoneStatus = String.enum('active', 'pending', 'initializing', 'moved', 'deleted', 'deactivated')

      # Cloudflare DNS Record Types
      CloudflareDnsRecordType = String.enum(
        'A', 'AAAA', 'CNAME', 'TXT', 'MX', 'NS', 'SRV', 'CAA',
        'HTTPS', 'SVCB', 'LOC', 'PTR', 'CERT', 'DNSKEY', 'DS',
        'NAPTR', 'SMIMEA', 'SSHFP', 'TLSA', 'URI'
      )

      # Cloudflare proxied status (orange cloud vs grey cloud)
      CloudflareProxied = Bool.default(false)

      # Cloudflare TTL validation (1 = automatic, or 60-86400 for manual)
      CloudflareTtl = Integer.constructor { |value|
        next value if value == 1
        unless (60..86400).include?(value)
          raise Dry::Types::ConstraintError, "Cloudflare TTL must be 1 (automatic) or between 60-86400 seconds"
        end
        value
      }

      # Cloudflare priority (for MX, SRV records)
      CloudflarePriority = Integer.constrained(gteq: 0, lteq: 65535)

      # Cloudflare Page Rule actions
      CloudflarePageRuleAction = String.enum(
        'always_online', 'always_use_https', 'automatic_https_rewrites',
        'browser_cache_ttl', 'browser_check', 'bypass_cache_on_cookie',
        'cache_by_device_type', 'cache_deception_armor', 'cache_key_fields',
        'cache_level', 'cache_on_cookie', 'cache_ttl_by_status',
        'disable_apps', 'disable_performance', 'disable_railgun',
        'disable_security', 'edge_cache_ttl', 'email_obfuscation',
        'explicit_cache_control', 'forwarding_url', 'host_header_override',
        'ip_geolocation', 'minify', 'mirage', 'opportunistic_encryption',
        'origin_error_page_pass_thru', 'polish', 'resolve_override',
        'respect_strong_etag', 'response_buffering', 'rocket_loader',
        'security_level', 'server_side_exclude', 'sort_query_string_for_cache',
        'ssl', 'true_client_ip_header', 'waf'
      )

      # Cloudflare cache level
      CloudflareCacheLevel = String.enum('bypass', 'basic', 'simplified', 'aggressive', 'cache_everything')

      # Cloudflare security level
      CloudflareSecurityLevel = String.enum('off', 'essentially_off', 'low', 'medium', 'high', 'under_attack')

      # Cloudflare SSL mode
      CloudflareSslMode = String.enum('off', 'flexible', 'full', 'strict', 'origin_pull')

      # Cloudflare Rocket Loader setting
      CloudflareRocketLoader = String.enum('off', 'manual', 'automatic')

      # Cloudflare Polish setting
      CloudflarePolish = String.enum('off', 'lossless', 'lossy')

      # Cloudflare Zone ID validation
      # Accepts both valid 32-char hex IDs and Terraform interpolation strings
      CloudflareZoneId = String.constructor { |value|
        next value if value.match?(/\A\$\{.+\}\z/)
        unless value.match?(/\A[a-f0-9]{32}\z/)
          raise Dry::Types::ConstraintError, "Cloudflare Zone ID must be 32-character hex or a Terraform interpolation string"
        end
        value
      }

      # Cloudflare Account ID validation
      # Accepts both valid 32-char hex IDs and Terraform interpolation strings
      CloudflareAccountId = String.constructor { |value|
        next value if value.match?(/\A\$\{.+\}\z/)
        unless value.match?(/\A[a-f0-9]{32}\z/)
          raise Dry::Types::ConstraintError, "Cloudflare Account ID must be 32-character hex or a Terraform interpolation string"
        end
        value
      }

      # Cloudflare API Token validation (40 character hex)
      CloudflareApiToken = String.constrained(min_size: 40, max_size: 40)

      # Cloudflare Email validation
      CloudflareEmail = String.constrained(
        format: /\A[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}\z/
      )

      # Cloudflare common tags
      CloudflareTags = Hash.map(String, String).default({}.freeze)

      # Cloudflare Argo smart routing
      CloudflareArgoSmartRouting = String.enum('on', 'off')

      # Cloudflare Argo Tiered Caching
      CloudflareArgoTieredCaching = String.enum('on', 'off')

      # Cloudflare Logpush job dataset
      CloudflareLogpushDataset = String.enum(
        'http_requests', 'spectrum_events', 'firewall_events', 'nel_reports',
        'dns_logs', 'network_analytics_logs', 'workers_trace_events',
        'access_requests', 'gateway_dns', 'gateway_http', 'gateway_network'
      )

      # Cloudflare Logpush destination type
      CloudflareLogpushDestinationType = String.enum('s3', 'gcs', 'azure', 'sumo_logic', 'splunk', 'datadog')

      # Cloudflare Logpush frequency
      CloudflareLogpushFrequency = String.enum('high', 'low')
    end
  end
end
