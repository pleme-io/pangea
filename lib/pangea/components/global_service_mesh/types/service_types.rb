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
      # Service definition for the mesh
      class ServiceDefinition < Dry::Struct
        transform_keys(&:to_sym)

        attribute :name, Types::String
        attribute :namespace, Types::String.default('default')
        attribute :port, Types::Integer.default(8080)
        attribute :protocol, Types::String.enum('HTTP', 'HTTP2', 'GRPC', 'TCP').default('HTTP')
        attribute :region, Types::String
        attribute :cluster_ref, Types::ResourceReference.optional
        attribute :task_definition_ref, Types::ResourceReference.optional
        attribute :health_check_path, Types::String.default('/health')
        attribute :timeout_seconds, Types::Integer.default(15)
        attribute :retry_attempts, Types::Integer.default(3)
        attribute :weight, Types::Integer.default(100)
      end

      # Service discovery configuration
      class ServiceDiscoveryConfig < Dry::Struct
        transform_keys(&:to_sym)

        attribute :namespace_name, Types::String
        attribute :namespace_description, Types::String.default('Service mesh namespace')
        attribute :dns_ttl, Types::Integer.default(60)
        attribute :health_check_custom_config_enabled, Types::Bool.default(true)
        attribute :routing_policy, Types::String.enum('MULTIVALUE', 'WEIGHTED').default('MULTIVALUE')
        attribute :cross_region_discovery, Types::Bool.default(true)
      end
    end
  end
end
