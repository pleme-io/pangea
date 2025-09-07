# frozen_string_literal: true

require 'dry-struct'
require 'pangea/resources/types'

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
        
        # Self-service permissions configuration
        class SelfServicePermissionsType < Dry::Struct
          transform_keys(&:to_sym)
          
          attribute :restart_workspace, Resources::Types::String.enum(
            'ENABLED',
            'DISABLED'
          ).default('ENABLED')
          
          attribute :increase_volume_size, Resources::Types::String.enum(
            'ENABLED',
            'DISABLED'
          ).default('DISABLED')
          
          attribute :change_compute_type, Resources::Types::String.enum(
            'ENABLED',
            'DISABLED'
          ).default('DISABLED')
          
          attribute :switch_running_mode, Resources::Types::String.enum(
            'ENABLED',
            'DISABLED'
          ).default('DISABLED')
          
          attribute :rebuild_workspace, Resources::Types::String.enum(
            'ENABLED',
            'DISABLED'
          ).default('DISABLED')
          
          # Helper methods
          def all_enabled?
            restart_workspace == 'ENABLED' &&
              increase_volume_size == 'ENABLED' &&
              change_compute_type == 'ENABLED' &&
              switch_running_mode == 'ENABLED' &&
              rebuild_workspace == 'ENABLED'
          end
          
          def all_disabled?
            restart_workspace == 'DISABLED' &&
              increase_volume_size == 'DISABLED' &&
              change_compute_type == 'DISABLED' &&
              switch_running_mode == 'DISABLED' &&
              rebuild_workspace == 'DISABLED'
          end
        end
        
        # Workspace creation properties
        class WorkspaceCreationPropertiesType < Dry::Struct
          transform_keys(&:to_sym)
          
          attribute :custom_security_group_id, Resources::Types::String.optional
          attribute :default_ou, Resources::Types::String.optional
          attribute :enable_internet_access, Resources::Types::Bool.default(true)
          attribute :enable_maintenance_mode, Resources::Types::Bool.default(false)
          attribute :user_enabled_as_local_administrator, Resources::Types::Bool.default(false)
          
          # Validation for OU format
          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}
            
            # Validate OU format if provided
            if attrs[:default_ou] && !attrs[:default_ou].match?(/\AOU=[^,]+/)
              raise Dry::Struct::Error, "default_ou must be in format 'OU=WorkSpaces,DC=example,DC=com'"
            end
            
            super(attrs)
          end
          
          # Security assessment
          def security_level
            score = 0
            score += 2 if custom_security_group_id  # Using custom security group
            score += 1 unless enable_internet_access  # Internet access disabled
            score += 2 unless user_enabled_as_local_administrator  # No local admin
            
            case score
            when 4..5 then :high
            when 2..3 then :medium
            else :low
            end
          end
        end
        
        # Workspace access properties
        class WorkspaceAccessPropertiesType < Dry::Struct
          transform_keys(&:to_sym)
          
          attribute :device_type_windows, Resources::Types::String.enum(
            'ALLOW',
            'DENY'
          ).default('ALLOW')
          
          attribute :device_type_osx, Resources::Types::String.enum(
            'ALLOW',
            'DENY'
          ).default('ALLOW')
          
          attribute :device_type_web, Resources::Types::String.enum(
            'ALLOW',
            'DENY'
          ).default('DENY')
          
          attribute :device_type_ios, Resources::Types::String.enum(
            'ALLOW',
            'DENY'
          ).default('ALLOW')
          
          attribute :device_type_android, Resources::Types::String.enum(
            'ALLOW',
            'DENY'
          ).default('ALLOW')
          
          attribute :device_type_chrome_os, Resources::Types::String.enum(
            'ALLOW',
            'DENY'
          ).default('DENY')
          
          attribute :device_type_zero_client, Resources::Types::String.enum(
            'ALLOW',
            'DENY'
          ).default('ALLOW')
          
          attribute :device_type_linux, Resources::Types::String.enum(
            'ALLOW',
            'DENY'
          ).default('DENY')
          
          # Helper methods
          def allowed_device_types
            types = []
            types << 'Windows' if device_type_windows == 'ALLOW'
            types << 'macOS' if device_type_osx == 'ALLOW'
            types << 'Web' if device_type_web == 'ALLOW'
            types << 'iOS' if device_type_ios == 'ALLOW'
            types << 'Android' if device_type_android == 'ALLOW'
            types << 'ChromeOS' if device_type_chrome_os == 'ALLOW'
            types << 'ZeroClient' if device_type_zero_client == 'ALLOW'
            types << 'Linux' if device_type_linux == 'ALLOW'
            types
          end
          
          def mobile_access_allowed?
            device_type_ios == 'ALLOW' || device_type_android == 'ALLOW'
          end
          
          def web_access_allowed?
            device_type_web == 'ALLOW'
          end
          
          def desktop_access_allowed?
            device_type_windows == 'ALLOW' || 
              device_type_osx == 'ALLOW' || 
              device_type_linux == 'ALLOW'
          end
        end
      end
    end
  end
end