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
    module GlobalTrafficManager
      # Monitoring and observability configuration
      class ObservabilityConfig < Dry::Struct
        transform_keys(&:to_sym)

        attribute :cloudwatch_enabled, Types::Bool.default(true)
        attribute :detailed_metrics, Types::Bool.default(true)
        attribute :access_logs_enabled, Types::Bool.default(true)
        attribute :distributed_tracing, Types::Bool.default(true)
        attribute :real_user_monitoring, Types::Bool.default(false)
        attribute :synthetic_checks, Types::Array.of(Types::Hash).default([].freeze)
        attribute :alerting_enabled, Types::Bool.default(true)
        attribute :notification_topic_ref, Types::ResourceReference.optional
      end
    end
  end
end
