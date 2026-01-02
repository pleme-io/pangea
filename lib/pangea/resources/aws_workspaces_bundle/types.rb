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
require_relative 'types/compute'
require_relative 'types/storage'

module Pangea
  module Resources
    module AWS
      module Types
        # WorkSpaces Bundle resource attributes with validation
        class WorkspacesBundleAttributes < Dry::Struct
          transform_keys(&:to_sym)

          attribute :bundle_name, Resources::Types::String.constrained(min_size: 1, max_size: 63)
          attribute :bundle_description, Resources::Types::String.constrained(min_size: 1, max_size: 255)
          attribute :image_id, Resources::Types::String.constrained(format: /\Awsi-[a-z0-9]{9}\z/)
          attribute :compute_type, ComputeTypeConfigurationType
          attribute :user_storage, UserStorageConfigurationType
          attribute :root_storage, RootStorageConfigurationType.optional
          attribute :tags, Resources::Types::AwsTags

          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}
            validate_storage_requirements(attrs)
            super(attrs)
          end

          def self.validate_storage_requirements(attrs)
            return unless attrs[:compute_type] && attrs[:user_storage]

            compute_name = attrs[:compute_type][:name] if attrs[:compute_type].is_a?(Hash)
            user_capacity = attrs[:user_storage][:capacity] if attrs[:user_storage].is_a?(Hash)

            min_storage = case compute_name
                          when 'VALUE', 'STANDARD', 'PERFORMANCE' then 10
                          when 'POWER', 'POWERPRO', 'GRAPHICS', 'GRAPHICSPRO' then 100
                          else 10
                          end

            if user_capacity && user_capacity.to_i < min_storage
              raise Dry::Struct::Error, "User storage capacity #{user_capacity}GB is below minimum #{min_storage}GB for #{compute_name} compute type"
            end
          end

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
            base + (total_storage_gb * 0.10)
          end
        end
      end
    end
  end
end
