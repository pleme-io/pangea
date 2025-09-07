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
require 'pangea/resources/aws_elasticache_cluster/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS ElastiCache Cluster with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] ElastiCache cluster attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_elasticache_cluster(name, attributes = {})
        # Validate attributes using dry-struct
        cluster_attrs = AWS::Types::Types::ElastiCacheClusterAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_elasticache_cluster, name) do
          cluster_id cluster_attrs.cluster_id
          engine cluster_attrs.engine
          node_type cluster_attrs.node_type
          num_cache_nodes cluster_attrs.num_cache_nodes
          
          # Engine configuration
          engine_version cluster_attrs.engine_version if cluster_attrs.engine_version
          parameter_group_name cluster_attrs.parameter_group_name if cluster_attrs.parameter_group_name
          port cluster_attrs.port if cluster_attrs.port
          
          # Network configuration
          subnet_group_name cluster_attrs.subnet_group_name if cluster_attrs.subnet_group_name
          security_group_ids cluster_attrs.security_group_ids if cluster_attrs.security_group_ids.any?
          
          # Availability zone configuration
          availability_zone cluster_attrs.availability_zone if cluster_attrs.availability_zone
          if cluster_attrs.preferred_availability_zones.any?
            preferred_availability_zones cluster_attrs.preferred_availability_zones
          end
          
          # Maintenance configuration
          maintenance_window cluster_attrs.maintenance_window if cluster_attrs.maintenance_window
          notification_topic_arn cluster_attrs.notification_topic_arn if cluster_attrs.notification_topic_arn
          auto_minor_version_upgrade cluster_attrs.auto_minor_version_upgrade
          apply_immediately cluster_attrs.apply_immediately
          
          # Redis-specific configuration
          if cluster_attrs.is_redis?
            # Snapshot configuration
            snapshot_arns cluster_attrs.snapshot_arns if cluster_attrs.snapshot_arns
            snapshot_name cluster_attrs.snapshot_name if cluster_attrs.snapshot_name
            snapshot_window cluster_attrs.snapshot_window if cluster_attrs.snapshot_window
            snapshot_retention_limit cluster_attrs.snapshot_retention_limit if cluster_attrs.snapshot_retention_limit > 0
            final_snapshot_identifier cluster_attrs.final_snapshot_identifier if cluster_attrs.final_snapshot_identifier
            
            # Encryption configuration
            at_rest_encryption_enabled cluster_attrs.at_rest_encryption_enabled if cluster_attrs.at_rest_encryption_enabled
            transit_encryption_enabled cluster_attrs.transit_encryption_enabled if cluster_attrs.transit_encryption_enabled
            auth_token cluster_attrs.auth_token if cluster_attrs.auth_token
          end
          
          # Log delivery configuration
          if cluster_attrs.log_delivery_configuration.any?
            cluster_attrs.log_delivery_configuration.each_with_index do |log_config, index|
              log_delivery_configuration do
                destination log_config[:destination]
                destination_type log_config[:destination_type]
                log_format log_config[:log_format]
                log_type log_config[:log_type]
              end
            end
          end
          
          # Apply tags if present
          if cluster_attrs.tags.any?
            tags do
              cluster_attrs.tags.each do |key, value|
                public_send(key, value)
              end
            end
          end
        end
        
        # Create resource reference
        ref = ResourceReference.new(
          type: 'aws_elasticache_cluster',
          name: name,
          resource_attributes: cluster_attrs.to_h,
          outputs: {
            id: "${aws_elasticache_cluster.#{name}.id}",
            arn: "${aws_elasticache_cluster.#{name}.arn}",
            cluster_address: "${aws_elasticache_cluster.#{name}.cluster_address}",
            configuration_endpoint: "${aws_elasticache_cluster.#{name}.configuration_endpoint}",
            port: "${aws_elasticache_cluster.#{name}.port}",
            cache_nodes: "${aws_elasticache_cluster.#{name}.cache_nodes}",
            engine_version_actual: "${aws_elasticache_cluster.#{name}.engine_version_actual}",
            tags_all: "${aws_elasticache_cluster.#{name}.tags_all}"
          }
        )
        
        # Add computed properties via method delegation
        ref.define_singleton_method(:is_redis?) { cluster_attrs.is_redis? }
        ref.define_singleton_method(:is_memcached?) { cluster_attrs.is_memcached? }
        ref.define_singleton_method(:default_port) { cluster_attrs.default_port }
        ref.define_singleton_method(:supports_encryption?) { cluster_attrs.supports_encryption? }
        ref.define_singleton_method(:supports_backup?) { cluster_attrs.supports_backup? }
        ref.define_singleton_method(:supports_auth?) { cluster_attrs.supports_auth? }
        ref.define_singleton_method(:engine_supports_encryption?) { cluster_attrs.engine_supports_encryption? }
        ref.define_singleton_method(:is_cluster_mode?) { cluster_attrs.is_cluster_mode? }
        ref.define_singleton_method(:estimated_monthly_cost) { cluster_attrs.estimated_monthly_cost }
        
        ref
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)