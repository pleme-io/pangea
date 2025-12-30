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
      # Performance optimization configuration
      class PerformanceConfig < Dry::Struct
        transform_keys(&:to_sym)

        attribute :tcp_optimization, Types::Bool.default(true)
        attribute :flow_logs_enabled, Types::Bool.default(true)
        attribute :flow_logs_s3_bucket, Types::String.optional
        attribute :flow_logs_s3_prefix, Types::String.default('global-traffic-flow-logs/')
        attribute :connection_draining_timeout, Types::Integer.default(30)
        attribute :idle_timeout, Types::Integer.default(60)
      end
    end
  end
end
