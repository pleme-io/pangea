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
      # Traffic policy configuration
      class TrafficPolicyConfig < Dry::Struct
        transform_keys(&:to_sym)

        attribute :policy_name, Types::String
        attribute :policy_type, Types::String.enum(
          'latency', 'weighted', 'geoproximity', 'geolocation', 'failover', 'multivalue'
        ).default('latency')
        attribute :health_check_interval, Types::Integer.default(30)
        attribute :health_check_path, Types::String.default('/health')
        attribute :health_check_protocol, Types::String.enum('HTTP', 'HTTPS', 'TCP').default('HTTP')
        attribute :unhealthy_threshold, Types::Integer.default(3)
        attribute :healthy_threshold, Types::Integer.default(2)
        attribute :health_check_timeout, Types::Integer.default(5)
      end
    end
  end
end
