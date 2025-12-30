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

require 'dry-struct'
require 'pangea/resources/types'
require_relative 'types/self_service_permissions_type'
require_relative 'types/workspace_creation_properties_type'
require_relative 'types/workspace_access_properties_type'

module Pangea
  module Resources
    module AWS
      module Types
        # WorkSpaces Directory resource attributes with validation
        class WorkspacesDirectoryAttributes < Dry::Struct
          transform_keys(&:to_sym)

          # Required attributes
          attribute :directory_id, Resources::Types::String.constrained(
            format: /\Ad-[a-f0-9]{10}\z/
          )

          # Optional attributes
          attribute :subnet_ids, Resources::Types::Array.of(
            Resources::Types::String
          ).optional

          attribute :self_service_permissions, SelfServicePermissionsType.optional
          attribute :workspace_creation_properties, WorkspaceCreationPropertiesType.optional
          attribute :workspace_access_properties, WorkspaceAccessPropertiesType.optional
          attribute :ip_group_ids, Resources::Types::Array.of(
            Resources::Types::String.constrained(
              format: /\Awsipg-[a-z0-9]{9}\z/
            )
          ).optional

          attribute :tags, Resources::Types::AwsTags

          # Computed properties
          def multi_az?
            subnet_ids && subnet_ids.length > 1
          end

          def self_service_enabled?
            return false unless self_service_permissions

            self_service_permissions.restart_workspace == 'ENABLED' ||
              self_service_permissions.increase_volume_size == 'ENABLED' ||
              self_service_permissions.change_compute_type == 'ENABLED' ||
              self_service_permissions.switch_running_mode == 'ENABLED' ||
              self_service_permissions.rebuild_workspace == 'ENABLED'
          end

          def device_access_enabled?
            return false unless workspace_access_properties

            workspace_access_properties.device_type_windows == 'ALLOW' ||
              workspace_access_properties.device_type_osx == 'ALLOW' ||
              workspace_access_properties.device_type_web == 'ALLOW' ||
              workspace_access_properties.device_type_ios == 'ALLOW' ||
              workspace_access_properties.device_type_android == 'ALLOW' ||
              workspace_access_properties.device_type_chrome_os == 'ALLOW' ||
              workspace_access_properties.device_type_zero_client == 'ALLOW' ||
              workspace_access_properties.device_type_linux == 'ALLOW'
          end
        end
      end
    end
  end
end
