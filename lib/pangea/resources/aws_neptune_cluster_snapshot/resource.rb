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
require 'pangea/resources/aws_neptune_cluster_snapshot/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Manages a Neptune cluster snapshot.
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Resource attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_neptune_cluster_snapshot(name, attributes = {})
        # Validate attributes using dry-struct
        attrs = Types::NeptuneClusterSnapshotAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_neptune_cluster_snapshot, name) do
          db_cluster_identifier attrs.db_cluster_identifier if attrs.db_cluster_identifier
          db_cluster_snapshot_identifier attrs.db_cluster_snapshot_identifier if attrs.db_cluster_snapshot_identifier
          
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
          type: 'aws_neptune_cluster_snapshot',
          name: name,
          resource_attributes: attrs.to_h,
          outputs: {
            id: "${aws_neptune_cluster_snapshot.#{name}.id}",
            db_cluster_snapshot_arn: "${aws_neptune_cluster_snapshot.#{name}.db_cluster_snapshot_arn}",
            engine: "${aws_neptune_cluster_snapshot.#{name}.engine}",
            engine_version: "${aws_neptune_cluster_snapshot.#{name}.engine_version}",
            port: "${aws_neptune_cluster_snapshot.#{name}.port}",
            status: "${aws_neptune_cluster_snapshot.#{name}.status}",
            storage_encrypted: "${aws_neptune_cluster_snapshot.#{name}.storage_encrypted}",
            kms_key_id: "${aws_neptune_cluster_snapshot.#{name}.kms_key_id}",
            vpc_id: "${aws_neptune_cluster_snapshot.#{name}.vpc_id}",
            snapshot_create_time: "${aws_neptune_cluster_snapshot.#{name}.snapshot_create_time}",
            availability_zones: "${aws_neptune_cluster_snapshot.#{name}.availability_zones}"
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