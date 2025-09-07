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
require 'pangea/resources/aws_workspaces_workspace/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS WorkSpaces Workspace with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] WorkSpaces Workspace attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_workspaces_workspace(name, attributes = {})
        # Validate attributes using dry-struct
        workspace_attrs = Types::Types::WorkspacesWorkspaceAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_workspaces_workspace, name) do
          directory_id workspace_attrs.directory_id
          bundle_id workspace_attrs.bundle_id
          user_name workspace_attrs.user_name
          
          # Encryption settings
          root_volume_encryption_enabled workspace_attrs.root_volume_encryption_enabled
          user_volume_encryption_enabled workspace_attrs.user_volume_encryption_enabled
          
          if workspace_attrs.volume_encryption_key
            volume_encryption_key workspace_attrs.volume_encryption_key
          end
          
          # Workspace properties
          if workspace_attrs.workspace_properties
            workspace_properties do
              props = workspace_attrs.workspace_properties
              
              compute_type_name props.compute_type_name if props.compute_type_name
              root_volume_size_gib props.root_volume_size_gib if props.root_volume_size_gib
              user_volume_size_gib props.user_volume_size_gib if props.user_volume_size_gib
              running_mode props.running_mode
              
              if props.running_mode_auto_stop_timeout_in_minutes
                running_mode_auto_stop_timeout_in_minutes props.running_mode_auto_stop_timeout_in_minutes
              end
            end
          end
          
          # Apply tags if present
          if workspace_attrs.tags.any?
            tags do
              workspace_attrs.tags.each do |key, value|
                public_send(key, value)
              end
            end
          end
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_workspaces_workspace',
          name: name,
          resource_attributes: workspace_attrs.to_h,
          outputs: {
            id: "${aws_workspaces_workspace.#{name}.id}",
            computer_name: "${aws_workspaces_workspace.#{name}.computer_name}",
            ip_address: "${aws_workspaces_workspace.#{name}.ip_address}",
            state: "${aws_workspaces_workspace.#{name}.state}",
            workspace_properties: {
              compute_type_name: "${aws_workspaces_workspace.#{name}.workspace_properties[0].compute_type_name}",
              root_volume_size_gib: "${aws_workspaces_workspace.#{name}.workspace_properties[0].root_volume_size_gib}",
              user_volume_size_gib: "${aws_workspaces_workspace.#{name}.workspace_properties[0].user_volume_size_gib}",
              running_mode: "${aws_workspaces_workspace.#{name}.workspace_properties[0].running_mode}"
            },
            directory_id: workspace_attrs.directory_id,
            bundle_id: workspace_attrs.bundle_id,
            user_name: workspace_attrs.user_name
          },
          computed_properties: {
            encrypted: workspace_attrs.encrypted?,
            compute_type: workspace_attrs.compute_type_from_bundle,
            estimated_monthly_cost: workspace_attrs.workspace_properties&.monthly_cost_estimate,
            auto_stop_enabled: workspace_attrs.workspace_properties&.auto_stop_enabled?,
            always_on: workspace_attrs.workspace_properties&.always_on?
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)