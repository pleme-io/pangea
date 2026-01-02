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

require_relative 'types/schemas'
require_relative 'types/validation'
require_relative 'types/instance_methods'

module Pangea
  module Resources
    module AWS
      module Types
        # Type-safe attributes for AWS CodeBuild Project resources
        class CodeBuildProjectAttributes < Dry::Struct
          include InstanceMethods

          transform_keys(&:to_sym)

          # Project name (required)
          attribute :name, Resources::Types::String.constrained(
            format: /\A[A-Za-z0-9][A-Za-z0-9\-_]*\z/,
            min_size: 2,
            max_size: 255
          )

          # Project description
          attribute? :description, Resources::Types::String.constrained(max_size: 255).optional

          # Service role ARN (required)
          attribute :service_role, Resources::Types::String

          # Build timeout in minutes (5-480)
          attribute :build_timeout, Resources::Types::Integer.constrained(gteq: 5, lteq: 480).default(60)

          # Queued timeout in minutes (5-480)
          attribute :queued_timeout, Resources::Types::Integer.constrained(gteq: 5, lteq: 480).default(480)

          # Concurrent build limit
          attribute? :concurrent_build_limit, Resources::Types::Integer.constrained(gteq: 1, lteq: 100).optional

          # Source configuration
          attribute :source, Schemas::SOURCE

          # Artifacts configuration
          attribute :artifacts, Schemas::ARTIFACTS

          # Secondary sources
          attribute :secondary_sources, Resources::Types::Array.of(Schemas::SECONDARY_SOURCE).default([].freeze)

          # Secondary artifacts
          attribute :secondary_artifacts, Resources::Types::Array.of(Schemas::SECONDARY_ARTIFACT).default([].freeze)

          # Environment configuration
          attribute :environment, Schemas::ENVIRONMENT

          # Cache configuration
          attribute :cache, Schemas::CACHE.default({ type: 'NO_CACHE' })

          # VPC configuration
          attribute? :vpc_config, Schemas::VPC_CONFIG.optional

          # Logs configuration
          attribute :logs_config, Schemas::LOGS_CONFIG.default({}.freeze)

          # Build batch configuration
          attribute? :build_batch_config, Schemas::BUILD_BATCH_CONFIG.optional

          # File system locations
          attribute :file_system_locations, Resources::Types::Array.of(Schemas::FILE_SYSTEM_LOCATION).default([].freeze)

          # Badge enabled
          attribute :badge_enabled, Resources::Types::Bool.default(false)

          # Encryption key
          attribute? :encryption_key, Resources::Types::String.optional

          # Resource access role
          attribute? :resource_access_role, Resources::Types::String.optional

          # Tags
          attribute :tags, Resources::Types::AwsTags.default({}.freeze)

          # Custom validation
          def self.new(attributes = {})
            attrs = super(attributes)
            Validation.validate(attrs)
            attrs
          end
        end
      end
    end
  end
end
