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
        # Caching configuration for SQL responses
        class HyperdriveCaching < Dry::Struct
          transform_keys(&:to_sym)

          # @!attribute disabled
          #   @return [Boolean, nil] Disable caching (default: false)
          attribute :disabled, Dry::Types['strict.bool'].optional.default(nil)

          # @!attribute max_age
          #   @return [Integer, nil] Cache duration in seconds (default: 60)
          attribute :max_age, Dry::Types['coercible.integer']
            .constrained(gteq: 0)
            .optional
            .default(nil)

          # @!attribute stale_while_revalidate
          #   @return [Integer, nil] Stale response serving window in seconds (default: 15)
          attribute :stale_while_revalidate, Dry::Types['coercible.integer']
            .constrained(gteq: 0)
            .optional
            .default(nil)

          # Check if caching is enabled
          # @return [Boolean] true if not disabled
          def enabled?
            disabled != true
          end
        end
      end
    end
  end
end
