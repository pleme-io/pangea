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
    module GlobalServiceMesh
      # Traffic management configuration
      class TrafficManagementConfig < Dry::Struct
        transform_keys(&:to_sym)

        attribute :load_balancing_algorithm, Types::String.enum('ROUND_ROBIN', 'RANDOM', 'LEAST_REQUEST').default('ROUND_ROBIN')
        attribute :circuit_breaker_enabled, Types::Bool.default(true)
        attribute :circuit_breaker_threshold, Types::Integer.default(5)
        attribute :outlier_detection_enabled, Types::Bool.default(true)
        attribute :outlier_ejection_duration_seconds, Types::Integer.default(30)
        attribute :max_ejection_percent, Types::Integer.default(50)
        attribute :canary_deployments_enabled, Types::Bool.default(true)
      end

      # Cross-region connectivity configuration
      class CrossRegionConfig < Dry::Struct
        transform_keys(&:to_sym)

        attribute :peering_enabled, Types::Bool.default(true)
        attribute :transit_gateway_enabled, Types::Bool.default(true)
        attribute :private_link_enabled, Types::Bool.default(false)
        attribute :inter_region_tls_enabled, Types::Bool.default(true)
        attribute :latency_routing_enabled, Types::Bool.default(true)
        attribute :health_based_routing, Types::Bool.default(true)
      end

      # Resilience patterns configuration
      class ResilienceConfig < Dry::Struct
        transform_keys(&:to_sym)

        attribute :retry_policy_enabled, Types::Bool.default(true)
        attribute :max_retries, Types::Integer.default(3)
        attribute :retry_timeout_seconds, Types::Integer.default(5)
        attribute :bulkhead_enabled, Types::Bool.default(true)
        attribute :max_connections, Types::Integer.default(100)
        attribute :max_pending_requests, Types::Integer.default(100)
        attribute :timeout_enabled, Types::Bool.default(true)
        attribute :request_timeout_seconds, Types::Integer.default(15)
        attribute :chaos_testing_enabled, Types::Bool.default(false)
      end
    end
  end
end
