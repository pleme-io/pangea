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
        # AWS Config Configuration Recorder resource attributes with validation
        class ConfigConfigurationRecorderAttributes < Dry::Struct
          transform_keys(&:to_sym)
          
          # Required attributes
          attribute :name, Resources::Types::String
          attribute :role_arn, Resources::Types::String
          
          # Optional attributes
          attribute :recording_group, Resources::Types::Hash.optional.default(nil)
          
          # Tags
          attribute :tags, Resources::Types::AwsTags
          
          # Validate configuration recorder name and role ARN
          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}
            
            if attrs[:name]
              name = attrs[:name]
              
              # Must not be empty
              if name.empty?
                raise Dry::Struct::Error, "Configuration recorder name cannot be empty"
              end
              
              # Length constraints (AWS Config allows 1-256 characters)
              if name.length > 256
                raise Dry::Struct::Error, "Configuration recorder name cannot exceed 256 characters"
              end
              
              # Character validation - alphanumeric, hyphens, underscores
              unless name.match?(/\A[a-zA-Z0-9_-]+\z/)
                raise Dry::Struct::Error, "Configuration recorder name can only contain alphanumeric characters, hyphens, and underscores"
              end
            end
            
            if attrs[:role_arn]
              role_arn = attrs[:role_arn]
              
              # Must not be empty
              if role_arn.empty?
                raise Dry::Struct::Error, "Role ARN cannot be empty"
              end
              
              # Basic ARN format validation
              unless role_arn.match?(/\Aarn:aws:iam::\d{12}:role\//)
                raise Dry::Struct::Error, "Role ARN must be a valid IAM role ARN format: arn:aws:iam::account:role/name"
              end
            end
            
            # Validate recording group if provided
            if attrs[:recording_group].is_a?(Hash)
              recording_group = attrs[:recording_group]
              
              # Validate boolean fields if present
              if recording_group.key?(:all_supported) && ![true, false].include?(recording_group[:all_supported])
                raise Dry::Struct::Error, "recording_group.all_supported must be true or false"
              end
              
              if recording_group.key?(:include_global_resource_types) && ![true, false].include?(recording_group[:include_global_resource_types])
                raise Dry::Struct::Error, "recording_group.include_global_resource_types must be true or false"
              end
              
              # Validate resource types array if present
              if recording_group.key?(:resource_types) && !recording_group[:resource_types].is_a?(Array)
                raise Dry::Struct::Error, "recording_group.resource_types must be an array"
              end
            end
            
            super(attrs)
          end
          
          # Computed properties
          def has_recording_group?
            !recording_group.nil? && !recording_group.empty?
          end
          
          def records_all_resources?
            has_recording_group? && recording_group[:all_supported] == true
          end
          
          def includes_global_resources?
            has_recording_group? && recording_group[:include_global_resource_types] == true
          end
          
          def has_specific_resource_types?
            has_recording_group? && recording_group[:resource_types].is_a?(Array) && !recording_group[:resource_types].empty?
          end
          
          def estimated_monthly_cost_usd
            # AWS Config pricing: $0.003 per configuration item recorded per month
            # Estimate based on resource types being recorded
            
            base_resources = 50 # Conservative estimate of baseline resources
            
            if records_all_resources?
              # Recording all supported resource types - higher cost
              estimated_resources = base_resources * 3 # Assume 3x more resources
            elsif has_specific_resource_types?
              # Recording specific resource types
              resource_count = recording_group[:resource_types].length
              estimated_resources = base_resources * [resource_count / 10.0, 1.0].max
            else
              estimated_resources = base_resources
            end
            
            # Configuration items cost
            config_cost = estimated_resources * 0.003
            
            # Add cost for global resources if included
            global_cost = includes_global_resources? ? 15.0 * 0.003 : 0.0
            
            total_cost = config_cost + global_cost
            total_cost.round(2)
          end
          
          def to_h
            hash = {
              name: name,
              role_arn: role_arn,
              tags: tags
            }
            
            hash[:recording_group] = recording_group if has_recording_group?
            
            hash.compact
          end
        end
      end
    end
  end
end