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
require 'pangea/resources/aws_docdb_global_cluster/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Provides a DocumentDB Global Cluster resource.
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Resource attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_docdb_global_cluster(name, attributes = {})
        # Validate attributes using dry-struct
        attrs = Types::DocdbGlobalClusterAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_docdb_global_cluster, name) do
          global_cluster_identifier attrs.global_cluster_identifier if attrs.global_cluster_identifier
          source_db_cluster_identifier attrs.source_db_cluster_identifier if attrs.source_db_cluster_identifier
          engine attrs.engine if attrs.engine
          engine_version attrs.engine_version if attrs.engine_version
          database_name attrs.database_name if attrs.database_name
          deletion_protection attrs.deletion_protection if attrs.deletion_protection
          storage_encrypted attrs.storage_encrypted if attrs.storage_encrypted
          
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
          type: 'aws_docdb_global_cluster',
          name: name,
          resource_attributes: attrs.to_h,
          outputs: {
            id: "${aws_docdb_global_cluster.#{name}.id}",
            arn: "${aws_docdb_global_cluster.#{name}.arn}",
            global_cluster_resource_id: "${aws_docdb_global_cluster.#{name}.global_cluster_resource_id}",
            global_cluster_members: "${aws_docdb_global_cluster.#{name}.global_cluster_members}"
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