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
require 'pangea/resources/aws_memorydb_multi_region_cluster/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Provides a MemoryDB Multi-Region Cluster resource.
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Resource attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_memorydb_multi_region_cluster(name, attributes = {})
        # Validate attributes using dry-struct
        attrs = Types::MemorydbMultiRegionClusterAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_memorydb_multi_region_cluster, name) do
          cluster_name_suffix attrs.cluster_name_suffix if attrs.cluster_name_suffix
          node_type attrs.node_type if attrs.node_type
          num_shards attrs.num_shards if attrs.num_shards
          description attrs.description if attrs.description
          engine attrs.engine if attrs.engine
          engine_version attrs.engine_version if attrs.engine_version
          
          # Apply tags if present
          if attrs.tags.any?
            tags do
              attrs.tags.each do |key, value|
                public_send(key, value)
              end
            end
          end
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_memorydb_multi_region_cluster',
          name: name,
          resource_attributes: attrs.to_h,
          outputs: {
            id: "${aws_memorydb_multi_region_cluster.#{name}.id}",
            arn: "${aws_memorydb_multi_region_cluster.#{name}.arn}",
            multi_region_cluster_name: "${aws_memorydb_multi_region_cluster.#{name}.multi_region_cluster_name}",
            status: "${aws_memorydb_multi_region_cluster.#{name}.status}"
          },
          computed_properties: {
            # Computed properties from type definitions
          }
        )
      end
    end
  end
end


# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)