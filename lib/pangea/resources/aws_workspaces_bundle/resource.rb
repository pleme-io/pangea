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
require 'pangea/resources/aws_workspaces_bundle/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create a custom AWS WorkSpaces Bundle with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] WorkSpaces Bundle attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_workspaces_bundle(name, attributes = {})
        # Validate attributes using dry-struct
        bundle_attrs = Types::Types::WorkspacesBundleAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_workspaces_bundle, name) do
          bundle_name bundle_attrs.bundle_name
          bundle_description bundle_attrs.bundle_description
          image_id bundle_attrs.image_id
          
          # Compute type configuration
          compute_type do
            name bundle_attrs.compute_type.name
          end
          
          # User storage configuration
          user_storage do
            capacity bundle_attrs.user_storage.capacity
          end
          
          # Root storage configuration (optional)
          if bundle_attrs.root_storage
            root_storage do
              capacity bundle_attrs.root_storage.capacity
            end
          end
          
          # Apply tags if present
          if bundle_attrs.tags.any?
            tags do
              bundle_attrs.tags.each do |key, value|
                public_send(key, value)
              end
            end
          end
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_workspaces_bundle',
          name: name,
          resource_attributes: bundle_attrs.to_h,
          outputs: {
            id: "${aws_workspaces_bundle.#{name}.id}",
            bundle_id: "${aws_workspaces_bundle.#{name}.bundle_id}",
            owner: "${aws_workspaces_bundle.#{name}.owner}",
            state: "${aws_workspaces_bundle.#{name}.state}",
            bundle_name: bundle_attrs.bundle_name,
            image_id: bundle_attrs.image_id,
            compute_type_name: bundle_attrs.compute_type.name
          },
          computed_properties: {
            total_storage_gb: bundle_attrs.total_storage_gb,
            is_graphics_bundle: bundle_attrs.is_graphics_bundle?,
            is_high_performance: bundle_attrs.is_high_performance?,
            estimated_monthly_cost: bundle_attrs.estimated_monthly_cost,
            vcpus: bundle_attrs.compute_type.vcpus,
            memory_gb: bundle_attrs.compute_type.memory_gb,
            gpu_enabled: bundle_attrs.compute_type.gpu_enabled?,
            gpu_memory_gb: bundle_attrs.compute_type.gpu_memory_gb,
            user_storage_gb: bundle_attrs.user_storage.capacity_gb,
            root_storage_gb: bundle_attrs.root_storage&.capacity_gb
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)