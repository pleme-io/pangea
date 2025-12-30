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
        # Allowed configuration for CORS rule
        class R2CorsAllowed < Dry::Struct
          transform_keys(&:to_sym)

          # @!attribute origins
          #   @return [Array<String>] Allowed origins (scheme://host[:port])
          attribute :origins, Dry::Types['strict.array']
            .of(Dry::Types['strict.string'])
            .constrained(min_size: 1)

          # @!attribute methods
          #   @return [Array<String>] Allowed HTTP methods
          attribute :methods, Dry::Types['strict.array']
            .of(CloudflareR2CorsMethod)
            .constrained(min_size: 1)

          # @!attribute headers
          #   @return [Array<String>, nil] Allowed request headers
          attribute :headers, Dry::Types['strict.array']
            .of(Dry::Types['strict.string'])
            .optional
            .default(nil)

          # Check if wildcard origin
          # @return [Boolean] true if allows all origins
          def wildcard_origin?
            origins.include?('*')
          end

          # Check if wildcard headers
          # @return [Boolean] true if allows all headers
          def wildcard_headers?
            headers&.include?('*') || false
          end
        end
      end
    end
  end
end
