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
require 'pangea/resources/aws_docdb_cluster_instance/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Provides a DocumentDB Cluster Instance resource. A Cluster Instance is an isolated database instance within a DocumentDB Cluster.
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Resource attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_docdb_cluster_instance(name, attributes = {})
        # Validate attributes using dry-struct
        attrs = Types::DocdbClusterInstanceAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_docdb_cluster_instance, name) do
          identifier attrs.identifier if attrs.identifier
          cluster_identifier attrs.cluster_identifier if attrs.cluster_identifier
          instance_class attrs.instance_class if attrs.instance_class
          engine attrs.engine if attrs.engine
          availability_zone attrs.availability_zone if attrs.availability_zone
          preferred_maintenance_window attrs.preferred_maintenance_window if attrs.preferred_maintenance_window
          apply_immediately attrs.apply_immediately if attrs.apply_immediately
          auto_minor_version_upgrade attrs.auto_minor_version_upgrade if attrs.auto_minor_version_upgrade
          promotion_tier attrs.promotion_tier if attrs.promotion_tier
          enable_performance_insights attrs.enable_performance_insights if attrs.enable_performance_insights
          performance_insights_kms_key_id attrs.performance_insights_kms_key_id if attrs.performance_insights_kms_key_id
          performance_insights_retention_period attrs.performance_insights_retention_period if attrs.performance_insights_retention_period
          copy_tags_to_snapshot attrs.copy_tags_to_snapshot if attrs.copy_tags_to_snapshot
          ca_cert_identifier attrs.ca_cert_identifier if attrs.ca_cert_identifier
          
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
          type: 'aws_docdb_cluster_instance',
          name: name,
          resource_attributes: attrs.to_h,
          outputs: {
            id: "${aws_docdb_cluster_instance.#{name}.id}",
            arn: "${aws_docdb_cluster_instance.#{name}.arn}",
            dbi_resource_id: "${aws_docdb_cluster_instance.#{name}.dbi_resource_id}",
            endpoint: "${aws_docdb_cluster_instance.#{name}.endpoint}",
            port: "${aws_docdb_cluster_instance.#{name}.port}",
            status: "${aws_docdb_cluster_instance.#{name}.status}",
            storage_encrypted: "${aws_docdb_cluster_instance.#{name}.storage_encrypted}",
            kms_key_id: "${aws_docdb_cluster_instance.#{name}.kms_key_id}",
            publicly_accessible: "${aws_docdb_cluster_instance.#{name}.publicly_accessible}",
            writer: "${aws_docdb_cluster_instance.#{name}.writer}"
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