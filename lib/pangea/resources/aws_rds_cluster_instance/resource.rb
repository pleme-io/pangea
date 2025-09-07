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
require 'pangea/resources/aws_rds_cluster_instance/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS RDS Cluster Instance (Aurora) with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] RDS cluster instance attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_rds_cluster_instance(name, attributes = {})
        # Validate attributes using dry-struct
        instance_attrs = Types::RdsClusterInstanceAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_rds_cluster_instance, name) do
          identifier instance_attrs.identifier if instance_attrs.identifier
          identifier_prefix instance_attrs.identifier_prefix if instance_attrs.identifier_prefix
          
          # Cluster association (required)
          cluster_identifier instance_attrs.cluster_identifier
          
          # Instance configuration
          instance_class instance_attrs.instance_class
          engine instance_attrs.engine if instance_attrs.engine
          engine_version instance_attrs.engine_version if instance_attrs.engine_version
          
          # Availability and networking
          availability_zone instance_attrs.availability_zone if instance_attrs.availability_zone
          publicly_accessible instance_attrs.publicly_accessible
          
          # Parameter group
          db_parameter_group_name instance_attrs.db_parameter_group_name if instance_attrs.db_parameter_group_name
          
          # Monitoring configuration
          monitoring_interval instance_attrs.monitoring_interval if instance_attrs.monitoring_interval > 0
          monitoring_role_arn instance_attrs.monitoring_role_arn if instance_attrs.monitoring_role_arn
          
          # Performance Insights
          performance_insights_enabled instance_attrs.performance_insights_enabled if instance_attrs.performance_insights_enabled
          performance_insights_kms_key_id instance_attrs.performance_insights_kms_key_id if instance_attrs.performance_insights_kms_key_id
          performance_insights_retention_period instance_attrs.performance_insights_retention_period if instance_attrs.performance_insights_enabled
          
          # Backup and maintenance windows
          preferred_backup_window instance_attrs.preferred_backup_window if instance_attrs.preferred_backup_window
          preferred_maintenance_window instance_attrs.preferred_maintenance_window if instance_attrs.preferred_maintenance_window
          
          # Additional configurations
          auto_minor_version_upgrade instance_attrs.auto_minor_version_upgrade
          apply_immediately instance_attrs.apply_immediately if instance_attrs.apply_immediately
          copy_tags_to_snapshot instance_attrs.copy_tags_to_snapshot
          
          # CA certificate
          ca_cert_identifier instance_attrs.ca_cert_identifier if instance_attrs.ca_cert_identifier
          
          # Promotion tier for failover priority
          promotion_tier instance_attrs.promotion_tier
          
          # Apply tags if present
          if instance_attrs.tags.any?
            tags do
              instance_attrs.tags.each do |key, value|
                public_send(key, value)
              end
            end
          end
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_rds_cluster_instance',
          name: name,
          resource_attributes: instance_attrs.to_h,
          outputs: {
            id: "${aws_rds_cluster_instance.#{name}.id}",
            arn: "${aws_rds_cluster_instance.#{name}.arn}",
            identifier: "${aws_rds_cluster_instance.#{name}.identifier}",
            cluster_identifier: "${aws_rds_cluster_instance.#{name}.cluster_identifier}",
            endpoint: "${aws_rds_cluster_instance.#{name}.endpoint}",
            engine: "${aws_rds_cluster_instance.#{name}.engine}",
            engine_version_actual: "${aws_rds_cluster_instance.#{name}.engine_version_actual}",
            instance_class: "${aws_rds_cluster_instance.#{name}.instance_class}",
            port: "${aws_rds_cluster_instance.#{name}.port}",
            availability_zone: "${aws_rds_cluster_instance.#{name}.availability_zone}",
            publicly_accessible: "${aws_rds_cluster_instance.#{name}.publicly_accessible}",
            writer: "${aws_rds_cluster_instance.#{name}.writer}",
            db_parameter_group_name: "${aws_rds_cluster_instance.#{name}.db_parameter_group_name}",
            promotion_tier: "${aws_rds_cluster_instance.#{name}.promotion_tier}",
            performance_insights_enabled: "${aws_rds_cluster_instance.#{name}.performance_insights_enabled}",
            performance_insights_kms_key_id: "${aws_rds_cluster_instance.#{name}.performance_insights_kms_key_id}",
            monitoring_interval: "${aws_rds_cluster_instance.#{name}.monitoring_interval}",
            monitoring_role_arn: "${aws_rds_cluster_instance.#{name}.monitoring_role_arn}",
            preferred_backup_window: "${aws_rds_cluster_instance.#{name}.preferred_backup_window}",
            preferred_maintenance_window: "${aws_rds_cluster_instance.#{name}.preferred_maintenance_window}",
            ca_cert_identifier: "${aws_rds_cluster_instance.#{name}.ca_cert_identifier}",
            dbi_resource_id: "${aws_rds_cluster_instance.#{name}.dbi_resource_id}"
          },
          computed_properties: {
            is_serverless: instance_attrs.is_serverless?,
            is_burstable: instance_attrs.is_burstable?,
            is_memory_optimized: instance_attrs.is_memory_optimized?,
            is_graviton: instance_attrs.is_graviton?,
            instance_family: instance_attrs.instance_family,
            instance_size: instance_attrs.instance_size,
            can_be_writer: instance_attrs.can_be_writer?,
            is_likely_reader: instance_attrs.is_likely_reader?,
            role_description: instance_attrs.role_description,
            has_enhanced_monitoring: instance_attrs.has_enhanced_monitoring?,
            has_performance_insights: instance_attrs.has_performance_insights?,
            estimated_vcpus: instance_attrs.estimated_vcpus,
            estimated_memory_gb: instance_attrs.estimated_memory_gb,
            supports_performance_insights: instance_attrs.supports_performance_insights?,
            supports_enhanced_monitoring: instance_attrs.supports_enhanced_monitoring?,
            performance_characteristics: instance_attrs.performance_characteristics,
            estimated_monthly_cost: instance_attrs.estimated_monthly_cost
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)