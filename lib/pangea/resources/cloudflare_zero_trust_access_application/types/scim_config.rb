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
        # SCIM configuration
        class ZeroTrustAccessScimConfig < Dry::Struct
          transform_keys(&:to_sym)

          attribute :enabled, Dry::Types['strict.bool']
          attribute :remote_uri, Dry::Types['strict.string']
          attribute :idp_uid, Dry::Types['strict.string'].optional.default(nil)
          attribute :deactivate_on_delete, Dry::Types['strict.bool'].optional.default(nil)
          attribute :authentication, Dry::Types['strict.hash'].optional.default(nil)
          attribute :mappings, Dry::Types['strict.array'].of(Dry::Types['strict.hash']).optional.default(nil)
        end
      end
    end
  end
end
