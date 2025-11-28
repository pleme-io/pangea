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
require 'pangea/resources/cloudflare_worker_route/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    # Cloudflare Worker Route resource module
    module CloudflareWorkerRoute
      # Create a Cloudflare Worker Route with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Worker route attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def cloudflare_worker_route(name, attributes = {})
        # Validate attributes using dry-struct
        route_attrs = Cloudflare::Types::WorkerRouteAttributes.new(attributes)

        # Generate terraform resource block via terraform-synthesizer
        resource(:cloudflare_worker_route, name) do
          zone_id route_attrs.zone_id
          pattern route_attrs.pattern
          script_name route_attrs.script_name if route_attrs.script_name
        end

        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'cloudflare_worker_route',
          name: name,
          resource_attributes: route_attrs.to_h,
          outputs: {
            id: "${cloudflare_worker_route.#{name}.id}"
          }
        )
      end
    end

    # Extend Cloudflare module
    module Cloudflare
      include CloudflareWorkerRoute
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
