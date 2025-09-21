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
      # Type-safe attributes for AwsMemorydbCluster resources
      # Provides a MemoryDB Cluster resource for Redis-compatible in-memory database.
      class MemorydbClusterAttributes < Dry::Struct
        attribute :name, Resources::Types::String
        attribute :node_type, Resources::Types::String
        attribute :num_shards, Resources::Types::Integer.optional
        attribute :num_replicas_per_shard, Resources::Types::Integer.optional
        attribute :subnet_group_name, Resources::Types::String.optional
        attribute :security_group_ids, Resources::Types::Array.of(Types::String).default([].freeze).optional
        attribute :maintenance_window, Resources::Types::String.optional
        attribute :port, Resources::Types::Integer.optional
        attribute :parameter_group_name, Resources::Types::String.optional
        attribute :snapshot_retention_limit, Resources::Types::Integer.optional
        attribute :snapshot_window, Resources::Types::String.optional
        attribute :acl_name, Resources::Types::String
        attribute :engine_version, Resources::Types::String.optional
        attribute :tls_enabled, Resources::Types::Bool.optional
        attribute :kms_key_id, Resources::Types::String.optional
        attribute :snapshot_arns, Resources::Types::Array.of(Types::String).default([].freeze).optional
        attribute :snapshot_name, Resources::Types::String.optional
        attribute :final_snapshot_name, Resources::Types::String.optional
        attribute :description, Resources::Types::String.optional
        attribute :sns_topic_arn, Resources::Types::String.optional
        attribute :auto_minor_version_upgrade, Resources::Types::Bool.optional
        attribute :data_tiering, Resources::Types::Bool.optional
        
        # Tags to apply to the resource
        attribute :tags, Resources::Types::AwsTags.default({}.freeze)

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)
          
          
          
          
          attrs
        end
        
        # TODO: Add computed properties specific to aws_memorydb_cluster

      end
    end
      end
    end
  end
end