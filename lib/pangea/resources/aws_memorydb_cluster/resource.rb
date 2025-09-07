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
require 'pangea/resources/aws_memorydb_cluster/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Provides a MemoryDB Cluster resource for Redis-compatible in-memory database.
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Resource attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_memorydb_cluster(name, attributes = {})
        # Validate attributes using dry-struct
        attrs = Types::MemorydbClusterAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_memorydb_cluster, name) do
          name attrs.name if attrs.name
          node_type attrs.node_type if attrs.node_type
          num_shards attrs.num_shards if attrs.num_shards
          num_replicas_per_shard attrs.num_replicas_per_shard if attrs.num_replicas_per_shard
          subnet_group_name attrs.subnet_group_name if attrs.subnet_group_name
          security_group_ids attrs.security_group_ids if attrs.security_group_ids
          maintenance_window attrs.maintenance_window if attrs.maintenance_window
          port attrs.port if attrs.port
          parameter_group_name attrs.parameter_group_name if attrs.parameter_group_name
          snapshot_retention_limit attrs.snapshot_retention_limit if attrs.snapshot_retention_limit
          snapshot_window attrs.snapshot_window if attrs.snapshot_window
          acl_name attrs.acl_name if attrs.acl_name
          engine_version attrs.engine_version if attrs.engine_version
          tls_enabled attrs.tls_enabled if attrs.tls_enabled
          kms_key_id attrs.kms_key_id if attrs.kms_key_id
          snapshot_arns attrs.snapshot_arns if attrs.snapshot_arns
          snapshot_name attrs.snapshot_name if attrs.snapshot_name
          final_snapshot_name attrs.final_snapshot_name if attrs.final_snapshot_name
          description attrs.description if attrs.description
          sns_topic_arn attrs.sns_topic_arn if attrs.sns_topic_arn
          auto_minor_version_upgrade attrs.auto_minor_version_upgrade if attrs.auto_minor_version_upgrade
          data_tiering attrs.data_tiering if attrs.data_tiering
          
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
          type: 'aws_memorydb_cluster',
          name: name,
          resource_attributes: attrs.to_h,
          outputs: {
            id: "${aws_memorydb_cluster.#{name}.id}",
            arn: "${aws_memorydb_cluster.#{name}.arn}",
            cluster_endpoint: "${aws_memorydb_cluster.#{name}.cluster_endpoint}",
            shards: "${aws_memorydb_cluster.#{name}.shards}",
            status: "${aws_memorydb_cluster.#{name}.status}",
            engine_patch_version: "${aws_memorydb_cluster.#{name}.engine_patch_version}"
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