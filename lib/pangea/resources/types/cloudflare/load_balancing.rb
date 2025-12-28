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
      # Cloudflare Load Balancer steering policy
      CloudflareLoadBalancerSteeringPolicy = String.default('off').enum(
        'off', 'geo', 'random', 'dynamic_latency', 'proximity', 'least_outstanding_requests', 'least_connections'
      )

      # Cloudflare Load Balancer session affinity
      CloudflareLoadBalancerSessionAffinity = String.default('none').enum('none', 'cookie', 'ip_cookie', 'header')

      # Cloudflare Load Balancer fallback pool
      CloudflareLoadBalancerFallbackPool = String.optional

      # Cloudflare Load Balancer Pool health check region
      CloudflareHealthCheckRegion = String.enum(
        'WNAM', 'ENAM', 'WEU', 'EEU', 'NSAM', 'SSAM', 'OC', 'ME', 'NAF', 'SAF',
        'SAS', 'SEAS', 'NEAS', 'ALL_REGIONS'
      )

      # Cloudflare Load Balancer Monitor type
      CloudflareMonitorType = String.default('http').enum('http', 'https', 'tcp', 'udp_icmp', 'icmp_ping', 'smtp')

      # Cloudflare Load Balancer Monitor method
      CloudflareMonitorMethod = String.default('GET').enum('GET', 'HEAD', 'POST', 'PUT', 'DELETE', 'CONNECT', 'OPTIONS', 'TRACE', 'PATCH')

      # Cloudflare Load Balancer Monitor interval (in seconds)
      CloudflareMonitorInterval = Integer.constrained(gteq: 5, lteq: 3600)

      # Cloudflare Load Balancer Monitor timeout (in seconds)
      CloudflareMonitorTimeout = Integer.constrained(gteq: 1, lteq: 10)

      # Cloudflare Load Balancer Monitor retries
      CloudflareMonitorRetries = Integer.constrained(gteq: 0, lteq: 5)

      # Cloudflare Load Balancer Monitor expected codes (e.g., "2xx", "200-299")
      CloudflareMonitorExpectedCodes = String.constructor { |value|
        valid_formats = [
          /\A\dxx\z/,
          /\A\d{3}\z/,
          /\A\d{3}-\d{3}\z/
        ]
        unless valid_formats.any? { |pattern| value.match?(pattern) }
          raise Dry::Types::ConstraintError, "Monitor expected codes must be in format '2xx', '200', or '200-299'"
        end
        value
      }

      # Cloudflare origin pool configuration
      CloudflareOriginPoolOrigin = Hash.schema(
        name: String,
        address: String,
        enabled?: Bool.default(true),
        weight?: Integer.constrained(gteq: 0, lteq: 1).default(1),
        header?: Hash.map(String, String).optional
      )

      # Cloudflare Load Balancer region pool
      CloudflareRegionPool = Hash.schema(
        region: CloudflareHealthCheckRegion,
        pool_ids: Array.of(String).constrained(min_size: 1)
      )

      # Cloudflare Load Balancer pop pool
      CloudflarePopPool = Hash.schema(
        pop: String.constrained(format: /\A[A-Z]{3}\z/),
        pool_ids: Array.of(String).constrained(min_size: 1)
      )

      # Cloudflare Load Balancer adaptive routing
      CloudflareAdaptiveRouting = Hash.schema(
        failover_across_pools?: Bool.default(false)
      )

      # Cloudflare Load Balancer location strategy
      CloudflareLocationStrategy = Hash.schema(
        prefer_ecs?: String.enum('always', 'never', 'proximity', 'geo').optional,
        mode?: String.enum('pop', 'resolver_ip').optional
      )

      # Cloudflare Load Balancer random steering
      CloudflareRandomSteering = Hash.schema(
        pool_weights: Hash.map(String, Integer.constrained(gteq: 0, lteq: 1))
      )
    end
  end
end
