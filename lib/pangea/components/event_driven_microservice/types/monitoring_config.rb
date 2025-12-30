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
    module EventDrivenMicroservice
      # Monitoring and alerting configuration
      class MonitoringConfig < Dry::Struct
        transform_keys(&:to_sym)

        attribute :dashboard_enabled, Types::Bool.default(true)
        attribute :alarm_email, Types::String.optional
        attribute :event_processing_threshold, Types::Integer.default(1000) # ms
        attribute :error_rate_threshold, Types::Float.default(0.01) # 1%
        attribute :dead_letter_threshold, Types::Integer.default(10)
      end
    end
  end
end
