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
        # Load balancer pool origin configuration
        PoolOrigin = ::Pangea::Resources::Types::Hash.schema(
          name: ::Pangea::Resources::Types::String,
          address: ::Pangea::Resources::Types::String,
          enabled?: ::Pangea::Resources::Types::Bool.default(true),
          weight?: ::Pangea::Resources::Types::Float.constrained(gteq: 0.0, lteq: 1.0).default(1.0),
          header?: ::Pangea::Resources::Types::Hash.map(::Pangea::Resources::Types::String, ::Pangea::Resources::Types::Array.of(::Pangea::Resources::Types::String)).optional
        )

        # Cloudflare Load Balancer Pool resource attributes with validation
        class LoadBalancerPoolAttributes < Dry::Struct
          transform_keys(&:to_sym)

          attribute :account_id, ::Pangea::Resources::Types::CloudflareAccountId
          attribute :name, ::Pangea::Resources::Types::String
          attribute :origins, ::Pangea::Resources::Types::Array.of(PoolOrigin).constrained(min_size: 1)
          attribute :description, ::Pangea::Resources::Types::String.optional.default(nil)
          attribute :enabled, ::Pangea::Resources::Types::Bool.default(true)
          attribute :minimum_origins, ::Pangea::Resources::Types::Integer.constrained(gteq: 1).default(1)
          attribute :monitor, ::Pangea::Resources::Types::String.optional.default(nil)
          attribute :notification_email, ::Pangea::Resources::Types::String.optional.default(nil)
          attribute :check_regions, ::Pangea::Resources::Types::Array.of(::Pangea::Resources::Types::CloudflareHealthCheckRegion).optional.default(nil)

          # Custom validation
          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}

            # Validate minimum_origins doesn't exceed actual origins
            if attrs[:origins] && attrs[:minimum_origins]
              if attrs[:minimum_origins] > attrs[:origins].length
                raise Dry::Struct::Error, "minimum_origins (#{attrs[:minimum_origins]}) cannot exceed number of origins (#{attrs[:origins].length})"
              end
            end

            super(attrs)
          end

          # Computed properties
          def origin_count
            origins.length
          end

          def has_monitor?
            !monitor.nil?
          end

          def is_enabled?
            enabled
          end

          def enabled_origin_count
            origins.count { |origin| origin[:enabled] != false }
          end
        end
      end
    end
  end
end
