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
  module Components
    module MySqlDatabaseComponent
      # Database creation methods for MySQL component
      module Database
        # Create DB Subnet Group
        def create_subnet_group(name, component_attrs, component_tag_set)
          subnet_group_name = component_attrs.db_subnet_group_name || "#{name}-db-subnet-group"

          aws_db_subnet_group(component_resource_name(name, :subnet_group), {
            name: subnet_group_name,
            description: "DB subnet group for #{name} MySQL database",
            subnet_ids: component_attrs.subnet_refs.map(&:id),
            tags: component_tag_set
          })
        end

        # Create DB Parameter Group if requested
        def create_parameter_group(name, component_attrs, component_tag_set)
          return nil unless component_attrs.parameter_config.create_parameter_group

          pg_name = component_attrs.parameter_config.parameter_group_name || "#{name}-mysql-params"

          aws_db_parameter_group(component_resource_name(name, :parameter_group), {
            name: pg_name,
            family: component_attrs.parameter_config.parameter_group_family,
            description: "Parameter group for #{name} MySQL database",
            parameter: component_attrs.parameter_config.parameters.map do |param_name, param_value|
              {
                name: param_name,
                value: param_value
              }
            end,
            tags: component_tag_set
          })
        end

        # Build RDS instance attributes
        def build_rds_attributes(name, component_attrs, subnet_group_ref, parameter_group_ref, component_tag_set)
          db_identifier = component_attrs.identifier || "#{name}-mysql-db"
          final_snapshot_id = determine_final_snapshot_id(name, component_attrs)

          rds_attrs = {
            identifier: db_identifier,
            engine: component_attrs.engine,
            engine_version: component_attrs.engine_version,
            instance_class: component_attrs.db_instance_class,
            allocated_storage: component_attrs.allocated_storage,
            max_allocated_storage: component_attrs.max_allocated_storage,
            storage_type: component_attrs.storage_type,
            iops: component_attrs.iops,
            storage_throughput: component_attrs.storage_throughput,
            db_name: component_attrs.db_name,
            username: component_attrs.username,
            manage_master_user_password: component_attrs.manage_master_user_password,
            password: component_attrs.password,
            kms_key_id: component_attrs.kms_key_id,
            multi_az: component_attrs.multi_az,
            availability_zone: component_attrs.availability_zone,
            storage_encrypted: component_attrs.storage_encrypted,
            publicly_accessible: component_attrs.publicly_accessible,
            port: component_attrs.port,
            db_subnet_group_name: subnet_group_ref.name,
            vpc_security_group_ids: component_attrs.security_group_refs.map(&:id),
            parameter_group_name: parameter_group_ref&.name,
            option_group_name: component_attrs.option_group_name,
            backup_retention_period: component_attrs.backup.backup_retention_period,
            backup_window: component_attrs.backup.backup_window,
            maintenance_window: component_attrs.maintenance.maintenance_window,
            auto_minor_version_upgrade: component_attrs.maintenance.auto_minor_version_upgrade,
            allow_major_version_upgrade: component_attrs.maintenance.allow_major_version_upgrade,
            monitoring_interval: component_attrs.monitoring.monitoring_interval,
            monitoring_role_arn: component_attrs.monitoring.monitoring_role_arn,
            performance_insights_enabled: component_attrs.monitoring.performance_insights_enabled,
            performance_insights_retention_period: component_attrs.monitoring.performance_insights_retention_period,
            performance_insights_kms_key_id: component_attrs.monitoring.performance_insights_kms_key_id,
            enabled_cloudwatch_logs_exports: component_attrs.enabled_cloudwatch_logs_exports,
            copy_tags_to_snapshot: component_attrs.backup.copy_tags_to_snapshot,
            delete_automated_backups: component_attrs.backup.delete_automated_backups,
            skip_final_snapshot: component_attrs.backup.skip_final_snapshot,
            final_snapshot_identifier: final_snapshot_id,
            deletion_protection: component_attrs.deletion_protection,
            character_set_name: component_attrs.character_set_name,
            blue_green_update: component_attrs.blue_green_update,
            tags: component_tag_set
          }.compact

          apply_restore_options(rds_attrs, component_attrs)
        end

        # Create read replicas if requested
        def create_read_replicas(name, component_attrs, db_instance_ref, component_tag_set)
          return {} unless component_attrs.create_read_replica

          db_identifier = component_attrs.identifier || "#{name}-mysql-db"
          read_replicas = {}

          (1..component_attrs.read_replica_count).each do |i|
            replica_identifier = "#{db_identifier}-replica-#{i}"
            replica_instance_class = component_attrs.read_replica_instance_class || component_attrs.db_instance_class

            replica_ref = aws_db_instance(component_resource_name(name, :read_replica, "replica#{i}".to_sym), {
              identifier: replica_identifier,
              replicate_source_db: db_instance_ref.identifier,
              instance_class: replica_instance_class,
              storage_encrypted: component_attrs.storage_encrypted,
              kms_key_id: component_attrs.kms_key_id,
              publicly_accessible: component_attrs.publicly_accessible,
              monitoring_interval: component_attrs.monitoring.monitoring_interval,
              monitoring_role_arn: component_attrs.monitoring.monitoring_role_arn,
              performance_insights_enabled: component_attrs.monitoring.performance_insights_enabled,
              auto_minor_version_upgrade: component_attrs.maintenance.auto_minor_version_upgrade,
              skip_final_snapshot: true,
              copy_tags_to_snapshot: component_attrs.backup.copy_tags_to_snapshot,
              tags: component_tag_set.merge({
                Name: "#{name}-mysql-replica-#{i}",
                Role: "ReadReplica"
              })
            })
            read_replicas["replica#{i}".to_sym] = replica_ref
          end

          read_replicas
        end

        private

        def determine_final_snapshot_id(name, component_attrs)
          if component_attrs.backup.skip_final_snapshot
            nil
          else
            component_attrs.backup.final_snapshot_identifier || "#{name}-final-snapshot-#{Time.now.to_i}"
          end
        end

        def apply_restore_options(rds_attrs, component_attrs)
          if component_attrs.restore_from_snapshot && component_attrs.snapshot_identifier
            rds_attrs[:snapshot_identifier] = component_attrs.snapshot_identifier
            rds_attrs.delete(:db_name)
            rds_attrs.delete(:username)
            rds_attrs.delete(:password)
            rds_attrs.delete(:manage_master_user_password)
          elsif component_attrs.restore_to_point_in_time
            rds_attrs.merge!(component_attrs.restore_to_point_in_time)
          end

          rds_attrs
        end
      end
    end
  end
end
