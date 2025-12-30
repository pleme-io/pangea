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
      # Distributed tracing configuration
      class TracingConfig < Dry::Struct
        transform_keys(&:to_sym)

        attribute :enabled, Types::Bool.default(true)
        attribute :sampling_rate, Types::Float.default(0.1)
        attribute :trace_id_header, Types::String.default("X-Trace-Id")
        attribute :span_header, Types::String.default("X-Span-Id")
        attribute :parent_span_header, Types::String.default("X-Parent-Span-Id")
        attribute :baggage_header, Types::String.default("X-Trace-Baggage")
      end

      # Metrics collection configuration
      class MetricsConfig < Dry::Struct
        transform_keys(&:to_sym)

        attribute :enabled, Types::Bool.default(true)
        attribute :collection_interval, Types::Integer.default(60)
        attribute :detailed_metrics, Types::Bool.default(true)
        attribute :custom_metrics, Types::Array.of(Types::Hash).default([].freeze)
        attribute :prometheus_enabled, Types::Bool.default(false)
        attribute :prometheus_port, Types::Integer.default(9090)
      end

      # Service map visualization configuration
      class ServiceMapConfig < Dry::Struct
        transform_keys(&:to_sym)

        attribute :enabled, Types::Bool.default(true)
        attribute :update_interval, Types::Integer.default(300)
        attribute :include_external_services, Types::Bool.default(true)
        attribute :group_by_namespace, Types::Bool.default(true)
      end
    end
  end
end
