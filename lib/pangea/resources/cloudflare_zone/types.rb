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
        # Cloudflare Zone resource attributes with validation
        class ZoneAttributes < Dry::Struct
          transform_keys(&:to_sym)

          attribute :zone, ::Pangea::Resources::Types::DomainName
          attribute :account_id, ::Pangea::Resources::Types::CloudflareAccountId.optional.default(nil)
          attribute :jump_start, ::Pangea::Resources::Types::Bool.default(false)
          attribute :paused, ::Pangea::Resources::Types::Bool.default(false)
          attribute :plan, ::Pangea::Resources::Types::CloudflareZonePlan
          attribute :type, ::Pangea::Resources::Types::CloudflareZoneType

          # Computed properties
          def is_active?
            !paused
          end

          def is_enterprise?
            plan == 'enterprise'
          end

          def is_free?
            plan == 'free'
          end

          def zone_root_domain
            # Extract root domain from zone
            parts = zone.split('.')
            return zone if parts.length <= 2
            parts[-2..-1].join('.')
          end

          def is_subdomain?
            zone.split('.').length > 2
          end
        end
      end
    end
  end
end
