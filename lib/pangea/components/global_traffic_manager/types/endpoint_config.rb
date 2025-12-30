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
      # Endpoint configuration for traffic management
      class EndpointConfig < Dry::Struct
        transform_keys(&:to_sym)

        attribute :region, Types::String
        attribute :endpoint_id, Types::String
        attribute :endpoint_type, Types::String.enum('ALB', 'NLB', 'INSTANCE', 'EIP', 'EC2').default('ALB')
        attribute :weight, Types::Integer.default(100)
        attribute :priority, Types::Integer.default(100)
        attribute :enabled, Types::Bool.default(true)
        attribute :health_check_enabled, Types::Bool.default(true)
        attribute :client_ip_preservation, Types::Bool.default(false)
        attribute :metadata, Types::Hash.default({}.freeze)
      end
    end
  end
end
