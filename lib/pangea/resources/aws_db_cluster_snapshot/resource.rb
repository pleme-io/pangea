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
require 'pangea/resources/aws_db_cluster_snapshot/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS DB Cluster Snapshot with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] DB cluster snapshot attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_db_cluster_snapshot(name, attributes = {})
        # Validate attributes using dry-struct
        snapshot_attrs = Types::DbClusterSnapshotAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_rds_cluster_snapshot, name) do
          db_cluster_identifier snapshot_attrs.db_cluster_identifier
          db_cluster_snapshot_identifier snapshot_attrs.db_cluster_snapshot_identifier
          
          # Apply tags if present
          if snapshot_attrs.tags.any?
            tags do
              snapshot_attrs.tags.each do |key, value|
                public_send(key, value)
              end
            end
          end
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_rds_cluster_snapshot',
          name: name,
          resource_attributes: snapshot_attrs.to_h,
          outputs: {
            id: "${aws_rds_cluster_snapshot.#{name}.id}",
            arn: "${aws_rds_cluster_snapshot.#{name}.db_cluster_snapshot_arn}",
            db_cluster_identifier: "${aws_rds_cluster_snapshot.#{name}.db_cluster_identifier}",
            db_cluster_snapshot_identifier: "${aws_rds_cluster_snapshot.#{name}.db_cluster_snapshot_identifier}",
            allocated_storage: "${aws_rds_cluster_snapshot.#{name}.allocated_storage}",
            availability_zones: "${aws_rds_cluster_snapshot.#{name}.availability_zones}",
            db_cluster_snapshot_arn: "${aws_rds_cluster_snapshot.#{name}.db_cluster_snapshot_arn}",
            engine: "${aws_rds_cluster_snapshot.#{name}.engine}",
            engine_version: "${aws_rds_cluster_snapshot.#{name}.engine_version}",
            kms_key_id: "${aws_rds_cluster_snapshot.#{name}.kms_key_id}",
            license_model: "${aws_rds_cluster_snapshot.#{name}.license_model}",
            master_username: "${aws_rds_cluster_snapshot.#{name}.master_username}",
            port: "${aws_rds_cluster_snapshot.#{name}.port}",
            snapshot_create_time: "${aws_rds_cluster_snapshot.#{name}.snapshot_create_time}",
            snapshot_type: "${aws_rds_cluster_snapshot.#{name}.snapshot_type}",
            source_db_cluster_snapshot_arn: "${aws_rds_cluster_snapshot.#{name}.source_db_cluster_snapshot_arn}",
            status: "${aws_rds_cluster_snapshot.#{name}.status}",
            storage_encrypted: "${aws_rds_cluster_snapshot.#{name}.storage_encrypted}",
            vpc_id: "${aws_rds_cluster_snapshot.#{name}.vpc_id}",
            tags: "${aws_rds_cluster_snapshot.#{name}.tags}",
            tags_all: "${aws_rds_cluster_snapshot.#{name}.tags_all}"
          },
          computed_properties: {
            follows_naming_convention: snapshot_attrs.follows_naming_convention?,
            base_name: snapshot_attrs.base_name,
            timestamp: snapshot_attrs.timestamp,
            age_in_days: snapshot_attrs.age_in_days,
            is_global_cluster_snapshot: snapshot_attrs.is_global_cluster_snapshot?,
            is_aurora_snapshot: snapshot_attrs.is_aurora_snapshot?,
            snapshot_summary: snapshot_attrs.snapshot_summary,
            estimated_monthly_storage_cost: snapshot_attrs.estimated_monthly_storage_cost,
            recommended_retention_days: snapshot_attrs.recommended_retention_days
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)