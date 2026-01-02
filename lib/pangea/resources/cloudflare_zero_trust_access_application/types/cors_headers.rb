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
        # CORS headers configuration
        class ZeroTrustAccessCorsHeaders < Dry::Struct
          transform_keys(&:to_sym)

          attribute :allow_all_headers, Dry::Types['strict.bool'].optional.default(nil)
          attribute :allow_all_methods, Dry::Types['strict.bool'].optional.default(nil)
          attribute :allow_all_origins, Dry::Types['strict.bool'].optional.default(nil)
          attribute :allow_credentials, Dry::Types['strict.bool'].optional.default(nil)
          attribute :allowed_headers, Dry::Types['strict.array'].of(Dry::Types['strict.string']).optional.default(nil)
          attribute :allowed_methods, Dry::Types['strict.array'].of(Dry::Types['strict.string']).optional.default(nil)
          attribute :allowed_origins, Dry::Types['strict.array'].of(Dry::Types['strict.string']).optional.default(nil)
          attribute :max_age, Dry::Types['coercible.integer'].constrained(gteq: -1).optional.default(nil)
        end
      end
    end
  end
end
