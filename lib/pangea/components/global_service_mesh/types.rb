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
      
      # Traffic management configuration
      class TrafficManagementConfig < Dry::Struct
        transform_keys(&:to_sym)
        
        attribute :load_balancing_algorithm, Types::String.enum('ROUND_ROBIN', 'RANDOM', 'LEAST_REQUEST').default('ROUND_ROBIN')
        attribute :circuit_breaker_enabled, Types::Bool.default(true)
        attribute :circuit_breaker_threshold, Types::Integer.default(5)
        attribute :outlier_detection_enabled, Types::Bool.default(true)
        attribute :outlier_ejection_duration_seconds, Types::Integer.default(30)
        attribute :max_ejection_percent, Types::Integer.default(50)
        attribute :canary_deployments_enabled, Types::Bool.default(true)
      end
      
      # Cross-region connectivity configuration
      class CrossRegionConfig < Dry::Struct
        transform_keys(&:to_sym)
        
        attribute :peering_enabled, Types::Bool.default(true)
        attribute :transit_gateway_enabled, Types::Bool.default(true)
        attribute :private_link_enabled, Types::Bool.default(false)
        attribute :inter_region_tls_enabled, Types::Bool.default(true)
        attribute :latency_routing_enabled, Types::Bool.default(true)
        attribute :health_based_routing, Types::Bool.default(true)
      end
      
      # Security configuration
      class SecurityConfig < Dry::Struct
        transform_keys(&:to_sym)
        
        attribute :mtls_enabled, Types::Bool.default(true)
        attribute :tls_mode, Types::String.enum('STRICT', 'PERMISSIVE', 'DISABLED').default('STRICT')
        attribute :certificate_authority_arn, Types::String.optional
        attribute :service_auth_enabled, Types::Bool.default(true)
        attribute :rbac_enabled, Types::Bool.default(true)
        attribute :encryption_in_transit, Types::Bool.default(true)
        attribute :secrets_manager_integration, Types::Bool.default(true)
      end
      
      # Observability configuration
      class ObservabilityConfig < Dry::Struct
        transform_keys(&:to_sym)
        
        attribute :xray_enabled, Types::Bool.default(true)
        attribute :cloudwatch_metrics_enabled, Types::Bool.default(true)
        attribute :access_logging_enabled, Types::Bool.default(true)
        attribute :envoy_stats_enabled, Types::Bool.default(true)
        attribute :custom_metrics_enabled, Types::Bool.default(false)
        attribute :distributed_tracing_sampling_rate, Types::Float.default(0.1)
        attribute :log_retention_days, Types::Integer.default(30)
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
      
      # Resilience patterns configuration
      class ResilienceConfig < Dry::Struct
        transform_keys(&:to_sym)
        
        attribute :retry_policy_enabled, Types::Bool.default(true)
        attribute :max_retries, Types::Integer.default(3)
        attribute :retry_timeout_seconds, Types::Integer.default(5)
        attribute :bulkhead_enabled, Types::Bool.default(true)
        attribute :max_connections, Types::Integer.default(100)
        attribute :max_pending_requests, Types::Integer.default(100)
        attribute :timeout_enabled, Types::Bool.default(true)
        attribute :request_timeout_seconds, Types::Integer.default(15)
        attribute :chaos_testing_enabled, Types::Bool.default(false)
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
          if service_names.uniq.length != service_names.length
            errors << "Service names must be unique across the mesh"
          end
          
          # Validate regions match service regions
          service_regions = services.map(&:region).uniq
          missing_regions = service_regions - regions
          if missing_regions.any?
            errors << "Service regions #{missing_regions} not included in mesh regions"
          end
          
          # Validate virtual node configuration
          if virtual_node_config.health_check_interval_millis < 5000
            errors << "Health check interval must be at least 5000ms"
          end
          
          if virtual_node_config.health_check_timeout_millis >= virtual_node_config.health_check_interval_millis
            errors << "Health check timeout must be less than interval"
          end
          
          # Validate traffic management
          if traffic_management.circuit_breaker_threshold < 1
            errors << "Circuit breaker threshold must be at least 1"
          end
          
          if traffic_management.outlier_ejection_duration_seconds < 1
            errors << "Outlier ejection duration must be at least 1 second"
          end
          
          if traffic_management.max_ejection_percent < 0 || traffic_management.max_ejection_percent > 100
            errors << "Max ejection percent must be between 0 and 100"
          end
          
          # Validate security configuration
          if security.mtls_enabled && security.tls_mode == 'DISABLED'
            errors << "mTLS cannot be enabled when TLS mode is DISABLED"
          end
          
          if security.mtls_enabled && !security.certificate_authority_arn
            errors << "Certificate authority ARN required when mTLS is enabled"
          end
          
          # Validate observability
          if observability.distributed_tracing_sampling_rate < 0 || observability.distributed_tracing_sampling_rate > 1
            errors << "Tracing sampling rate must be between 0 and 1"
          end
          
          if observability.log_retention_days < 1 || observability.log_retention_days > 3653
            errors << "Log retention must be between 1 and 3653 days"
          end
          
          # Validate service discovery
          if service_discovery.dns_ttl < 0 || service_discovery.dns_ttl > 300
            errors << "DNS TTL must be between 0 and 300 seconds"
          end
          
          # Validate resilience configuration
          if resilience.max_retries < 0 || resilience.max_retries > 10
            errors << "Max retries must be between 0 and 10"
          end
          
          if resilience.request_timeout_seconds < 1
            errors << "Request timeout must be at least 1 second"
          end
          
          if resilience.max_connections < 1
            errors << "Max connections must be at least 1"
          end
          
          # Validate gateway configuration
          if gateway.gateway_port < 1 || gateway.gateway_port > 65535
            errors << "Gateway port must be between 1 and 65535"
          end
          
          # Validate backend references
          all_service_names = services.map(&:name)
          services.each do |service|
            if virtual_node_config.backends.any?
              invalid_backends = virtual_node_config.backends - all_service_names
              if invalid_backends.any?
                errors << "Service #{service.name} references unknown backends: #{invalid_backends}"
              end
            end
          end
          
          raise ArgumentError, errors.join(", ") unless errors.empty?
          
          true
        end
      end
    end
  end
end