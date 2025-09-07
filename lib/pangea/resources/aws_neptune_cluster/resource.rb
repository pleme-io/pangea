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
require 'pangea/resources/aws_neptune_cluster/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Provides a Neptune Cluster resource for graph database workloads.
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Resource attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_neptune_cluster(name, attributes = {})
        # Validate attributes using dry-struct
        attrs = Types::NeptuneClusterAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_neptune_cluster, name) do
          cluster_identifier attrs.cluster_identifier if attrs.cluster_identifier
          engine attrs.engine if attrs.engine
          engine_version attrs.engine_version if attrs.engine_version
          backup_retention_period attrs.backup_retention_period if attrs.backup_retention_period
          preferred_backup_window attrs.preferred_backup_window if attrs.preferred_backup_window
          preferred_maintenance_window attrs.preferred_maintenance_window if attrs.preferred_maintenance_window
          port attrs.port if attrs.port
          vpc_security_group_ids attrs.vpc_security_group_ids if attrs.vpc_security_group_ids
          neptune_subnet_group_name attrs.neptune_subnet_group_name if attrs.neptune_subnet_group_name
          neptune_cluster_parameter_group_name attrs.neptune_cluster_parameter_group_name if attrs.neptune_cluster_parameter_group_name
          storage_encrypted attrs.storage_encrypted if attrs.storage_encrypted
          kms_key_id attrs.kms_key_id if attrs.kms_key_id
          iam_database_authentication_enabled attrs.iam_database_authentication_enabled if attrs.iam_database_authentication_enabled
          iam_roles attrs.iam_roles if attrs.iam_roles
          enable_cloudwatch_logs_exports attrs.enable_cloudwatch_logs_exports if attrs.enable_cloudwatch_logs_exports
          deletion_protection attrs.deletion_protection if attrs.deletion_protection
          skip_final_snapshot attrs.skip_final_snapshot if attrs.skip_final_snapshot
          final_snapshot_identifier attrs.final_snapshot_identifier if attrs.final_snapshot_identifier
          apply_immediately attrs.apply_immediately if attrs.apply_immediately
          availability_zones attrs.availability_zones if attrs.availability_zones
          copy_tags_to_snapshot attrs.copy_tags_to_snapshot if attrs.copy_tags_to_snapshot
          enable_global_write_forwarding attrs.enable_global_write_forwarding if attrs.enable_global_write_forwarding
          serverless_v2_scaling_configuration attrs.serverless_v2_scaling_configuration if attrs.serverless_v2_scaling_configuration
          
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
          type: 'aws_neptune_cluster',
          name: name,
          resource_attributes: attrs.to_h,
          outputs: {
            id: "${aws_neptune_cluster.#{name}.id}",
            arn: "${aws_neptune_cluster.#{name}.arn}",
            cluster_resource_id: "${aws_neptune_cluster.#{name}.cluster_resource_id}",
            cluster_members: "${aws_neptune_cluster.#{name}.cluster_members}",
            endpoint: "${aws_neptune_cluster.#{name}.endpoint}",
            reader_endpoint: "${aws_neptune_cluster.#{name}.reader_endpoint}",
            hosted_zone_id: "${aws_neptune_cluster.#{name}.hosted_zone_id}",
            port: "${aws_neptune_cluster.#{name}.port}",
            status: "${aws_neptune_cluster.#{name}.status}",
            storage_encrypted: "${aws_neptune_cluster.#{name}.storage_encrypted}"
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