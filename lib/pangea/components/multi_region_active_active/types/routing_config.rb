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
  module Components
    module MultiRegionActiveActive
      # Traffic routing configuration
      class TrafficRoutingConfig < Dry::Struct
        transform_keys(&:to_sym)

        attribute :routing_policy, Types::String.enum('latency', 'weighted', 'geolocation', 'failover').default('latency')
        attribute :health_check_enabled, Types::Bool.default(true)
        attribute :cross_region_latency_threshold_ms, Types::Integer.default(100)
        attribute :sticky_sessions, Types::Bool.default(false)
        attribute :session_affinity_ttl, Types::Integer.default(3600)
      end
    end
  end
end
