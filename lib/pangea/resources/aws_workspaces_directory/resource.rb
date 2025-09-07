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
require 'pangea/resources/aws_workspaces_directory/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS WorkSpaces Directory configuration with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] WorkSpaces Directory attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_workspaces_directory(name, attributes = {})
        # Validate attributes using dry-struct
        directory_attrs = Types::Types::WorkspacesDirectoryAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_workspaces_directory, name) do
          directory_id directory_attrs.directory_id
          
          # Subnet configuration for multi-AZ
          if directory_attrs.subnet_ids
            subnet_ids directory_attrs.subnet_ids
          end
          
          # Self-service permissions
          if directory_attrs.self_service_permissions
            self_service_permissions do
              perms = directory_attrs.self_service_permissions
              restart_workspace perms.restart_workspace
              increase_volume_size perms.increase_volume_size
              change_compute_type perms.change_compute_type
              switch_running_mode perms.switch_running_mode
              rebuild_workspace perms.rebuild_workspace
            end
          end
          
          # Workspace creation properties
          if directory_attrs.workspace_creation_properties
            workspace_creation_properties do
              props = directory_attrs.workspace_creation_properties
              
              custom_security_group_id props.custom_security_group_id if props.custom_security_group_id
              default_ou props.default_ou if props.default_ou
              enable_internet_access props.enable_internet_access
              enable_maintenance_mode props.enable_maintenance_mode
              user_enabled_as_local_administrator props.user_enabled_as_local_administrator
            end
          end
          
          # Workspace access properties
          if directory_attrs.workspace_access_properties
            workspace_access_properties do
              access = directory_attrs.workspace_access_properties
              
              device_type_windows access.device_type_windows
              device_type_osx access.device_type_osx
              device_type_web access.device_type_web
              device_type_ios access.device_type_ios
              device_type_android access.device_type_android
              device_type_chrome_os access.device_type_chrome_os
              device_type_zero_client access.device_type_zero_client
              device_type_linux access.device_type_linux
            end
          end
          
          # IP group associations
          if directory_attrs.ip_group_ids
            ip_group_ids directory_attrs.ip_group_ids
          end
          
          # Apply tags if present
          if directory_attrs.tags.any?
            tags do
              directory_attrs.tags.each do |key, value|
                public_send(key, value)
              end
            end
          end
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_workspaces_directory',
          name: name,
          resource_attributes: directory_attrs.to_h,
          outputs: {
            id: "${aws_workspaces_directory.#{name}.id}",
            directory_id: directory_attrs.directory_id,
            workspace_security_group_id: "${aws_workspaces_directory.#{name}.workspace_security_group_id}",
            iam_role_id: "${aws_workspaces_directory.#{name}.iam_role_id}",
            registration_code: "${aws_workspaces_directory.#{name}.registration_code}",
            directory_name: "${aws_workspaces_directory.#{name}.directory_name}",
            directory_type: "${aws_workspaces_directory.#{name}.directory_type}",
            alias: "${aws_workspaces_directory.#{name}.alias}",
            customer_user_name: "${aws_workspaces_directory.#{name}.customer_user_name}",
            dns_ip_addresses: "${aws_workspaces_directory.#{name}.dns_ip_addresses}"
          },
          computed_properties: {
            multi_az: directory_attrs.multi_az?,
            self_service_enabled: directory_attrs.self_service_enabled?,
            device_access_enabled: directory_attrs.device_access_enabled?,
            allowed_device_types: directory_attrs.workspace_access_properties&.allowed_device_types,
            mobile_access_allowed: directory_attrs.workspace_access_properties&.mobile_access_allowed?,
            web_access_allowed: directory_attrs.workspace_access_properties&.web_access_allowed?,
            desktop_access_allowed: directory_attrs.workspace_access_properties&.desktop_access_allowed?,
            security_level: directory_attrs.workspace_creation_properties&.security_level
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)