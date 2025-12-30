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
    module AWS
      module Types
        # Throttle settings type for API Gateway usage plans
        ThrottleSettingsType = Resources::Types::Hash.schema(
          burst_limit?: Types::Integer.optional,
          rate_limit?: Types::Coercible::Float.optional
        ).optional

        # Quota settings type for API Gateway usage plans
        QuotaSettingsType = Resources::Types::Hash.schema(
          limit: Types::Integer,
          offset?: Types::Integer.optional,
          period: Types::String.enum('DAY', 'WEEK', 'MONTH')
        ).optional

        # Per-path throttle settings for API stages
        PathThrottleType = Types::Hash.schema(
          path?: Types::String.optional,
          burst_limit?: Types::Integer.optional,
          rate_limit?: Types::Coercible::Float.optional
        ).optional

        # API stage configuration type
        ApiStageType = Types::Hash.schema(
          api_id: Types::String,
          stage: Types::String,
          throttle?: PathThrottleType
        )

        # Array of API stages type
        ApiStagesType = Resources::Types::Array.of(ApiStageType).default([].freeze)
      end
    end
  end
end
