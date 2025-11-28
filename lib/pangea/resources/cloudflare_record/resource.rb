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
require 'pangea/resources/cloudflare_record/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    # Cloudflare DNS Record resource module
    module CloudflareRecord
      # Create a Cloudflare DNS Record with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] DNS record attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def cloudflare_record(name, attributes = {})
        # Validate attributes using dry-struct
        record_attrs = Cloudflare::Types::RecordAttributes.new(attributes)

        # Generate terraform resource block via terraform-synthesizer
        resource(:cloudflare_record, name) do
          zone_id record_attrs.zone_id
          name record_attrs.name
          type record_attrs.type
          value record_attrs.value if record_attrs.value
          ttl record_attrs.ttl
          priority record_attrs.priority if record_attrs.priority
          proxied record_attrs.proxied if record_attrs.can_be_proxied? && record_attrs.proxied

          # Add SRV data if present
          if record_attrs.data
            data do
              record_attrs.data.each do |key, value|
                public_send(key, value) if value
              end
            end
          end

          comment record_attrs.comment if record_attrs.comment

          # Apply tags if present
          if record_attrs.tags.any?
            tags do
              record_attrs.tags.each do |key, value|
                public_send(key, value)
              end
            end
          end
        end

        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'cloudflare_record',
          name: name,
          resource_attributes: record_attrs.to_h,
          outputs: {
            id: "${cloudflare_record.#{name}.id}",
            hostname: "${cloudflare_record.#{name}.hostname}",
            proxiable: "${cloudflare_record.#{name}.proxiable}",
            created_on: "${cloudflare_record.#{name}.created_on}",
            modified_on: "${cloudflare_record.#{name}.modified_on}",
            metadata: "${cloudflare_record.#{name}.metadata}"
          }
        )
      end
    end

    # Extend Cloudflare module
    module Cloudflare
      include CloudflareRecord
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
