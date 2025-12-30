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
    module MicroserviceDeployment
      # Service discovery configuration
      class ServiceDiscoveryConfig < Dry::Struct
        transform_keys(&:to_sym)

        attribute :namespace_id, Types::String.optional
        attribute :service_name, Types::String
        attribute :dns_config, Types::Hash.default({
          routing_policy: "MULTIVALUE",
          dns_records: [{
            type: "A",
            ttl: 60
          }]
        }.freeze)
        attribute :health_check_custom_config, Types::Hash.default({
          failure_threshold: 1
        }.freeze)
      end
    end
  end
end
