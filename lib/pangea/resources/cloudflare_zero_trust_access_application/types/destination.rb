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
        # Application destination
        class ZeroTrustAccessDestination < Dry::Struct
          transform_keys(&:to_sym)

          attribute :type, Dry::Types['strict.string'].optional.default(nil)
          attribute :uri, Dry::Types['strict.string'].optional.default(nil)
          attribute :hostname, Dry::Types['strict.string'].optional.default(nil)
          attribute :cidr, Dry::Types['strict.string'].optional.default(nil)
          attribute :port_range, Dry::Types['strict.string'].optional.default(nil)
          attribute :l4_protocol, Dry::Types['strict.string'].optional.default(nil)
          attribute :vnet_id, Dry::Types['strict.string'].optional.default(nil)
          attribute :mcp_server_id, Dry::Types['strict.string'].optional.default(nil)
        end
      end
    end
  end
end
