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
  module Components
    module ApiGatewayMicroservices
      # Rate limiting configuration
      class RateLimitConfig < Dry::Struct
        transform_keys(&:to_sym)

        attribute :enabled, Types::Bool.default(true)
        attribute :burst_limit, Types::Integer.default(5000)
        attribute :rate_limit, Types::Float.default(10_000.0)
        attribute :quota_limit, Types::Integer.optional
        attribute :quota_period, Types::String.enum('DAY', 'WEEK', 'MONTH').optional
      end

      # API versioning configuration
      class VersioningConfig < Dry::Struct
        transform_keys(&:to_sym)

        attribute :strategy, Types::String.enum('PATH', 'HEADER', 'QUERY').default('PATH')
        attribute :default_version, Types::String.default('v1')
        attribute :versions, Types::Array.of(Types::String).default(['v1'].freeze)
        attribute :header_name, Types::String.default('X-API-Version')
        attribute :query_param, Types::String.default('version')
      end

      # CORS configuration
      class CorsConfig < Dry::Struct
        transform_keys(&:to_sym)

        attribute :enabled, Types::Bool.default(true)
        attribute :allow_origins, Types::Array.of(Types::String).default(['*'].freeze)
        attribute :allow_methods, Types::Array.of(Types::String).default(%w[GET POST PUT DELETE OPTIONS].freeze)
        attribute :allow_headers, Types::Array.of(Types::String).default(['Content-Type', 'Authorization', 'X-API-Key'].freeze)
        attribute :expose_headers, Types::Array.of(Types::String).default([].freeze)
        attribute :max_age, Types::Integer.default(86_400)
        attribute :allow_credentials, Types::Bool.default(false)
      end
    end
  end
end
