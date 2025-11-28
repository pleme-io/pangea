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
require 'pangea/resources/cloudflare_static_route/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    # Cloudflare Magic WAN Static Route resource module that self-registers
    module CloudflareStaticRoute
      # Create a Cloudflare Magic WAN Static Route
      #
      # Static routes for Magic WAN traffic steering to direct packets
      # to specific next-hop addresses based on destination IP prefixes.
      #
      # Note: Lower priority values have greater priority. When priorities match,
      # Cloudflare uses Equal-Cost Multi-Path (ECMP) forwarding with weights.
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Static route attributes
      # @option attributes [String] :account_id Account ID (required)
      # @option attributes [String] :prefix IP prefix in CIDR format (required)
      # @option attributes [String] :nexthop Next-hop IP address (required)
      # @option attributes [Integer] :priority Priority value (required, lower = higher priority)
      # @option attributes [String] :description Route description
      # @option attributes [Integer] :weight ECMP weight (1-256)
      # @option attributes [Hash] :scope Region/colo scope
      #
      # @return [ResourceReference] Reference object with outputs
      #
      # @example Basic static route
      #   cloudflare_static_route(:default_route, {
      #     account_id: "a" * 32,
      #     prefix: "192.0.2.0/24",
      #     nexthop: "10.0.0.1",
      #     priority: 100,
      #     description: "Route to datacenter A"
      #   })
      #
      # @example ECMP route with weight
      #   cloudflare_static_route(:ecmp_route, {
      #     account_id: "a" * 32,
      #     prefix: "192.0.2.0/24",
      #     nexthop: "10.0.0.2",
      #     priority: 100,
      #     weight: 128,
      #     description: "Secondary ECMP route"
      #   })
      #
      # @example Region-scoped route
      #   cloudflare_static_route(:apac_route, {
      #     account_id: "a" * 32,
      #     prefix: "192.0.2.0/24",
      #     nexthop: "10.0.0.3",
      #     priority: 50,
      #     scope: { colo_regions: ["APAC"] }
      #   })
      def cloudflare_static_route(name, attributes = {})
        # Validate attributes using dry-struct
        route_attrs = Cloudflare::Types::StaticRouteAttributes.new(attributes)

        # Generate terraform resource block via terraform-synthesizer
        # Note: Using cloudflare_magic_wan_static_route (cloudflare_static_route is deprecated)
        resource(:cloudflare_magic_wan_static_route, name) do
          account_id route_attrs.account_id
          prefix route_attrs.prefix
          nexthop route_attrs.nexthop
          priority route_attrs.priority

          description route_attrs.description if route_attrs.description
          weight route_attrs.weight if route_attrs.weight

          if route_attrs.scope
            scope do
              colo_names route_attrs.scope.colo_names if route_attrs.scope.colo_names
              colo_regions route_attrs.scope.colo_regions if route_attrs.scope.colo_regions
            end
          end
        end

        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'cloudflare_magic_wan_static_route',
          name: name,
          resource_attributes: route_attrs.to_h,
          outputs: {
            id: "${cloudflare_magic_wan_static_route.#{name}.id}"
          }
        )
      end

      # Alias for backward compatibility
      alias cloudflare_magic_wan_static_route cloudflare_static_route
    end

    # Maintain backward compatibility by extending Cloudflare module
    module Cloudflare
      include CloudflareStaticRoute
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
