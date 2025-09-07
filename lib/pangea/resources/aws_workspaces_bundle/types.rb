# frozen_string_literal: true

require 'dry-struct'
require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
        # WorkSpaces Bundle resource attributes with validation
        class WorkspacesBundleAttributes < Dry::Struct
          transform_keys(&:to_sym)
          
          # Required attributes
          attribute :bundle_name, Resources::Types::String.constrained(
            min_size: 1,
            max_size: 63
          )
          
          attribute :bundle_description, Resources::Types::String.constrained(
            min_size: 1,
            max_size: 255
          )
          
          attribute :image_id, Resources::Types::String.constrained(
            format: /\Awsi-[a-z0-9]{9}\z/
          )
          
          attribute :compute_type, ComputeTypeConfigurationType
          attribute :user_storage, UserStorageConfigurationType
          attribute :root_storage, RootStorageConfigurationType.optional
          
          # Optional attributes
          attribute :tags, Resources::Types::AwsTags
          
          # Validation for storage sizes
          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}
            
            # Validate compute type matches storage requirements
            if attrs[:compute_type] && attrs[:user_storage]
              compute_name = attrs[:compute_type][:name] if attrs[:compute_type].is_a?(Hash)
              user_capacity = attrs[:user_storage][:capacity] if attrs[:user_storage].is_a?(Hash)
              
              # Minimum storage requirements by compute type
              min_storage = case compute_name
                           when 'VALUE' then 10
                           when 'STANDARD' then 10
                           when 'PERFORMANCE' then 10
                           when 'POWER' then 100
                           when 'POWERPRO' then 100
                           when 'GRAPHICS' then 100
                           when 'GRAPHICSPRO' then 100
                           else 10
                           end
              
              if user_capacity && user_capacity.to_i < min_storage
                raise Dry::Struct::Error, "User storage capacity #{user_capacity}GB is below minimum #{min_storage}GB for #{compute_name} compute type"
              end
            end
            
            super(attrs)
          end
          
          # Computed properties
          def total_storage_gb
            total = 0
            total += user_storage.capacity.to_i if user_storage
            total += root_storage.capacity.to_i if root_storage
            total
          end
          
          def is_graphics_bundle?
            compute_type.name.include?('GRAPHICS')
          end
          
          def is_high_performance?
            %w[POWER POWERPRO GRAPHICS GRAPHICSPRO].include?(compute_type.name)
          end
          
          def estimated_monthly_cost
            # Base cost estimates by compute type
            base = case compute_type.name
                  when 'VALUE' then 21
                  when 'STANDARD' then 25
                  when 'PERFORMANCE' then 35
                  when 'POWER' then 44
                  when 'POWERPRO' then 88
                  when 'GRAPHICS' then 145
                  when 'GRAPHICSPRO' then 251
                  else 25
                  end
            
            # Add storage costs (rough estimate: $0.10 per GB/month)
            storage_cost = total_storage_gb * 0.10
            
            base + storage_cost
          end
        end
        
        # Compute type configuration
        class ComputeTypeConfigurationType < Dry::Struct
          transform_keys(&:to_sym)
          
          attribute :name, Resources::Types::String.enum(
            'VALUE',
            'STANDARD',
            'PERFORMANCE', 
            'POWER',
            'POWERPRO',
            'GRAPHICS',
            'GRAPHICSPRO'
          )
          
          # Computed specifications based on compute type
          def vcpus
            case name
            when 'VALUE' then 1
            when 'STANDARD' then 2
            when 'PERFORMANCE' then 2
            when 'POWER' then 4
            when 'POWERPRO' then 8
            when 'GRAPHICS' then 8
            when 'GRAPHICSPRO' then 16
            end
          end
          
          def memory_gb
            case name
            when 'VALUE' then 2
            when 'STANDARD' then 4
            when 'PERFORMANCE' then 8
            when 'POWER' then 16
            when 'POWERPRO' then 32
            when 'GRAPHICS' then 15
            when 'GRAPHICSPRO' then 60
            end
          end
          
          def gpu_enabled?
            %w[GRAPHICS GRAPHICSPRO].include?(name)
          end
          
          def gpu_memory_gb
            case name
            when 'GRAPHICS' then 1
            when 'GRAPHICSPRO' then 8
            else 0
            end
          end
        end
        
        # User storage configuration
        class UserStorageConfigurationType < Dry::Struct
          transform_keys(&:to_sym)
          
          attribute :capacity, Resources::Types::Coercible::String.constrained(
            format: /\A\d+\z/
          ).constructor { |value|
            capacity_int = value.to_i
            unless (10..2000).include?(capacity_int)
              raise Dry::Types::ConstraintError, "User storage capacity must be between 10 and 2000 GB"
            end
            value
          }
          
          # Helper methods
          def capacity_gb
            capacity.to_i
          end
          
          def is_ssd?
            true # WorkSpaces storage is SSD-based
          end
        end
        
        # Root storage configuration
        class RootStorageConfigurationType < Dry::Struct
          transform_keys(&:to_sym)
          
          attribute :capacity, Resources::Types::Coercible::String.constrained(
            format: /\A\d+\z/
          ).constructor { |value|
            capacity_int = value.to_i
            unless (80..2000).include?(capacity_int)
              raise Dry::Types::ConstraintError, "Root storage capacity must be between 80 and 2000 GB"
            end
            value
          }
          
          # Helper methods
          def capacity_gb
            capacity.to_i
          end
          
          def is_ssd?
            true # WorkSpaces storage is SSD-based
          end
        end
      end
    end
  end
end