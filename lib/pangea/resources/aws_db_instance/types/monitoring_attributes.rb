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

require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
        # Performance and monitoring attributes for AWS RDS Database Instance
        class MonitoringAttributes < Dry::Struct
          transform_keys(&:to_sym)

          # CloudWatch log exports
          attribute :enabled_cloudwatch_logs_exports, Resources::Types::Array.of(Resources::Types::String).default([].freeze)

          # Performance Insights enabled
          attribute :performance_insights_enabled, Resources::Types::Bool.default(false)

          # Performance Insights retention period
          attribute :performance_insights_retention_period, Resources::Types::Integer.default(7)
        end
      end
    end
  end
end
