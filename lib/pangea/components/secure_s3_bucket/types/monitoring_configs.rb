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
    module SecureS3Bucket
      # Transfer acceleration configuration
      class AccelerationConfig < Dry::Struct
        transform_keys(&:to_sym)

        attribute :enabled, Types::Bool.default(false)
        attribute :status, Types::String.optional.enum('Enabled', 'Suspended')
      end

      # Analytics configuration
      class AnalyticsConfig < Dry::Struct
        transform_keys(&:to_sym)

        attribute :enabled, Types::Bool.default(false)
        attribute :configurations, Types::Array.default([].freeze)
      end

      # Inventory configuration
      class InventoryConfig < Dry::Struct
        transform_keys(&:to_sym)

        attribute :enabled, Types::Bool.default(false)
        attribute :configurations, Types::Array.default([].freeze)
      end

      # Metrics configuration for CloudWatch
      class MetricsConfig < Dry::Struct
        transform_keys(&:to_sym)

        attribute :enabled, Types::Bool.default(true)
        attribute :request_metrics, Types::Array.default([].freeze)
        attribute :enable_request_metrics, Types::Bool.default(true)
        attribute :enable_data_events_logging, Types::Bool.default(false)
      end
    end
  end
end
