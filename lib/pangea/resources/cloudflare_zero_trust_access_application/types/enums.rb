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
        # Application type for Zero Trust Access
        ZeroTrustAccessApplicationType = Dry::Types['strict.string'].enum(
          'self_hosted', 'saas', 'ssh', 'vnc', 'app_launcher', 'warp', 'biso', 'bookmark', 'dash_sso'
        )

        # SameSite cookie attribute
        ZeroTrustSameSiteCookieAttribute = Dry::Types['strict.string'].enum('none', 'lax', 'strict')
      end
    end
  end
end
