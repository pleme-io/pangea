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
require 'pangea/resources/cloudflare_load_balancer/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    # Cloudflare Load Balancer resource module
    module CloudflareLoadBalancer
      # Create a Cloudflare Load Balancer with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Load balancer attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def cloudflare_load_balancer(name, attributes = {})
        # Validate attributes using dry-struct
        lb_attrs = Cloudflare::Types::LoadBalancerAttributes.new(attributes)

        # Generate terraform resource block via terraform-synthesizer
        resource(:cloudflare_load_balancer, name) do
          zone_id lb_attrs.zone_id
          name lb_attrs.name
          default_pool_ids lb_attrs.default_pool_ids
          fallback_pool_id lb_attrs.fallback_pool_id if lb_attrs.fallback_pool_id
          description lb_attrs.description if lb_attrs.description
          ttl lb_attrs.ttl if lb_attrs.ttl
          steering_policy lb_attrs.steering_policy
          session_affinity lb_attrs.session_affinity
          session_affinity_ttl lb_attrs.session_affinity_ttl if lb_attrs.session_affinity_ttl

          if lb_attrs.session_affinity_attributes
            session_affinity_attributes do
              lb_attrs.session_affinity_attributes.each do |key, value|
                public_send(key, value)
              end
            end
          end

          proxied lb_attrs.proxied
          enabled lb_attrs.enabled

          # Add region pools
          lb_attrs.region_pools.each do |region_pool|
            region_pools do
              region region_pool[:region]
              pool_ids region_pool[:pool_ids]
            end
          end

          # Add pop pools
          lb_attrs.pop_pools.each do |pop_pool|
            pop_pools do
              pop pop_pool[:pop]
              pool_ids pop_pool[:pool_ids]
            end
          end
        end

        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'cloudflare_load_balancer',
          name: name,
          resource_attributes: lb_attrs.to_h,
          outputs: {
            id: "${cloudflare_load_balancer.#{name}.id}",
            created_on: "${cloudflare_load_balancer.#{name}.created_on}",
            modified_on: "${cloudflare_load_balancer.#{name}.modified_on}"
          }
        )
      end
    end

    # Extend Cloudflare module
    module Cloudflare
      include CloudflareLoadBalancer
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
