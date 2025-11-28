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
require 'pangea/resources/cloudflare_filter/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    # Cloudflare Filter resource module
    module CloudflareFilter
      # Create a Cloudflare Filter with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Filter attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def cloudflare_filter(name, attributes = {})
        # Validate attributes using dry-struct
        filter_attrs = Cloudflare::Types::FilterAttributes.new(attributes)

        # Generate terraform resource block via terraform-synthesizer
        resource(:cloudflare_filter, name) do
          zone_id filter_attrs.zone_id
          expression filter_attrs.expression
          description filter_attrs.description if filter_attrs.description
          ref filter_attrs.ref if filter_attrs.ref
          paused filter_attrs.paused
        end

        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'cloudflare_filter',
          name: name,
          resource_attributes: filter_attrs.to_h,
          outputs: {
            id: "${cloudflare_filter.#{name}.id}"
          }
        )
      end
    end

    # Extend Cloudflare module
    module Cloudflare
      include CloudflareFilter
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
