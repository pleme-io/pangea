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

require_relative 'types/region_config'
require_relative 'types/consistency_config'
require_relative 'types/failover_config'
require_relative 'types/database_config'
require_relative 'types/application_config'
require_relative 'types/routing_config'
require_relative 'types/monitoring_config'
require_relative 'types/cost_config'
require_relative 'types/validators'

module Pangea
  module Components
    module MultiRegionActiveActive
      # Main component attributes for multi-region active-active deployment
      class MultiRegionActiveActiveAttributes < Dry::Struct
        include Validators

        transform_keys(&:to_sym)

        # Core configuration
        attribute :deployment_name, Types::String
        attribute :deployment_description, Types::String.default('Multi-region active-active infrastructure')
        attribute :domain_name, Types::String

        # Region configurations
        attribute :regions, Types::Array.of(RegionConfig).constrained(min_size: 2)

        # Data consistency
        attribute :consistency, ConsistencyConfig.default { ConsistencyConfig.new({}) }

        # Failover configuration
        attribute :failover, FailoverConfig.default { FailoverConfig.new({}) }

        # Global database
        attribute :global_database, GlobalDatabaseConfig.default { GlobalDatabaseConfig.new({}) }

        # Application configuration
        attribute :application, ApplicationConfig.optional

        # Traffic routing
        attribute :traffic_routing, TrafficRoutingConfig.default { TrafficRoutingConfig.new({}) }

        # Monitoring
        attribute :monitoring, MonitoringConfig.default { MonitoringConfig.new({}) }

        # Cost optimization
        attribute :cost_optimization, CostOptimizationConfig.default { CostOptimizationConfig.new({}) }

        # Compliance and data residency
        attribute :data_residency_enabled, Types::Bool.default(true)
        attribute :compliance_regions, Types::Array.of(Types::String).default([].freeze)
        attribute :enable_data_localization, Types::Bool.default(false)

        # Advanced features
        attribute :enable_global_accelerator, Types::Bool.default(true)
        attribute :enable_circuit_breaker, Types::Bool.default(true)
        attribute :enable_bulkhead_pattern, Types::Bool.default(true)
        attribute :enable_chaos_engineering, Types::Bool.default(false)

        # Tags
        attribute :tags, Types::Hash.default({}.freeze)
      end
    end
  end
end
