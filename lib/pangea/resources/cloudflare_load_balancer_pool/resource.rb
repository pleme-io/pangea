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
require 'pangea/resources/cloudflare_load_balancer_pool/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    # Cloudflare Load Balancer Pool resource module
    module CloudflareLoadBalancerPool
      # Create a Cloudflare Load Balancer Pool with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Pool attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def cloudflare_load_balancer_pool(name, attributes = {})
        # Validate attributes using dry-struct
        pool_attrs = Cloudflare::Types::LoadBalancerPoolAttributes.new(attributes)

        # Generate terraform resource block via terraform-synthesizer
        resource(:cloudflare_load_balancer_pool, name) do
          account_id pool_attrs.account_id
          name pool_attrs.name
          description pool_attrs.description if pool_attrs.description
          enabled pool_attrs.enabled
          minimum_origins pool_attrs.minimum_origins
          monitor pool_attrs.monitor if pool_attrs.monitor
          notification_email pool_attrs.notification_email if pool_attrs.notification_email

          # Add check regions
          if pool_attrs.check_regions
            check_regions pool_attrs.check_regions
          end

          # Add origins as array (terraform-synthesizer handles array → blocks conversion)
          if pool_attrs.origins.any?
            origin pool_attrs.origins.map { |o| o.to_h }
          end
        end

        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'cloudflare_load_balancer_pool',
          name: name,
          resource_attributes: pool_attrs.to_h,
          outputs: {
            id: "${cloudflare_load_balancer_pool.#{name}.id}",
            created_on: "${cloudflare_load_balancer_pool.#{name}.created_on}",
            modified_on: "${cloudflare_load_balancer_pool.#{name}.modified_on}"
          }
        )
      end
    end

    # Extend Cloudflare module
    module Cloudflare
      include CloudflareLoadBalancerPool
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
