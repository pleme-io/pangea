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
        # CloudWatch Log Stream resource attributes with validation
        class CloudWatchLogStreamAttributes < Dry::Struct
          transform_keys(&:to_sym)
          
          # Required attributes
          attribute :name, Resources::Types::String
          attribute :log_group_name, Resources::Types::String
          
          # Validate log stream name pattern
          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}
            
            if attrs[:name]
              # CloudWatch log stream name validation
              name = attrs[:name]
              
              # Must not be empty
              if name.empty?
                raise Dry::Struct::Error, "Log stream name cannot be empty"
              end
              
              # Length constraints
              if name.length > 512
                raise Dry::Struct::Error, "Log stream name cannot exceed 512 characters"
              end
              
              # Character validation - more restrictive than log groups
              # Allows letters, numbers, periods, underscores, hyphens, colons, and forward slashes
              unless name.match?(/\A[a-zA-Z0-9._\-:\/]+\z/)
                raise Dry::Struct::Error, "Log stream name can only contain alphanumeric characters, periods, underscores, hyphens, colons, and forward slashes"
              end
              
              # Cannot start with a colon
              if name.start_with?(':')
                raise Dry::Struct::Error, "Log stream name cannot start with a colon"
              end
              
              # Cannot end with a colon
              if name.end_with?(':')
                raise Dry::Struct::Error, "Log stream name cannot end with a colon"
              end
              
              # Cannot contain consecutive colons
              if name.include?('::')
                raise Dry::Struct::Error, "Log stream name cannot contain consecutive colons"
              end
              
              # Cannot contain consecutive forward slashes
              if name.include?('//')
                raise Dry::Struct::Error, "Log stream name cannot contain consecutive forward slashes"
              end
            end
            
            if attrs[:log_group_name]
              # Log group name validation (same as log group resource)
              log_group_name = attrs[:log_group_name]
              
              if log_group_name.empty?
                raise Dry::Struct::Error, "Log group name cannot be empty"
              end
              
              if log_group_name.length > 512
                raise Dry::Struct::Error, "Log group name cannot exceed 512 characters"
              end
              
              unless log_group_name.match?(/\A[a-zA-Z0-9._\-\/]+\z/)
                raise Dry::Struct::Error, "Log group name can only contain alphanumeric characters, periods, underscores, hyphens, and forward slashes"
              end
            end
            
            super(attrs)
          end
          
          # Computed properties
          def is_lambda_stream?
            name.include?('[') && name.include?(']')
          end
          
          def is_ecs_stream?
            name.start_with?('ecs/')
          end
          
          def is_application_stream?
            !is_lambda_stream? && !is_ecs_stream?
          end
          
          def stream_type
            return 'lambda' if is_lambda_stream?
            return 'ecs' if is_ecs_stream?
            'application'
          end
          
          def log_group_hierarchy
            log_group_name.split('/').reject(&:empty?)
          end
          
          def to_h
            {
              name: name,
              log_group_name: log_group_name
            }
          end
        end
      end
    end
  end
end