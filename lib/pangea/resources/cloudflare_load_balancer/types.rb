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
        # Cloudflare Load Balancer resource attributes with validation
        class LoadBalancerAttributes < Dry::Struct
          transform_keys(&:to_sym)

          attribute :zone_id, ::Pangea::Resources::Types::CloudflareZoneId
          attribute :name, ::Pangea::Resources::Types::String
          attribute :default_pool_ids, ::Pangea::Resources::Types::Array.of(::Pangea::Resources::Types::String).constrained(min_size: 1)
          attribute :fallback_pool_id, ::Pangea::Resources::Types::String.optional.default(nil)
          attribute :description, ::Pangea::Resources::Types::String.optional.default(nil)
          attribute :ttl, ::Pangea::Resources::Types::Integer.optional.default(nil)
          attribute :steering_policy, ::Pangea::Resources::Types::CloudflareLoadBalancerSteeringPolicy
          attribute :session_affinity, ::Pangea::Resources::Types::CloudflareLoadBalancerSessionAffinity
          attribute :session_affinity_ttl, ::Pangea::Resources::Types::Integer.constrained(gteq: 1800, lteq: 604800).optional.default(nil)
          attribute :session_affinity_attributes, ::Pangea::Resources::Types::Hash.optional.default(nil)
          attribute :proxied, ::Pangea::Resources::Types::Bool.default(false)
          attribute :enabled, ::Pangea::Resources::Types::Bool.default(true)
          attribute :region_pools, ::Pangea::Resources::Types::Array.of(::Pangea::Resources::Types::CloudflareRegionPool).default([].freeze)
          attribute :pop_pools, ::Pangea::Resources::Types::Array.of(::Pangea::Resources::Types::CloudflarePopPool).default([].freeze)

          # Computed properties
          def is_enabled?
            enabled
          end

          def is_proxied?
            proxied
          end

          def has_fallback_pool?
            !fallback_pool_id.nil?
          end

          def has_region_pools?
            region_pools.any?
          end

          def has_pop_pools?
            pop_pools.any?
          end

          def uses_session_affinity?
            session_affinity != 'none'
          end

          def pool_count
            default_pool_ids.length
          end
        end
      end
    end
  end
end
