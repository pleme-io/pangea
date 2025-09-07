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
        # Auto Scaling Group tag attributes with validation
        class AutoScalingTagAttributes < Dry::Struct
          transform_keys(&:to_sym)
          
          # Required attributes
          attribute :autoscaling_group_name, Resources::Types::String
          attribute :tags, Resources::Types::Array.of(TagSpecification).constrained(min_size: 1)
          
          # Tag specification for Auto Scaling Groups
          class TagSpecification < Dry::Struct
            transform_keys(&:to_sym)
            
            attribute :key, Resources::Types::String
            attribute :value, Resources::Types::String
            attribute :propagate_at_launch, Resources::Types::Bool
            
            def to_h
              {
                key: key,
                value: value,
                propagate_at_launch: propagate_at_launch
              }
            end
          end
          
          # Validate configuration
          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}
            
            # Validate Auto Scaling Group name
            if attrs[:autoscaling_group_name]
              group_name = attrs[:autoscaling_group_name]
              
              if group_name.nil? || group_name.strip.empty?
                raise Dry::Struct::Error, "Auto Scaling Group name cannot be empty"
              end
              
              if group_name.length > 255
                raise Dry::Struct::Error, "Auto Scaling Group name cannot exceed 255 characters: #{group_name}"
              end
            end
            
            # Validate tags
            if attrs[:tags]
              validate_tags(attrs[:tags])
            end
            
            super(attrs)
          end
          
          # Validate tag specifications
          def self.validate_tags(tags)
            return unless tags.is_a?(Array)
            
            tag_keys = []
            
            tags.each do |tag|
              tag_hash = tag.is_a?(Hash) ? tag : {}
              
              # Validate tag key
              key = tag_hash[:key] || tag_hash['key']
              if key.nil? || key.strip.empty?
                raise Dry::Struct::Error, "Tag key cannot be empty"
              end
              
              if key.length > 128
                raise Dry::Struct::Error, "Tag key cannot exceed 128 characters: #{key}"
              end
              
              if key.start_with?('aws:')
                raise Dry::Struct::Error, "Tag key cannot start with 'aws:' prefix: #{key}"
              end
              
              # Validate tag value
              value = tag_hash[:value] || tag_hash['value']
              if value.nil?
                raise Dry::Struct::Error, "Tag value cannot be nil for key: #{key}"
              end
              
              if value.length > 256
                raise Dry::Struct::Error, "Tag value cannot exceed 256 characters for key '#{key}': #{value}"
              end
              
              # Check for duplicate keys
              if tag_keys.include?(key)
                raise Dry::Struct::Error, "Duplicate tag key not allowed: #{key}"
              end
              
              tag_keys << key
              
              # Validate propagate_at_launch
              propagate = tag_hash[:propagate_at_launch] || tag_hash['propagate_at_launch']
              unless [true, false].include?(propagate)
                raise Dry::Struct::Error, "propagate_at_launch must be true or false for tag key: #{key}"
              end
            end
            
            # AWS has a limit on number of tags per resource
            if tags.length > 50
              raise Dry::Struct::Error, "Cannot exceed 50 tags per Auto Scaling Group (provided: #{tags.length})"
            end
          end
          
          # Computed properties
          def tag_count
            tags.length
          end
          
          def has_propagated_tags?
            tags.any?(&:propagate_at_launch)
          end
          
          def has_non_propagated_tags?
            tags.any? { |tag| !tag.propagate_at_launch }
          end
          
          def all_tags_propagated?
            tags.all?(&:propagate_at_launch)
          end
          
          def no_tags_propagated?
            tags.none?(&:propagate_at_launch)
          end
          
          def propagated_tag_count
            tags.count(&:propagate_at_launch)
          end
          
          def non_propagated_tag_count
            tags.count { |tag| !tag.propagate_at_launch }
          end
          
          def tag_keys
            tags.map(&:key)
          end
          
          def propagated_tag_keys
            tags.select(&:propagate_at_launch).map(&:key)
          end
          
          def non_propagated_tag_keys
            tags.reject(&:propagate_at_launch).map(&:key)
          end
          
          def has_tag?(key)
            tag_keys.include?(key)
          end
          
          def tag_value(key)
            tag = tags.find { |t| t.key == key }
            tag&.value
          end
          
          def tag_propagated?(key)
            tag = tags.find { |t| t.key == key }
            tag&.propagate_at_launch || false
          end
          
          # Standard tag queries
          def has_environment_tag?
            has_tag?('Environment') || has_tag?('environment')
          end
          
          def has_name_tag?
            has_tag?('Name') || has_tag?('name')
          end
          
          def has_cost_center_tag?
            has_tag?('CostCenter') || has_tag?('Cost-Center') || has_tag?('cost-center')
          end
          
          def has_owner_tag?
            has_tag?('Owner') || has_tag?('owner')
          end
          
          def has_project_tag?
            has_tag?('Project') || has_tag?('project')
          end
          
          def environment
            tag_value('Environment') || tag_value('environment')
          end
          
          def name
            tag_value('Name') || tag_value('name')
          end
          
          def cost_center
            tag_value('CostCenter') || tag_value('Cost-Center') || tag_value('cost-center')
          end
          
          def owner
            tag_value('Owner') || tag_value('owner')
          end
          
          def project
            tag_value('Project') || tag_value('project')
          end
          
          def to_h
            {
              autoscaling_group_name: autoscaling_group_name,
              tags: tags.map(&:to_h)
            }
          end
        end
      end
    end
  end
end