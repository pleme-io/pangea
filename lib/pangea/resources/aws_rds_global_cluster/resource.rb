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
require 'pangea/resources/aws_rds_global_cluster/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS RDS Global Cluster with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] RDS global cluster attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_rds_global_cluster(name, attributes = {})
        # Validate attributes using dry-struct
        global_attrs = Types::RdsGlobalClusterAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_rds_global_cluster, name) do
          global_cluster_identifier global_attrs.global_cluster_identifier if global_attrs.global_cluster_identifier
          engine global_attrs.engine
          engine_version global_attrs.engine_version if global_attrs.engine_version
          engine_lifecycle_support global_attrs.engine_lifecycle_support if global_attrs.engine_lifecycle_support
          
          # Database configuration (only for new global clusters)
          unless global_attrs.source_db_cluster_identifier
            database_name global_attrs.database_name if global_attrs.database_name
            master_username global_attrs.master_username if global_attrs.master_username
            master_password global_attrs.master_password if global_attrs.master_password
            manage_master_user_password global_attrs.manage_master_user_password if global_attrs.manage_master_user_password
            master_user_secret_kms_key_id global_attrs.master_user_secret_kms_key_id if global_attrs.master_user_secret_kms_key_id
          end
          
          # Source cluster (for migration from existing cluster)
          source_db_cluster_identifier global_attrs.source_db_cluster_identifier if global_attrs.source_db_cluster_identifier
          
          # Storage configuration
          storage_encrypted global_attrs.storage_encrypted
          kms_key_id global_attrs.kms_key_id if global_attrs.kms_key_id
          
          # Backup configuration
          if global_attrs.backup_configuration
            backup_configuration do
              backup_retention_period global_attrs.backup_configuration.backup_retention_period
              preferred_backup_window global_attrs.backup_configuration.preferred_backup_window if global_attrs.backup_configuration.preferred_backup_window
              copy_tags_to_snapshot global_attrs.backup_configuration.copy_tags_to_snapshot
            end
          end
          
          # Force destroy configuration
          force_destroy global_attrs.force_destroy if global_attrs.force_destroy
          
          # Apply tags if present
          if global_attrs.tags.any?
            tags do
              global_attrs.tags.each do |key, value|
                public_send(key, value)
              end
            end
          end
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_rds_global_cluster',
          name: name,
          resource_attributes: global_attrs.to_h,
          outputs: {
            id: "${aws_rds_global_cluster.#{name}.id}",
            arn: "${aws_rds_global_cluster.#{name}.arn}",
            global_cluster_identifier: "${aws_rds_global_cluster.#{name}.global_cluster_identifier}",
            global_cluster_resource_id: "${aws_rds_global_cluster.#{name}.global_cluster_resource_id}",
            engine: "${aws_rds_global_cluster.#{name}.engine}",
            engine_version_actual: "${aws_rds_global_cluster.#{name}.engine_version_actual}",
            database_name: "${aws_rds_global_cluster.#{name}.database_name}",
            master_username: "${aws_rds_global_cluster.#{name}.master_username}",
            master_user_secret: "${aws_rds_global_cluster.#{name}.master_user_secret}",
            storage_encrypted: "${aws_rds_global_cluster.#{name}.storage_encrypted}",
            kms_key_id: "${aws_rds_global_cluster.#{name}.kms_key_id}",
            global_cluster_members: "${aws_rds_global_cluster.#{name}.global_cluster_members}",
            tags: "${aws_rds_global_cluster.#{name}.tags}",
            tags_all: "${aws_rds_global_cluster.#{name}.tags_all}"
          },
          computed_properties: {
            engine_family: global_attrs.engine_family,
            engine_major_version: global_attrs.engine_major_version,
            is_mysql: global_attrs.is_mysql?,
            is_postgresql: global_attrs.is_postgresql?,
            uses_managed_password: global_attrs.uses_managed_password?,
            created_from_source: global_attrs.created_from_source?,
            is_encrypted: global_attrs.is_encrypted?,
            allows_force_destroy: global_attrs.allows_force_destroy?,
            has_backup_configuration: global_attrs.has_backup_configuration?,
            effective_backup_retention_period: global_attrs.effective_backup_retention_period,
            effective_backup_window: global_attrs.effective_backup_window,
            supported_regions: global_attrs.supported_regions,
            configuration_summary: global_attrs.configuration_summary,
            estimated_monthly_cost: global_attrs.estimated_monthly_cost
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)