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
require 'pangea/resources/aws_redshift_cluster/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS Redshift Cluster with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Redshift Cluster attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_redshift_cluster(name, attributes = {})
        # Validate attributes using dry-struct
        cluster_attrs = Types::RedshiftClusterAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_redshift_cluster, name) do
          # Required attributes
          cluster_identifier cluster_attrs.cluster_identifier
          database_name cluster_attrs.database_name
          master_username cluster_attrs.master_username
          master_password cluster_attrs.master_password if cluster_attrs.master_password
          node_type cluster_attrs.node_type
          
          # Cluster configuration
          cluster_type cluster_attrs.cluster_type
          number_of_nodes cluster_attrs.number_of_nodes if cluster_attrs.multi_node?
          
          # Network configuration
          port cluster_attrs.port
          cluster_subnet_group_name cluster_attrs.cluster_subnet_group_name if cluster_attrs.cluster_subnet_group_name
          vpc_security_group_ids cluster_attrs.vpc_security_group_ids if cluster_attrs.vpc_security_group_ids.any?
          availability_zone cluster_attrs.availability_zone if cluster_attrs.availability_zone
          enhanced_vpc_routing cluster_attrs.enhanced_vpc_routing
          publicly_accessible cluster_attrs.publicly_accessible
          elastic_ip cluster_attrs.elastic_ip if cluster_attrs.elastic_ip
          
          # Parameter group
          cluster_parameter_group_name cluster_attrs.cluster_parameter_group_name if cluster_attrs.cluster_parameter_group_name
          
          # Maintenance and backups
          preferred_maintenance_window cluster_attrs.preferred_maintenance_window
          automated_snapshot_retention_period cluster_attrs.automated_snapshot_retention_period
          manual_snapshot_retention_period cluster_attrs.manual_snapshot_retention_period
          
          # Encryption
          encrypted cluster_attrs.encrypted
          kms_key_id cluster_attrs.kms_key_id if cluster_attrs.kms_key_id
          
          # Snapshot configuration
          skip_final_snapshot cluster_attrs.skip_final_snapshot
          final_snapshot_identifier cluster_attrs.final_snapshot_identifier if cluster_attrs.final_snapshot_identifier
          snapshot_identifier cluster_attrs.snapshot_identifier if cluster_attrs.snapshot_identifier
          snapshot_cluster_identifier cluster_attrs.snapshot_cluster_identifier if cluster_attrs.snapshot_cluster_identifier
          owner_account cluster_attrs.owner_account if cluster_attrs.owner_account
          
          # Version configuration
          allow_version_upgrade cluster_attrs.allow_version_upgrade
          cluster_version cluster_attrs.cluster_version
          
          # Logging configuration
          if cluster_attrs.logging
            logging do
              enable cluster_attrs.logging[:enable]
              bucket_name cluster_attrs.logging[:bucket_name] if cluster_attrs.logging[:bucket_name]
              s3_key_prefix cluster_attrs.logging[:s3_key_prefix] if cluster_attrs.logging[:s3_key_prefix]
            end
          end
          
          # Snapshot copy configuration
          if cluster_attrs.snapshot_copy
            snapshot_copy do
              destination_region cluster_attrs.snapshot_copy[:destination_region]
              retention_period cluster_attrs.snapshot_copy[:retention_period] if cluster_attrs.snapshot_copy[:retention_period]
              grant_name cluster_attrs.snapshot_copy[:grant_name] if cluster_attrs.snapshot_copy[:grant_name]
            end
          end
          
          # IAM roles
          iam_roles cluster_attrs.iam_roles if cluster_attrs.iam_roles.any?
          
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
          type: 'aws_redshift_cluster',
          name: name,
          resource_attributes: cluster_attrs.to_h,
          outputs: {
            id: "${aws_redshift_cluster.#{name}.id}",
            arn: "${aws_redshift_cluster.#{name}.arn}",
            endpoint: "${aws_redshift_cluster.#{name}.endpoint}",
            address: "${aws_redshift_cluster.#{name}.address}",
            port: "${aws_redshift_cluster.#{name}.port}",
            database_name: "${aws_redshift_cluster.#{name}.database_name}",
            cluster_identifier: "${aws_redshift_cluster.#{name}.cluster_identifier}",
            cluster_nodes: "${aws_redshift_cluster.#{name}.cluster_nodes}",
            cluster_parameter_group_name: "${aws_redshift_cluster.#{name}.cluster_parameter_group_name}",
            cluster_subnet_group_name: "${aws_redshift_cluster.#{name}.cluster_subnet_group_name}",
            vpc_security_group_ids: "${aws_redshift_cluster.#{name}.vpc_security_group_ids}",
            preferred_maintenance_window: "${aws_redshift_cluster.#{name}.preferred_maintenance_window}",
            node_type: "${aws_redshift_cluster.#{name}.node_type}",
            number_of_nodes: "${aws_redshift_cluster.#{name}.number_of_nodes}"
          },
          computed_properties: {
            multi_node: cluster_attrs.multi_node?,
            uses_ra3_nodes: cluster_attrs.uses_ra3_nodes?,
            uses_dc2_nodes: cluster_attrs.uses_dc2_nodes?,
            total_storage_capacity_gb: cluster_attrs.total_storage_capacity_gb,
            total_vcpus: cluster_attrs.total_vcpus,
            total_memory_gb: cluster_attrs.total_memory_gb,
            estimated_monthly_cost_usd: cluster_attrs.estimated_monthly_cost_usd,
            high_availability: cluster_attrs.high_availability?,
            audit_logging_enabled: cluster_attrs.audit_logging_enabled?,
            cross_region_backup: cluster_attrs.cross_region_backup?,
            jdbc_connection_string: cluster_attrs.jdbc_connection_string
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)