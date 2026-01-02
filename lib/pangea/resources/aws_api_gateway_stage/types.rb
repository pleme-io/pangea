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
require_relative 'types/validators'
require_relative 'types/helpers'

module Pangea
  module Resources
    module AWS
      module Types
        # API Gateway Stage attributes with validation
        class ApiGatewayStageAttributes < Dry::Struct
          transform_keys(&:to_sym)

          VALID_CACHE_SIZES = %w[0.5 1.6 6.1 13.5 28.4 58.2 118 237].freeze

          # Core attributes
          attribute :rest_api_id, Pangea::Resources::Types::String
          attribute :deployment_id, Pangea::Resources::Types::String
          attribute :stage_name, Pangea::Resources::Types::String

          # Stage configuration
          attribute :description, Pangea::Resources::Types::String.optional.default(nil)
          attribute :documentation_version, Pangea::Resources::Types::String.optional.default(nil)

          # Caching
          attribute :cache_cluster_enabled, Pangea::Resources::Types::Bool.default(false)
          attribute :cache_cluster_size, Pangea::Resources::Types::String
            .constrained(included_in: VALID_CACHE_SIZES).optional.default(nil)

          # Stage variables
          attribute :variables, Pangea::Resources::Types::Hash.map(
            Pangea::Resources::Types::String, Pangea::Resources::Types::String
          ).default({}.freeze)

          # Logging and monitoring
          attribute :xray_tracing_enabled, Pangea::Resources::Types::Bool.default(false)

          # Access logging
          attribute :access_log_settings, Pangea::Resources::Types::Hash.optional.default(nil)

          # Throttling
          attribute :throttle_burst_limit, Pangea::Resources::Types::Coercible::Integer.optional.default(nil)
          attribute :throttle_rate_limit, Pangea::Resources::Types::Coercible::Float.optional.default(nil)

          # Method settings (per-method configuration)
          attribute :method_settings, Pangea::Resources::Types::Array.of(Pangea::Resources::Types::Hash).default([].freeze)

          # Canary settings
          attribute :canary_settings, Pangea::Resources::Types::Hash.optional.default(nil)

          # Client certificate
          attribute :client_certificate_id, Pangea::Resources::Types::String.optional.default(nil)

          # Tags
          attribute :tags, Pangea::Resources::Types::AwsTags

          # Custom validation
          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}
            ApiGatewayStageValidators.validate!(attrs)
            super(attrs)
          end

          # Computed properties
          def has_caching?
            cache_cluster_enabled
          end

          def has_access_logging?
            !access_log_settings.nil?
          end

          def has_canary?
            !canary_settings.nil? && canary_settings[:percent_traffic].to_f.positive?
          end

          def has_throttling?
            !throttle_rate_limit.nil? || !throttle_burst_limit.nil?
          end

          def has_method_settings?
            !method_settings.empty?
          end

          def estimated_monthly_cost
            return 0.0 unless cache_cluster_enabled && cache_cluster_size

            ApiGatewayStageHelpers.cache_monthly_cost(cache_cluster_size)
          end

          # Delegate class methods to helpers
          def self.common_log_formats
            ApiGatewayStageHelpers.common_log_formats
          end

          def self.common_method_paths
            ApiGatewayStageHelpers.common_method_paths
          end
        end
      end
    end
  end
end
