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
require 'pangea/resources/aws_rds_cluster/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS RDS Cluster (Aurora) with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] RDS cluster attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_rds_cluster(name, attributes = {})
        # Validate attributes using dry-struct
        cluster_attrs = Types::RdsClusterAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_rds_cluster, name) do
          cluster_identifier cluster_attrs.cluster_identifier if cluster_attrs.cluster_identifier
          cluster_identifier_prefix cluster_attrs.cluster_identifier_prefix if cluster_attrs.cluster_identifier_prefix
          
          # Engine configuration
          engine cluster_attrs.engine
          engine_version cluster_attrs.engine_version if cluster_attrs.engine_version
          engine_mode cluster_attrs.engine_mode if cluster_attrs.engine_mode != "provisioned"
          
          # Database configuration
          database_name cluster_attrs.database_name if cluster_attrs.database_name
          master_username cluster_attrs.master_username if cluster_attrs.master_username
          master_password cluster_attrs.master_password if cluster_attrs.master_password
          manage_master_user_password cluster_attrs.manage_master_user_password if cluster_attrs.manage_master_user_password
          master_user_secret_kms_key_id cluster_attrs.master_user_secret_kms_key_id if cluster_attrs.master_user_secret_kms_key_id
          
          # Network configuration
          db_subnet_group_name cluster_attrs.db_subnet_group_name if cluster_attrs.db_subnet_group_name
          vpc_security_group_ids cluster_attrs.vpc_security_group_ids if cluster_attrs.vpc_security_group_ids.any?
          availability_zones cluster_attrs.availability_zones if cluster_attrs.availability_zones && cluster_attrs.availability_zones.any?
          db_cluster_parameter_group_name cluster_attrs.db_cluster_parameter_group_name if cluster_attrs.db_cluster_parameter_group_name
          port cluster_attrs.port if cluster_attrs.port
          
          # Backup configuration
          backup_retention_period cluster_attrs.backup_retention_period
          preferred_backup_window cluster_attrs.preferred_backup_window if cluster_attrs.preferred_backup_window
          preferred_maintenance_window cluster_attrs.preferred_maintenance_window if cluster_attrs.preferred_maintenance_window
          copy_tags_to_snapshot cluster_attrs.copy_tags_to_snapshot
          
          # Storage configuration
          storage_encrypted cluster_attrs.storage_encrypted
          kms_key_id cluster_attrs.kms_key_id if cluster_attrs.kms_key_id
          storage_type cluster_attrs.storage_type if cluster_attrs.storage_type
          allocated_storage cluster_attrs.allocated_storage if cluster_attrs.allocated_storage
          iops cluster_attrs.iops if cluster_attrs.iops
          
          # Global cluster
          global_cluster_identifier cluster_attrs.global_cluster_identifier if cluster_attrs.global_cluster_identifier
          
          # Serverless v1 scaling (deprecated)
          if cluster_attrs.scaling_configuration
            scaling_configuration do
              cluster_attrs.scaling_configuration.each do |key, value|
                public_send(key, value)
              end
            end
          end
          
          # Serverless v2 scaling
          if cluster_attrs.serverless_v2_scaling_configuration
            serverless_v2_scaling_configuration do
              min_capacity cluster_attrs.serverless_v2_scaling_configuration.min_capacity
              max_capacity cluster_attrs.serverless_v2_scaling_configuration.max_capacity
            end
          end
          
          # Point-in-time restore
          if cluster_attrs.restore_to_point_in_time
            restore_to_point_in_time do
              source_cluster_identifier cluster_attrs.restore_to_point_in_time.source_cluster_identifier
              restore_to_time cluster_attrs.restore_to_point_in_time.restore_to_time if cluster_attrs.restore_to_point_in_time.restore_to_time
              use_latest_restorable_time cluster_attrs.restore_to_point_in_time.use_latest_restorable_time if cluster_attrs.restore_to_point_in_time.use_latest_restorable_time
              restore_type cluster_attrs.restore_to_point_in_time.restore_type if cluster_attrs.restore_to_point_in_time.restore_type
            end
          end
          
          # Snapshot restore
          snapshot_identifier cluster_attrs.snapshot_identifier if cluster_attrs.snapshot_identifier
          source_region cluster_attrs.source_region if cluster_attrs.source_region
          
          # Monitoring and logging
          enabled_cloudwatch_logs_exports cluster_attrs.enabled_cloudwatch_logs_exports if cluster_attrs.enabled_cloudwatch_logs_exports.any?
          monitoring_interval cluster_attrs.monitoring_interval if cluster_attrs.monitoring_interval > 0
          monitoring_role_arn cluster_attrs.monitoring_role_arn if cluster_attrs.monitoring_role_arn
          performance_insights_enabled cluster_attrs.performance_insights_enabled if cluster_attrs.performance_insights_enabled
          performance_insights_kms_key_id cluster_attrs.performance_insights_kms_key_id if cluster_attrs.performance_insights_kms_key_id
          performance_insights_retention_period cluster_attrs.performance_insights_retention_period if cluster_attrs.performance_insights_enabled
          
          # Backtrack (Aurora MySQL only)
          backtrack_window cluster_attrs.backtrack_window if cluster_attrs.backtrack_window
          
          # Additional configurations
          apply_immediately cluster_attrs.apply_immediately if cluster_attrs.apply_immediately
          auto_minor_version_upgrade cluster_attrs.auto_minor_version_upgrade
          deletion_protection cluster_attrs.deletion_protection
          skip_final_snapshot cluster_attrs.skip_final_snapshot
          final_snapshot_identifier cluster_attrs.final_snapshot_identifier if cluster_attrs.final_snapshot_identifier
          
          # Enable HTTP endpoint for Aurora Serverless
          enable_http_endpoint cluster_attrs.enable_http_endpoint if cluster_attrs.enable_http_endpoint
          
          # Apply tags if present
          if cluster_attrs.tags.any?
            tags do
              cluster_attrs.tags.each do |key, value|
                public_send(key, value)
              end
            end
          end
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_rds_cluster',
          name: name,
          resource_attributes: cluster_attrs.to_h,
          outputs: {
            id: "${aws_rds_cluster.#{name}.id}",
            arn: "${aws_rds_cluster.#{name}.arn}",
            cluster_identifier: "${aws_rds_cluster.#{name}.cluster_identifier}",
            cluster_resource_id: "${aws_rds_cluster.#{name}.cluster_resource_id}",
            endpoint: "${aws_rds_cluster.#{name}.endpoint}",
            reader_endpoint: "${aws_rds_cluster.#{name}.reader_endpoint}",
            engine_version_actual: "${aws_rds_cluster.#{name}.engine_version_actual}",
            port: "${aws_rds_cluster.#{name}.port}",
            database_name: "${aws_rds_cluster.#{name}.database_name}",
            master_username: "${aws_rds_cluster.#{name}.master_username}",
            master_user_secret: "${aws_rds_cluster.#{name}.master_user_secret}",
            hosted_zone_id: "${aws_rds_cluster.#{name}.hosted_zone_id}",
            cluster_members: "${aws_rds_cluster.#{name}.cluster_members}",
            availability_zones: "${aws_rds_cluster.#{name}.availability_zones}",
            backup_retention_period: "${aws_rds_cluster.#{name}.backup_retention_period}",
            preferred_backup_window: "${aws_rds_cluster.#{name}.preferred_backup_window}",
            preferred_maintenance_window: "${aws_rds_cluster.#{name}.preferred_maintenance_window}",
            vpc_security_group_ids: "${aws_rds_cluster.#{name}.vpc_security_group_ids}",
            db_subnet_group_name: "${aws_rds_cluster.#{name}.db_subnet_group_name}",
            db_cluster_parameter_group_name: "${aws_rds_cluster.#{name}.db_cluster_parameter_group_name}",
            storage_encrypted: "${aws_rds_cluster.#{name}.storage_encrypted}",
            kms_key_id: "${aws_rds_cluster.#{name}.kms_key_id}"
          },
          computed_properties: {
            engine_family: cluster_attrs.engine_family,
            is_mysql: cluster_attrs.is_mysql?,
            is_postgresql: cluster_attrs.is_postgresql?,
            is_serverless: cluster_attrs.is_serverless?,
            is_global: cluster_attrs.is_global?,
            effective_port: cluster_attrs.effective_port,
            has_enhanced_monitoring: cluster_attrs.has_enhanced_monitoring?,
            has_performance_insights: cluster_attrs.has_performance_insights?,
            has_backtrack: cluster_attrs.has_backtrack?,
            has_http_endpoint: cluster_attrs.has_http_endpoint?,
            supports_backtrack: cluster_attrs.supports_backtrack?,
            supports_global: cluster_attrs.supports_global?,
            supports_serverless_v2: cluster_attrs.supports_serverless_v2?,
            default_cloudwatch_logs_exports: cluster_attrs.default_cloudwatch_logs_exports,
            estimated_monthly_cost: cluster_attrs.estimated_monthly_cost
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)