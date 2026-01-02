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
    module GlobalServiceMesh
      # Virtual node configuration
      class VirtualNodeConfig < Dry::Struct
        transform_keys(&:to_sym)

        attribute :service_discovery_type, Types::String.enum('DNS', 'CLOUD_MAP', 'CLOUD_MAP_WITH_ECS').default('CLOUD_MAP')
        attribute :listener_port, Types::Integer.default(8080)
        attribute :health_check_interval_millis, Types::Integer.default(30000)
        attribute :health_check_timeout_millis, Types::Integer.default(5000)
        attribute :healthy_threshold, Types::Integer.default(2)
        attribute :unhealthy_threshold, Types::Integer.default(3)
        attribute :backends, Types::Array.of(Types::String).default([].freeze)
      end

      # Gateway configuration
      class GatewayConfig < Dry::Struct
        transform_keys(&:to_sym)

        attribute :ingress_gateway_enabled, Types::Bool.default(true)
        attribute :egress_gateway_enabled, Types::Bool.default(true)
        attribute :gateway_port, Types::Integer.default(443)
        attribute :gateway_protocol, Types::String.enum('HTTP', 'HTTPS', 'HTTP2', 'GRPC').default('HTTPS')
        attribute :custom_domain_enabled, Types::Bool.default(true)
        attribute :waf_enabled, Types::Bool.default(true)
        attribute :rate_limiting_enabled, Types::Bool.default(true)
      end
    end
  end
end
