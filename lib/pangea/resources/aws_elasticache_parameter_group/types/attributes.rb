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

module Pangea
  module Resources
    module AWS
      module Types
        # Type-safe attributes for AWS ElastiCache Parameter Group resources
        class ElastiCacheParameterGroupAttributes < Dry::Struct
          include ElastiCacheParameterHelpers

          # Name of the parameter group
          attribute :name, Resources::Types::String

          # Description of the parameter group
          attribute :description, Resources::Types::String.optional

          # Cache parameter group family (e.g., "redis7.x", "memcached1.6")
          attribute :family, Resources::Types::String.enum(
            # Redis families
            'redis2.6', 'redis2.8', 'redis3.2', 'redis4.0', 'redis5.0', 'redis6.x', 'redis7.x',
            # Memcached families
            'memcached1.4', 'memcached1.5', 'memcached1.6'
          )

          # Parameters to apply to the parameter group
          attribute :parameters, Resources::Types::Array.of(
            Types::Hash.schema(
              name: Types::String,
              value: Types::String
            )
          ).default([].freeze)

          # Tags to apply to the parameter group
          attribute :tags, Resources::Types::AwsTags.default({}.freeze)

          # Custom validation
          def self.new(attributes = {})
            attrs = super(attributes)

            validate_name_format(attrs)
            validate_parameters_for_engine(attrs)
            attrs = set_default_description(attrs)

            attrs
          end

          def self.validate_name_format(attrs)
            unless attrs.name.match?(/\A[a-zA-Z0-9\-]+\z/)
              raise Dry::Struct::Error, 'Parameter group name must contain only letters, numbers, and hyphens'
            end

            if attrs.name.length < 1 || attrs.name.length > 255
              raise Dry::Struct::Error, 'Parameter group name must be between 1 and 255 characters'
            end

            if attrs.name.match?(/\A[\d\-]/)
              raise Dry::Struct::Error, 'Parameter group name cannot start with a number or hyphen'
            end

            return unless attrs.name.end_with?('-')

            raise Dry::Struct::Error, 'Parameter group name cannot end with a hyphen'
          end

          def self.validate_parameters_for_engine(attrs)
            engine_type = attrs.engine_type_from_family
            attrs.parameters.each do |param|
              next if attrs.parameter_valid_for_engine?(param[:name], engine_type)

              raise Dry::Struct::Error, "Parameter '#{param[:name]}' is not valid for #{engine_type} engine"
            end
          end

          def self.set_default_description(attrs)
            return attrs if attrs.description

            attrs.copy_with(description: "Custom parameter group for #{attrs.family}")
          end

          # Helper methods
          def engine_type_from_family
            family.start_with?('redis') ? 'redis' : 'memcached'
          end

          def is_redis_family?
            family.start_with?('redis')
          end

          def is_memcached_family?
            family.start_with?('memcached')
          end

          def family_version
            family.sub(/^(redis|memcached)/, '')
          end

          def parameter_count
            parameters.length
          end

          # Check if this is a default parameter group
          def is_default_group?
            name.start_with?('default.')
          end

          # Cost implications (parameter groups themselves are free)
          def has_cost_implications?
            false
          end

          def estimated_monthly_cost
            '$0.00/month (parameter groups are free)'
          end
        end
      end
    end
  end
end
