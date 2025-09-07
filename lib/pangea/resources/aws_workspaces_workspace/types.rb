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
        # WorkSpaces Workspace resource attributes with validation
        class WorkspacesWorkspaceAttributes < Dry::Struct
          transform_keys(&:to_sym)
          
          # Required attributes
          attribute :directory_id, Resources::Types::String.constrained(
            format: /\Ad-[a-f0-9]{10}\z/
          )
          attribute :bundle_id, Resources::Types::String.constrained(
            format: /\Awsb-[a-z0-9]{9}\z/
          )
          attribute :user_name, Resources::Types::String.constrained(
            min_size: 1,
            max_size: 63,
            format: /\A[a-zA-Z0-9][a-zA-Z0-9._-]*\z/
          )
          
          # Optional attributes
          attribute :root_volume_encryption_enabled, Resources::Types::Bool.default(false)
          attribute :user_volume_encryption_enabled, Resources::Types::Bool.default(false)
          attribute :volume_encryption_key, Resources::Types::String.optional
          attribute :workspace_properties, WorkspacePropertiesType.optional
          attribute :tags, Resources::Types::AwsTags
          
          # Validation for encryption key when encryption is enabled
          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}
            
            # Validate encryption key is provided when encryption is enabled
            if (attrs[:root_volume_encryption_enabled] || attrs[:user_volume_encryption_enabled])
              unless attrs[:volume_encryption_key]
                raise Dry::Struct::Error, "volume_encryption_key is required when encryption is enabled"
              end
            end
            
            super(attrs)
          end
          
          # Computed properties
          def encrypted?
            root_volume_encryption_enabled || user_volume_encryption_enabled
          end
          
          def compute_type_from_bundle
            # Extract compute type from bundle_id pattern
            # Standard bundles: wsb-bh8rsxt14 (Value), wsb-92tn3b7gx (Standard), etc.
            case bundle_id
            when /wsb-bh8rsxt14/, /wsb-gm7rt3w1y/
              'VALUE'
            when /wsb-92tn3b7gx/, /wsb-8vbljg4r6/
              'STANDARD'
            when /wsb-b0s22j3d7/, /wsb-3t36q0xfc/
              'PERFORMANCE'
            when /wsb-1pzkp0bx4/, /wsb-2bs6k5lgn/
              'POWER'
            when /wsb-2bsgq3kc5/, /wsb-cj5xkqz9m/
              'POWERPRO'
            when /wsb-wps19h2gn/, /wsb-g2wnzgdxn/
              'GRAPHICS'
            when /wsb-69x44f3xq/, /wsb-6cxgxvq42/
              'GRAPHICSPRO'
            else
              'CUSTOM'
            end
          end
        end
        
        # WorkSpace properties configuration
        class WorkspacePropertiesType < Dry::Struct
          transform_keys(&:to_sym)
          
          attribute :compute_type_name, Resources::Types::String.enum(
            'VALUE',
            'STANDARD', 
            'PERFORMANCE',
            'POWER',
            'POWERPRO',
            'GRAPHICS',
            'GRAPHICSPRO'
          ).optional
          
          attribute :root_volume_size_gib, Resources::Types::Integer.constrained(
            gteq: 80,
            lteq: 2000
          ).optional
          
          attribute :user_volume_size_gib, Resources::Types::Integer.constrained(
            gteq: 10,
            lteq: 2000
          ).optional
          
          attribute :running_mode, Resources::Types::String.enum(
            'AUTO_STOP',
            'ALWAYS_ON'
          ).default('AUTO_STOP')
          
          attribute :running_mode_auto_stop_timeout_in_minutes, Resources::Types::Integer.constrained(
            included_in: [60, 120, 180, 240, 300, 360, 420, 480, 540, 600, 660, 720]
          ).optional
          
          # Validation for auto stop timeout when running mode is AUTO_STOP
          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}
            
            # If running mode is AUTO_STOP, timeout should be specified
            if attrs[:running_mode] == 'AUTO_STOP' && !attrs[:running_mode_auto_stop_timeout_in_minutes]
              attrs[:running_mode_auto_stop_timeout_in_minutes] = 60 # Default to 60 minutes
            end
            
            # If running mode is ALWAYS_ON, timeout should not be specified
            if attrs[:running_mode] == 'ALWAYS_ON' && attrs[:running_mode_auto_stop_timeout_in_minutes]
              raise Dry::Struct::Error, "running_mode_auto_stop_timeout_in_minutes cannot be set when running_mode is ALWAYS_ON"
            end
            
            super(attrs)
          end
          
          # Helper methods
          def auto_stop_enabled?
            running_mode == 'AUTO_STOP'
          end
          
          def always_on?
            running_mode == 'ALWAYS_ON'
          end
          
          def monthly_cost_estimate
            # Rough estimates based on compute type and running mode
            base_cost = case compute_type_name
                       when 'VALUE' then 21
                       when 'STANDARD' then 25
                       when 'PERFORMANCE' then 35
                       when 'POWER' then 44
                       when 'POWERPRO' then 88
                       when 'GRAPHICS' then 145
                       when 'GRAPHICSPRO' then 251
                       else 25 # Default to standard
                       end
            
            # Add hourly costs for always-on mode (assuming 730 hours/month)
            if always_on?
              hourly_cost = case compute_type_name
                           when 'VALUE' then 0.17
                           when 'STANDARD' then 0.21
                           when 'PERFORMANCE' then 0.29
                           when 'POWER' then 0.52
                           when 'POWERPRO' then 0.74
                           when 'GRAPHICS' then 1.75
                           when 'GRAPHICSPRO' then 2.42
                           else 0.21
                           end
              base_cost + (hourly_cost * 730)
            else
              base_cost
            end
          end
        end
      end
    end
  end
end