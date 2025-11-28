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
  module Resources
    module Cloudflare
      module Types
        include Dry.Types()

        # Zone settings configuration
        ZoneSettings = ::Pangea::Resources::Types::Hash

        # Cloudflare Zone Settings Override resource attributes with validation
        class ZoneSettingsOverrideAttributes < Dry::Struct
          transform_keys(&:to_sym)

          attribute :zone_id, ::Pangea::Resources::Types::CloudflareZoneId
          attribute :settings, ZoneSettings.optional.default(nil)

          # Computed properties
          def has_settings?
            settings && settings.any?
          end

          def setting_count
            settings ? settings.keys.length : 0
          end

          def ssl_mode
            settings&.dig(:ssl)
          end

          def security_level
            settings&.dig(:security_level)
          end

          def cache_level
            settings&.dig(:cache_level)
          end

          def always_use_https?
            settings&.dig(:always_use_https) == 'on'
          end
        end
      end
    end
  end
end
