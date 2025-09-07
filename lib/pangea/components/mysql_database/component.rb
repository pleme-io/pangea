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


require 'pangea/components/base'
require 'pangea/components/mysql_database/types'
require 'pangea/resources/aws'

module Pangea
  module Components
    # MySQL Database component with backups, monitoring, and security
    # Creates a production-ready RDS MySQL instance with comprehensive features
    def mysql_database(name, attributes = {})
      include Base
      include Resources::AWS
      
      # Validate and set defaults
      component_attrs = MySqlDatabase::MySqlDatabaseAttributes.new(attributes)
      
      # Generate component-specific tags
      component_tag_set = component_tags('MySqlDatabase', name, component_attrs.tags)
      
      resources = {}
      
      # Create DB Subnet Group
      subnet_group_name = component_attrs.db_subnet_group_name || "#{name}-db-subnet-group"
      
      subnet_group_ref = aws_db_subnet_group(component_resource_name(name, :subnet_group), {
        name: subnet_group_name,
        description: "DB subnet group for #{name} MySQL database",
        subnet_ids: component_attrs.subnet_refs.map(&:id),
        tags: component_tag_set
      })
      resources[:subnet_group] = subnet_group_ref
      
      # Create DB Parameter Group if requested
      parameter_group_ref = nil
      if component_attrs.parameter_config.create_parameter_group
        pg_name = component_attrs.parameter_config.parameter_group_name || "#{name}-mysql-params"
        
        parameter_group_ref = aws_db_parameter_group(component_resource_name(name, :parameter_group), {
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
        resources[:parameter_group] = parameter_group_ref
      end
      
      # Determine final snapshot identifier
      final_snapshot_id = if component_attrs.backup.skip_final_snapshot
        nil
      else
        component_attrs.backup.final_snapshot_identifier || "#{name}-final-snapshot-#{Time.now.to_i}"
      end
      
      # Create the RDS instance
      db_identifier = component_attrs.identifier || "#{name}-mysql-db"
      
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
      
      # Handle restore scenarios
      if component_attrs.restore_from_snapshot && component_attrs.snapshot_identifier
        rds_attrs[:snapshot_identifier] = component_attrs.snapshot_identifier
        # Remove certain attributes not compatible with snapshot restore
        rds_attrs.delete(:db_name)
        rds_attrs.delete(:username)
        rds_attrs.delete(:password)
        rds_attrs.delete(:manage_master_user_password)
      elsif component_attrs.restore_to_point_in_time
        rds_attrs.merge!(component_attrs.restore_to_point_in_time)
      end
      
      db_instance_ref = aws_db_instance(component_resource_name(name, :db_instance), rds_attrs)
      resources[:db_instance] = db_instance_ref
      
      # Create read replicas if requested
      read_replicas = {}
      if component_attrs.create_read_replica
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
        resources[:read_replicas] = read_replicas unless read_replicas.empty?
      end
      
      # Create CloudWatch alarms for monitoring
      alarms = {}
      
      # CPU Utilization alarm
      cpu_alarm = aws_cloudwatch_metric_alarm(component_resource_name(name, :alarm, :cpu_high), {
        alarm_name: "#{name}-rds-cpu-utilization-high",
        comparison_operator: "GreaterThanThreshold",
        evaluation_periods: "2",
        metric_name: "CPUUtilization", 
        namespace: "AWS/RDS",
        period: "300",
        statistic: "Average",
        threshold: "80.0",
        alarm_description: "RDS instance CPU utilization is high",
        dimensions: {
          DBInstanceIdentifier: db_instance_ref.identifier
        },
        tags: component_tag_set
      })
      alarms[:cpu_high] = cpu_alarm
      
      # Database connections alarm
      connections_alarm = aws_cloudwatch_metric_alarm(component_resource_name(name, :alarm, :connections_high), {
        alarm_name: "#{name}-rds-connections-high",
        comparison_operator: "GreaterThanThreshold",
        evaluation_periods: "2",
        metric_name: "DatabaseConnections",
        namespace: "AWS/RDS",
        period: "300",
        statistic: "Average",
        threshold: "80",
        alarm_description: "RDS instance has high number of connections",
        dimensions: {
          DBInstanceIdentifier: db_instance_ref.identifier
        },
        tags: component_tag_set
      })
      alarms[:connections_high] = connections_alarm
      
      # Free storage space alarm
      storage_alarm = aws_cloudwatch_metric_alarm(component_resource_name(name, :alarm, :storage_low), {
        alarm_name: "#{name}-rds-free-storage-low",
        comparison_operator: "LessThanThreshold",
        evaluation_periods: "1",
        metric_name: "FreeStorageSpace",
        namespace: "AWS/RDS",
        period: "300",
        statistic: "Average",
        threshold: "2000000000", # 2GB in bytes
        alarm_description: "RDS instance is running low on storage",
        dimensions: {
          DBInstanceIdentifier: db_instance_ref.identifier
        },
        tags: component_tag_set
      })
      alarms[:storage_low] = storage_alarm
      
      # Read latency alarm (if applicable)
      read_latency_alarm = aws_cloudwatch_metric_alarm(component_resource_name(name, :alarm, :read_latency), {
        alarm_name: "#{name}-rds-read-latency-high",
        comparison_operator: "GreaterThanThreshold",
        evaluation_periods: "2",
        metric_name: "ReadLatency",
        namespace: "AWS/RDS",
        period: "300",
        statistic: "Average",
        threshold: "0.2",
        alarm_description: "RDS read latency is high",
        dimensions: {
          DBInstanceIdentifier: db_instance_ref.identifier
        },
        tags: component_tag_set
      })
      alarms[:read_latency] = read_latency_alarm
      
      # Write latency alarm
      write_latency_alarm = aws_cloudwatch_metric_alarm(component_resource_name(name, :alarm, :write_latency), {
        alarm_name: "#{name}-rds-write-latency-high",
        comparison_operator: "GreaterThanThreshold",
        evaluation_periods: "2",
        metric_name: "WriteLatency",
        namespace: "AWS/RDS",
        period: "300",
        statistic: "Average",
        threshold: "0.2",
        alarm_description: "RDS write latency is high",
        dimensions: {
          DBInstanceIdentifier: db_instance_ref.identifier
        },
        tags: component_tag_set
      })
      alarms[:write_latency] = write_latency_alarm
      
      resources[:alarms] = alarms
      
      # Calculate outputs
      outputs = {
        db_instance_identifier: db_instance_ref.identifier,
        db_instance_arn: db_instance_ref.arn,
        db_instance_endpoint: db_instance_ref.endpoint,
        db_instance_hosted_zone_id: db_instance_ref.hosted_zone_id,
        db_instance_port: db_instance_ref.port,
        db_instance_status: db_instance_ref.status,
        db_subnet_group_name: subnet_group_ref.name,
        parameter_group_name: parameter_group_ref&.name,
        read_replica_identifiers: read_replicas.transform_values(&:identifier),
        security_features: [
          ("Encryption at Rest" if component_attrs.storage_encrypted),
          ("Multi-AZ Deployment" if component_attrs.multi_az),
          ("Automated Backups" if component_attrs.backup.backup_retention_period > 0),
          ("Performance Insights" if component_attrs.monitoring.performance_insights_enabled),
          ("Enhanced Monitoring" if component_attrs.monitoring.monitoring_interval > 0),
          ("Deletion Protection" if component_attrs.deletion_protection),
          ("Private Deployment" if !component_attrs.publicly_accessible),
          ("CloudWatch Logs" if component_attrs.enabled_cloudwatch_logs_exports.any?),
          ("Parameter Group Optimization" if parameter_group_ref),
          ("Read Replicas" if component_attrs.create_read_replica)
        ].compact,
        backup_retention_days: component_attrs.backup.backup_retention_period,
        maintenance_window: component_attrs.maintenance.maintenance_window,
        backup_window: component_attrs.backup.backup_window,
        multi_az_enabled: component_attrs.multi_az,
        storage_encrypted: component_attrs.storage_encrypted,
        estimated_monthly_cost: estimate_rds_monthly_cost(
          component_attrs.db_instance_class,
          component_attrs.allocated_storage,
          component_attrs.multi_az,
          component_attrs.create_read_replica ? component_attrs.read_replica_count : 0
        )
      }
      
      create_component_reference(
        'mysql_database',
        name,
        component_attrs.to_h,
        resources,
        outputs
      )
    end
    
    private
    
    def estimate_rds_monthly_cost(instance_class, storage_gb, multi_az, read_replica_count)
      base_cost = case instance_class
      when /^db\.t3\.micro$/
        15.0
      when /^db\.t3\.small$/
        30.0
      when /^db\.t3\.medium$/
        60.0
      when /^db\.t3\.large$/
        120.0
      when /^db\.r5\.large$/
        150.0
      when /^db\.m5\.large$/
        140.0
      else
        75.0  # Default estimate
      end
      
      # Multi-AZ doubles the instance cost
      instance_cost = multi_az ? base_cost * 2 : base_cost
      
      # Storage cost (approximate)
      storage_cost = storage_gb * 0.115  # GP3 pricing
      
      # Read replica cost
      replica_cost = read_replica_count * base_cost
      
      # Backup storage (estimated as 20% of allocated storage)
      backup_cost = storage_gb * 0.2 * 0.095
      
      (instance_cost + storage_cost + replica_cost + backup_cost).round(2)
    end
  end
end