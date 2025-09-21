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


require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
      # Type-safe attributes for AwsMemorydbMultiRegionCluster resources
      # Provides a MemoryDB Multi-Region Cluster resource.
      class MemorydbMultiRegionClusterAttributes < Dry::Struct
        attribute :cluster_name_suffix, Resources::Types::String
        attribute :node_type, Resources::Types::String
        attribute :num_shards, Resources::Types::Integer.optional
        attribute :description, Resources::Types::String.optional
        attribute :engine, Resources::Types::String.optional
        attribute :engine_version, Resources::Types::String.optional
        
        # Tags to apply to the resource
        attribute :tags, Resources::Types::AwsTags.default({}.freeze)

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)
          
          
          
          
          attrs
        end
        
        # TODO: Add computed properties specific to aws_memorydb_multi_region_cluster

      end
    end
      end
    end
  end
end