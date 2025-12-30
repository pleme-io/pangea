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

require_relative 'types/service_types'
require_relative 'types/infrastructure_types'
require_relative 'types/policy_types'
require_relative 'types/operational_types'

module Pangea
  module Components
    module GlobalServiceMesh
      # Main component attributes
      class GlobalServiceMeshAttributes < Dry::Struct
        transform_keys(&:to_sym)

        # Core configuration
        attribute :mesh_name, Types::String
        attribute :mesh_description, Types::String.default('Global service mesh for microservices')

        # Services in the mesh
        attribute :services, Types::Array.of(ServiceDefinition).constrained(min_size: 1)

        # Mesh regions
        attribute :regions, Types::Array.of(Types::String).constrained(min_size: 1)

        # Virtual node configuration
        attribute :virtual_node_config, VirtualNodeConfig.default { VirtualNodeConfig.new({}) }

        # Traffic management
        attribute :traffic_management, TrafficManagementConfig.default { TrafficManagementConfig.new({}) }

        # Cross-region connectivity
        attribute :cross_region, CrossRegionConfig.default { CrossRegionConfig.new({}) }

        # Security
        attribute :security, SecurityConfig.default { SecurityConfig.new({}) }

        # Observability
        attribute :observability, ObservabilityConfig.default { ObservabilityConfig.new({}) }

        # Service discovery
        attribute :service_discovery, ServiceDiscoveryConfig

        # Resilience patterns
        attribute :resilience, ResilienceConfig.default { ResilienceConfig.new({}) }

        # Gateway configuration
        attribute :gateway, GatewayConfig.default { GatewayConfig.new({}) }

        # Advanced features
        attribute :enable_global_load_balancing, Types::Bool.default(true)
        attribute :enable_multi_cluster_routing, Types::Bool.default(true)
        attribute :enable_service_migration, Types::Bool.default(true)
        attribute :enable_progressive_delivery, Types::Bool.default(true)

        # Tags
        attribute :tags, Types::Hash.default({}.freeze)

        # Custom validations
        def validate!
          errors = []

          # Validate services
          service_names = services.map(&:name)
          errors << 'Service names must be unique across the mesh' if service_names.uniq.length != service_names.length

          # Validate regions match service regions
          service_regions = services.map(&:region).uniq
          missing_regions = service_regions - regions
          errors << "Service regions #{missing_regions} not included in mesh regions" if missing_regions.any?

          # Validate virtual node configuration
          errors << 'Health check interval must be at least 5000ms' if virtual_node_config.health_check_interval_millis < 5000

          if virtual_node_config.health_check_timeout_millis >= virtual_node_config.health_check_interval_millis
            errors << 'Health check timeout must be less than interval'
          end

          # Validate traffic management
          errors << 'Circuit breaker threshold must be at least 1' if traffic_management.circuit_breaker_threshold < 1
          errors << 'Outlier ejection duration must be at least 1 second' if traffic_management.outlier_ejection_duration_seconds < 1

          unless traffic_management.max_ejection_percent.between?(0, 100)
            errors << 'Max ejection percent must be between 0 and 100'
          end

          # Validate security configuration
          errors << 'mTLS cannot be enabled when TLS mode is DISABLED' if security.mtls_enabled && security.tls_mode == 'DISABLED'
          errors << 'Certificate authority ARN required when mTLS is enabled' if security.mtls_enabled && !security.certificate_authority_arn

          # Validate observability
          unless observability.distributed_tracing_sampling_rate.between?(0, 1)
            errors << 'Tracing sampling rate must be between 0 and 1'
          end

          unless observability.log_retention_days.between?(1, 3653)
            errors << 'Log retention must be between 1 and 3653 days'
          end

          # Validate service discovery
          errors << 'DNS TTL must be between 0 and 300 seconds' unless service_discovery.dns_ttl.between?(0, 300)

          # Validate resilience configuration
          errors << 'Max retries must be between 0 and 10' unless resilience.max_retries.between?(0, 10)
          errors << 'Request timeout must be at least 1 second' if resilience.request_timeout_seconds < 1
          errors << 'Max connections must be at least 1' if resilience.max_connections < 1

          # Validate gateway configuration
          errors << 'Gateway port must be between 1 and 65535' unless gateway.gateway_port.between?(1, 65_535)

          # Validate backend references
          all_service_names = services.map(&:name)
          services.each do |service|
            next unless virtual_node_config.backends.any?

            invalid_backends = virtual_node_config.backends - all_service_names
            errors << "Service #{service.name} references unknown backends: #{invalid_backends}" if invalid_backends.any?
          end

          raise ArgumentError, errors.join(', ') unless errors.empty?

          true
        end
      end
    end
  end
end
