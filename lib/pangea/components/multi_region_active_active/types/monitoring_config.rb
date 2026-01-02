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
      # Monitoring configuration
      class MonitoringConfig < Dry::Struct
        transform_keys(&:to_sym)

        attribute :enabled, Types::Bool.default(true)
        attribute :detailed_metrics, Types::Bool.default(true)
        attribute :cross_region_dashboard, Types::Bool.default(true)
        attribute :synthetic_monitoring, Types::Bool.default(true)
        attribute :distributed_tracing, Types::Bool.default(true)
        attribute :log_aggregation, Types::Bool.default(true)
        attribute :anomaly_detection, Types::Bool.default(true)
      end
    end
  end
end
