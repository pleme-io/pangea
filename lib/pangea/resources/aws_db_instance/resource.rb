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
require 'pangea/resources/aws_db_instance/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS RDS Database Instance with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Database instance attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_db_instance(name, attributes = {})
        # Validate attributes using dry-struct
        db_attrs = Types::DbInstanceAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_db_instance, name) do
          identifier db_attrs.identifier if db_attrs.identifier
          identifier_prefix db_attrs.identifier_prefix if db_attrs.identifier_prefix
          
          # Engine configuration
          engine db_attrs.engine
          engine_version db_attrs.engine_version if db_attrs.engine_version
          
          # Instance specifications
          instance_class db_attrs.instance_class
          allocated_storage db_attrs.allocated_storage if db_attrs.allocated_storage
          storage_type db_attrs.storage_type if db_attrs.storage_type && db_attrs.allocated_storage
          storage_encrypted db_attrs.storage_encrypted
          kms_key_id db_attrs.kms_key_id if db_attrs.kms_key_id
          
          # IOPS configuration for io1/io2 storage
          if db_attrs.iops && %w[io1 io2].include?(db_attrs.storage_type)
            iops db_attrs.iops
          end
          
          # Database configuration
          db_name db_attrs.db_name if db_attrs.db_name
          username db_attrs.username if db_attrs.username
          password db_attrs.password if db_attrs.password
          manage_master_user_password db_attrs.manage_master_user_password if db_attrs.manage_master_user_password
          
          # Network configuration
          db_subnet_group_name db_attrs.db_subnet_group_name if db_attrs.db_subnet_group_name
          vpc_security_group_ids db_attrs.vpc_security_group_ids if db_attrs.vpc_security_group_ids.any?
          availability_zone db_attrs.availability_zone if db_attrs.availability_zone
          multi_az db_attrs.multi_az
          publicly_accessible db_attrs.publicly_accessible
          
          # Backup configuration
          backup_retention_period db_attrs.backup_retention_period
          backup_window db_attrs.backup_window if db_attrs.backup_window
          maintenance_window db_attrs.maintenance_window if db_attrs.maintenance_window
          
          # Performance and monitoring
          enabled_cloudwatch_logs_exports db_attrs.enabled_cloudwatch_logs_exports if db_attrs.enabled_cloudwatch_logs_exports.any?
          performance_insights_enabled db_attrs.performance_insights_enabled
          performance_insights_retention_period db_attrs.performance_insights_retention_period if db_attrs.performance_insights_enabled
          
          # Additional configurations
          auto_minor_version_upgrade db_attrs.auto_minor_version_upgrade
          deletion_protection db_attrs.deletion_protection
          skip_final_snapshot db_attrs.skip_final_snapshot
          final_snapshot_identifier db_attrs.final_snapshot_identifier if db_attrs.final_snapshot_identifier && !db_attrs.skip_final_snapshot
          
          # Apply tags if present
          if db_attrs.tags.any?
            tags do
              db_attrs.tags.each do |key, value|
                public_send(key, value)
              end
            end
          end
        end
        
        # Return resource reference with available outputs
        ref = ResourceReference.new(
          type: 'aws_db_instance',
          name: name,
          resource_attributes: db_attrs.to_h,
          outputs: {
            id: "${aws_db_instance.#{name}.id}",
            arn: "${aws_db_instance.#{name}.arn}",
            address: "${aws_db_instance.#{name}.address}",
            endpoint: "${aws_db_instance.#{name}.endpoint}",
            hosted_zone_id: "${aws_db_instance.#{name}.hosted_zone_id}",
            resource_id: "${aws_db_instance.#{name}.resource_id}",
            status: "${aws_db_instance.#{name}.status}",
            port: "${aws_db_instance.#{name}.port}"
          }
        )
        
        # Add computed properties via method delegation
        ref.define_singleton_method(:engine_family) { db_attrs.engine_family }
        ref.define_singleton_method(:is_aurora?) { db_attrs.is_aurora? }
        ref.define_singleton_method(:is_serverless?) { db_attrs.is_serverless? }
        ref.define_singleton_method(:requires_subnet_group?) { db_attrs.requires_subnet_group? }
        ref.define_singleton_method(:supports_encryption?) { db_attrs.supports_encryption? }
        ref.define_singleton_method(:estimated_monthly_cost) { db_attrs.estimated_monthly_cost }
        
        ref
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)