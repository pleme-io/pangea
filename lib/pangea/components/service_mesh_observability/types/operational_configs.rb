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
    module ServiceMeshObservability
      # Alerting configuration
      class AlertingConfig < Dry::Struct
        transform_keys(&:to_sym)

        attribute :enabled, Types::Bool.default(true)
        attribute :notification_channel_ref, Types::ResourceReference.optional
        attribute :latency_threshold_ms, Types::Integer.default(1000)
        attribute :error_rate_threshold, Types::Float.default(0.05)
        attribute :availability_threshold, Types::Float.default(0.99)
        attribute :circuit_breaker_threshold, Types::Integer.default(5)
      end

      # Log aggregation configuration
      class LogAggregationConfig < Dry::Struct
        transform_keys(&:to_sym)

        attribute :enabled, Types::Bool.default(true)
        attribute :retention_days, Types::Integer.default(30)
        attribute :log_groups, Types::Array.of(Types::String).default([].freeze)
        attribute :filter_patterns, Types::Array.of(Types::Hash).default([].freeze)
        attribute :insights_queries, Types::Array.of(Types::Hash).default([].freeze)
      end
    end
  end
end
