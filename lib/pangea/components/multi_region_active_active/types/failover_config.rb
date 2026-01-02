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
      # Failover configuration
      class FailoverConfig < Dry::Struct
        transform_keys(&:to_sym)

        attribute :enabled, Types::Bool.default(true)
        attribute :health_check_interval, Types::Integer.default(30)
        attribute :unhealthy_threshold, Types::Integer.default(3)
        attribute :healthy_threshold, Types::Integer.default(2)
        attribute :failover_timeout, Types::Integer.default(300)
        attribute :auto_failback, Types::Bool.default(true)
        attribute :notification_topic_ref, Types::ResourceReference.optional
      end
    end
  end
end
