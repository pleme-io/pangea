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

module Pangea
  module Resources
    module AWS
      # Query Wavelength edge location mappings
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Edge location attributes
      # @option attributes [String] :region The AWS region
      # @option attributes [String] :carrier_name The carrier name (e.g., "verizon", "att")
      # @return [ResourceReference] Reference object with outputs
      def aws_wavelength_edge_location_mapping(name, attributes = {})
        optional_attrs = {
          region: nil,
          carrier_name: nil
        }

        edge_attrs = optional_attrs.merge(attributes)

        data(:aws_availability_zones, name) do
          state "available"

          # Filter for Wavelength zones
          filter do
            name "zone-type"
            values ["wavelength-zone"]
          end

          if edge_attrs[:region]
            filter do
              name "region-name"
              values [edge_attrs[:region]]
            end
          end
        end

        ResourceReference.new(
          type: 'aws_availability_zones',
          name: name,
          resource_attributes: edge_attrs,
          outputs: {
            id: "${data.aws_availability_zones.#{name}.id}",
            names: "${data.aws_availability_zones.#{name}.names}",
            zone_ids: "${data.aws_availability_zones.#{name}.zone_ids}",
            group_names: "${data.aws_availability_zones.#{name}.group_names}"
          }
        )
      end
    end
  end
end
