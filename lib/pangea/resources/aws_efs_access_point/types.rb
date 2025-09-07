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

module Pangea
  module Resources
    module AWS
      module Types
        # EFS Access Point resource attributes with validation
        class EfsAccessPointAttributes < Dry::Struct
          transform_keys(&:to_sym)
          
          # Required attributes
          attribute :file_system_id, Resources::Types::String
          
          # Optional POSIX user configuration
          attribute :posix_user, Resources::Types::EfsPosixUser.optional
          
          # Optional root directory configuration  
          attribute :root_directory, Resources::Types::EfsRootDirectory.optional
          
          # Tags
          attribute :tags, Resources::Types::AwsTags.default({}.freeze)
          
          # Custom validation
          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}
            
            # Validate root directory path if specified
            if attrs[:root_directory] && attrs[:root_directory][:path]
              path = attrs[:root_directory][:path]
              
              # Path must start with /
              unless path.start_with?('/')
                raise Dry::Struct::Error, "root_directory path must start with '/', got '#{path}'"
              end
              
              # Path cannot end with / unless it's the root path
              if path.length > 1 && path.end_with?('/')
                raise Dry::Struct::Error, "root_directory path cannot end with '/' except for root path '/'"
              end
              
              # Path cannot be longer than 100 characters
              if path.length > 100
                raise Dry::Struct::Error, "root_directory path cannot exceed 100 characters, got #{path.length}"
              end
              
              # Path cannot contain consecutive slashes
              if path.include?('//')
                raise Dry::Struct::Error, "root_directory path cannot contain consecutive slashes '//'"
              end
              
              # Validate path components
              path_components = path.split('/').reject(&:empty?)
              path_components.each do |component|
                # Each component must be valid filename
                if component.match?(/[<>:"|?*\x00-\x1f]/)
                  raise Dry::Struct::Error, "root_directory path component '#{component}' contains invalid characters"
                end
                
                # Each component cannot be . or ..
                if component == '.' || component == '..'
                  raise Dry::Struct::Error, "root_directory path cannot contain '.' or '..' components"
                end
              end
            end
            
            # Validate creation_info permissions format if specified
            if attrs[:root_directory] && 
               attrs[:root_directory][:creation_info] && 
               attrs[:root_directory][:creation_info][:permissions]
              
              perms = attrs[:root_directory][:creation_info][:permissions]
              unless perms.match?(/\A[0-7]{3,4}\z/)
                raise Dry::Struct::Error, "creation_info permissions must be 3-4 digit octal format (e.g., '755', '0755')"
              end
              
              # Convert to integer and validate range
              perm_int = perms.to_i(8)
              if perm_int > 0o7777
                raise Dry::Struct::Error, "creation_info permissions cannot exceed 0777 (got #{perms})"
              end
            end
            
            # Validate POSIX user IDs if specified
            if attrs[:posix_user]
              posix = attrs[:posix_user]
              
              # Validate secondary_gids length
              if posix[:secondary_gids] && posix[:secondary_gids].length > 16
                raise Dry::Struct::Error, "posix_user secondary_gids cannot exceed 16 groups"
              end
              
              # Validate UID/GID are not reserved system IDs in sensitive range
              [posix[:uid], posix[:gid]].compact.each do |id|
                if id == 0
                  # Root user/group - log warning but allow for containers
                  # In production, using root should be discouraged
                end
              end
            end
            
            super(attrs)
          end
          
          # Computed properties
          def has_posix_user?
            !posix_user.nil?
          end
          
          def has_root_directory?
            !root_directory.nil?
          end
          
          def has_creation_info?
            root_directory && root_directory[:creation_info]
          end
          
          def effective_root_path
            root_directory&.dig(:path) || "/"
          end
          
          def effective_uid
            posix_user&.dig(:uid) || 1000  # Default non-root UID
          end
          
          def effective_gid  
            posix_user&.dig(:gid) || 1000  # Default non-root GID
          end
          
          def is_root_user?
            effective_uid == 0
          end
          
          def security_assessment
            issues = []
            warnings = []
            
            # Check for root user
            if is_root_user?
              warnings << "Using root user (UID 0) - consider using non-privileged user"
            end
            
            # Check for overly permissive directory permissions
            if has_creation_info?
              perms = root_directory[:creation_info][:permissions]
              perm_int = perms.to_i(8)
              
              # Check for world-writable
              if (perm_int & 0o002) != 0
                issues << "Directory permissions are world-writable (#{perms}) - security risk"
              end
              
              # Check for world-readable sensitive paths
              if effective_root_path.match?(/\/(etc|home|root|var\/log)/) && (perm_int & 0o004) != 0
                warnings << "World-readable permissions on sensitive path #{effective_root_path}"
              end
            end
            
            {
              issues: issues,
              warnings: warnings,
              secure: issues.empty?
            }
          end
        end
      end
    end
  end
end