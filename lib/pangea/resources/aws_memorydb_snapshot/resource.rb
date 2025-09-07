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
require 'pangea/resources/aws_memorydb_snapshot/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Provides a MemoryDB Snapshot resource.
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Resource attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_memorydb_snapshot(name, attributes = {})
        # Validate attributes using dry-struct
        attrs = Types::MemorydbSnapshotAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_memorydb_snapshot, name) do
          cluster_name attrs.cluster_name if attrs.cluster_name
          name attrs.name if attrs.name
          name_prefix attrs.name_prefix if attrs.name_prefix
          kms_key_id attrs.kms_key_id if attrs.kms_key_id
          
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
          type: 'aws_memorydb_snapshot',
          name: name,
          resource_attributes: attrs.to_h,
          outputs: {
            id: "${aws_memorydb_snapshot.#{name}.id}",
            arn: "${aws_memorydb_snapshot.#{name}.arn}",
            cluster_configuration: "${aws_memorydb_snapshot.#{name}.cluster_configuration}",
            source: "${aws_memorydb_snapshot.#{name}.source}"
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