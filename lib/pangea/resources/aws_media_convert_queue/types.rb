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
    module AWS
      module Types
      # Type-safe attributes for AWS MediaConvert Queue resources
      class MediaConvertQueueAttributes < Dry::Struct
        transform_keys(&:to_sym)

        # Queue name (required)
        attribute :name, Resources::Types::String

        # Queue description
        attribute :description, Resources::Types::String.default("")

        # Pricing plan
        attribute :pricing_plan, Resources::Types::String.enum('ON_DEMAND', 'RESERVED').default('ON_DEMAND')

        # Reservation plan settings (for RESERVED pricing)
        attribute :reservation_plan_settings, Resources::Types::Hash.schema(
          commitment: Resources::Types::String.enum('ONE_YEAR'),
          renewal_type: Resources::Types::String.enum('AUTO_RENEW', 'EXPIRE'),
          reserved_slots: Resources::Types::Integer
        ).default({}.freeze)

        # Status
        attribute :status, Resources::Types::String.enum('ACTIVE', 'PAUSED').default('ACTIVE')

        # Tags
        attribute :tags, Resources::Types::AwsTags.default({}.freeze)

        # Helper methods
        def reserved_pricing?
          pricing_plan == 'RESERVED'
        end

        def on_demand_pricing?
          pricing_plan == 'ON_DEMAND'
        end

        def active?
          status == 'ACTIVE'
        end

        def paused?
          status == 'PAUSED'
        end
      end
    end
      end
    end
  end
end