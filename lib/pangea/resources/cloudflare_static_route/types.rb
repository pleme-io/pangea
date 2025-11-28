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
        # Scope configuration for Magic WAN static routes
        class MagicWANRouteScope < Dry::Struct
          transform_keys(&:to_sym)

          # @!attribute colo_names
          #   @return [Array<String>, nil] Specific Cloudflare data center names
          attribute :colo_names, Dry::Types['strict.array']
            .of(Dry::Types['strict.string'])
            .optional
            .default(nil)

          # @!attribute colo_regions
          #   @return [Array<String>, nil] Cloudflare regions (e.g., "APAC", "ENAM")
          attribute :colo_regions, Dry::Types['strict.array']
            .of(Dry::Types['strict.string'])
            .optional
            .default(nil)
        end

        # Type-safe attributes for Cloudflare Magic WAN Static Route
        #
        # Static routes for Magic WAN traffic steering to direct packets
        # to specific next-hop addresses based on destination IP prefixes.
        #
        # Note: Lower priority values have greater priority. When priorities match,
        # Cloudflare uses Equal-Cost Multi-Path (ECMP) forwarding.
        #
        # @example Basic static route
        #   StaticRouteAttributes.new(
        #     account_id: "a" * 32,
        #     prefix: "192.0.2.0/24",
        #     nexthop: "10.0.0.1",
        #     priority: 100
        #   )
        #
        # @example Route with ECMP weight
        #   StaticRouteAttributes.new(
        #     account_id: "a" * 32,
        #     prefix: "192.0.2.0/24",
        #     nexthop: "10.0.0.1",
        #     priority: 100,
        #     weight: 128,
        #     description: "Primary route"
        #   )
        class StaticRouteAttributes < Dry::Struct
          transform_keys(&:to_sym)

          # @!attribute account_id
          #   @return [String] The account ID
          attribute :account_id, ::Pangea::Resources::Types::CloudflareAccountId

          # @!attribute prefix
          #   @return [String] IP prefix in CIDR format
          attribute :prefix, Dry::Types['strict.string'].constrained(
            format: /\A\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\/\d{1,2}\z/
          )

          # @!attribute nexthop
          #   @return [String] Next-hop IP address
          attribute :nexthop, Dry::Types['strict.string'].constrained(
            format: /\A\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\z/
          )

          # @!attribute priority
          #   @return [Integer] Priority (lower value = higher priority)
          attribute :priority, Dry::Types['coercible.integer'].constrained(gteq: 0)

          # @!attribute description
          #   @return [String, nil] Human-readable description
          attribute :description, Dry::Types['strict.string'].optional.default(nil)

          # @!attribute weight
          #   @return [Integer, nil] ECMP weight (1-256)
          attribute :weight, Dry::Types['coercible.integer']
            .constrained(gteq: 1, lteq: 256)
            .optional
            .default(nil)

          # @!attribute scope
          #   @return [MagicWANRouteScope, nil] Region/colo scope
          attribute :scope, MagicWANRouteScope.optional.default(nil)

          # Check if route has weight for ECMP
          # @return [Boolean] true if ECMP weight configured
          def has_weight?
            !weight.nil?
          end

          # Check if route is scoped to specific regions/colos
          # @return [Boolean] true if scoped
          def scoped?
            !scope.nil?
          end

          # Get priority level description
          # @return [String] Description of priority level
          def priority_level
            case priority
            when 0..50 then "high"
            when 51..150 then "medium"
            else "low"
            end
          end
        end
      end
    end
  end
end
