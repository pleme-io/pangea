# frozen_string_literal: true

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
        attribute :tags, Resources::Types::AwsTags.default({})

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