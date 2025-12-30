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
    module Cloudflare
      module Types
        # CORS rule for R2 bucket
        class R2CorsRule < Dry::Struct
          transform_keys(&:to_sym)

          # @!attribute allowed
          #   @return [R2CorsAllowed] Allowed origins, methods, headers
          attribute :allowed, R2CorsAllowed

          # @!attribute id
          #   @return [String, nil] Rule identifier
          attribute :id, Dry::Types['strict.string'].optional.default(nil)

          # @!attribute max_age_seconds
          #   @return [Integer, nil] Preflight cache duration (max 86400)
          attribute :max_age_seconds, Dry::Types['coercible.integer']
            .constrained(gteq: 0, lteq: 86400)
            .optional
            .default(nil)

          # @!attribute expose_headers
          #   @return [Array<String>, nil] Headers exposed to JavaScript
          attribute :expose_headers, Dry::Types['strict.array']
            .of(Dry::Types['strict.string'])
            .optional
            .default(nil)

          # Check if GET requests allowed
          # @return [Boolean] true if GET in methods
          def allows_get?
            allowed[:methods].include?('GET')
          end

          # Check if POST requests allowed
          # @return [Boolean] true if POST in methods
          def allows_post?
            allowed[:methods].include?('POST')
          end

          # Check if has preflight caching
          # @return [Boolean] true if max_age_seconds configured
          def has_preflight_caching?
            !max_age_seconds.nil? && max_age_seconds > 0
          end

          # Check if exposes headers
          # @return [Boolean] true if expose_headers configured
          def exposes_headers?
            !expose_headers.nil? && !expose_headers.empty?
          end
        end
      end
    end
  end
end
