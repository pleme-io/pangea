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
      # Advanced routing features
      class AdvancedRoutingConfig < Dry::Struct
        transform_keys(&:to_sym)

        attribute :weighted_distribution, Types::Hash.default({}.freeze)
        attribute :canary_deployment, Types::Hash.default({}.freeze)
        attribute :blue_green_deployment, Types::Hash.default({}.freeze)
        attribute :traffic_dials, Types::Hash.default({}.freeze)
        attribute :custom_headers, Types::Array.of(Types::Hash).default([].freeze)
        attribute :request_routing_rules, Types::Array.of(Types::Hash).default([].freeze)
      end
    end
  end
end
