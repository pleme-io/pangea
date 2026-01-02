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
        # Landing page design
        class ZeroTrustAccessLandingPageDesign < Dry::Struct
          transform_keys(&:to_sym)

          attribute :title, Dry::Types['strict.string'].optional.default(nil)
          attribute :message, Dry::Types['strict.string'].optional.default(nil)
          attribute :button_color, Dry::Types['strict.string'].optional.default(nil)
          attribute :button_text_color, Dry::Types['strict.string'].optional.default(nil)
          attribute :image_url, Dry::Types['strict.string'].optional.default(nil)
        end
      end
    end
  end
end
