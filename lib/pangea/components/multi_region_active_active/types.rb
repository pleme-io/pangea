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
      # Region configuration for active-active deployment
      class RegionConfig < Dry::Struct
        transform_keys(&:to_sym)
        
        attribute :region, Types::String
        attribute :vpc_cidr, Types::String
        attribute :availability_zones, Types::Array.of(Types::String).constrained(min_size: 2, max_size: 6)
        attribute :vpc_ref, Types::ResourceReference.optional
        attribute :is_primary, Types::Bool.default(false)
        attribute :database_priority, Types::Integer.default(100)
        attribute :write_weight, Types::Integer.default(100)
      end
      
      # Data consistency configuration
      class ConsistencyConfig < Dry::Struct
        transform_keys(&:to_sym)
        
        attribute :consistency_model, Types::String.enum('eventual', 'strong', 'bounded').default('eventual')
        attribute :conflict_resolution, Types::String.enum('timestamp', 'region_priority', 'custom').default('timestamp')
        attribute :replication_lag_threshold_ms, Types::Integer.default(100)
        attribute :stale_read_acceptable, Types::Bool.default(false)
        attribute :write_quorum_size, Types::Integer.default(2)
        attribute :read_quorum_size, Types::Integer.default(1)
      end
      
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
      
      # Global database configuration
      class GlobalDatabaseConfig < Dry::Struct
        transform_keys(&:to_sym)
        
        attribute :engine, Types::String.enum('aurora-mysql', 'aurora-postgresql', 'dynamodb').default('aurora-postgresql')
        attribute :engine_version, Types::String.optional
        attribute :instance_class, Types::String.default('db.r5.large')
        attribute :backup_retention_days, Types::Integer.default(7)
        attribute :enable_global_write_forwarding, Types::Bool.default(true)
        attribute :storage_encrypted, Types::Bool.default(true)
        attribute :kms_key_ref, Types::ResourceReference.optional
      end
      
      # Application configuration
      class ApplicationConfig < Dry::Struct
        transform_keys(&:to_sym)
        
        attribute :name, Types::String
        attribute :port, Types::Integer.default(443)
        attribute :protocol, Types::String.enum('HTTP', 'HTTPS', 'TCP').default('HTTPS')
        attribute :health_check_path, Types::String.default('/health')
        attribute :container_image, Types::String.optional
        attribute :task_cpu, Types::Integer.default(256)
        attribute :task_memory, Types::Integer.default(512)
        attribute :desired_count, Types::Integer.default(3)
      end
      
      # Traffic routing configuration
      class TrafficRoutingConfig < Dry::Struct
        transform_keys(&:to_sym)
        
        attribute :routing_policy, Types::String.enum('latency', 'weighted', 'geolocation', 'failover').default('latency')
        attribute :health_check_enabled, Types::Bool.default(true)
        attribute :cross_region_latency_threshold_ms, Types::Integer.default(100)
        attribute :sticky_sessions, Types::Bool.default(false)
        attribute :session_affinity_ttl, Types::Integer.default(3600)
      end
      
      # Monitoring configuration
      class MonitoringConfig < Dry::Struct
        transform_keys(&:to_sym)
        
        attribute :enabled, Types::Bool.default(true)
        attribute :detailed_metrics, Types::Bool.default(true)
        attribute :cross_region_dashboard, Types::Bool.default(true)
        attribute :synthetic_monitoring, Types::Bool.default(true)
        attribute :distributed_tracing, Types::Bool.default(true)
        attribute :log_aggregation, Types::Bool.default(true)
        attribute :anomaly_detection, Types::Bool.default(true)
      end
      
      # Cost optimization configuration
      class CostOptimizationConfig < Dry::Struct
        transform_keys(&:to_sym)
        
        attribute :use_regional_services, Types::Bool.default(true)
        attribute :data_transfer_optimization, Types::Bool.default(true)
        attribute :intelligent_tiering, Types::Bool.default(true)
        attribute :spot_instances_enabled, Types::Bool.default(false)
        attribute :reserved_capacity_planning, Types::Bool.default(true)
      end
      
      # Main component attributes
      class MultiRegionActiveActiveAttributes < Dry::Struct
        transform_keys(&:to_sym)
        
        # Core configuration
        attribute :deployment_name, Types::String
        attribute :deployment_description, Types::String.default("Multi-region active-active infrastructure")
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
        
        # Custom validations
        def validate!
          errors = []
          
          # Validate regions
          region_names = regions.map(&:region)
          if region_names.uniq.length != region_names.length
            errors << "Region names must be unique"
          end
          
          primary_regions = regions.select(&:is_primary)
          if primary_regions.empty?
            errors << "At least one region must be marked as primary"
          elsif primary_regions.length > 1 && consistency.consistency_model == 'strong'
            errors << "Strong consistency requires exactly one primary region"
          end
          
          # Validate CIDR blocks don't overlap
          cidr_blocks = regions.map(&:vpc_cidr)
          if cidr_blocks.uniq.length != cidr_blocks.length
            errors << "VPC CIDR blocks must not overlap across regions"
          end
          
          # Validate consistency configuration
          if consistency.write_quorum_size > regions.length
            errors << "Write quorum size cannot exceed number of regions"
          end
          
          if consistency.read_quorum_size > regions.length
            errors << "Read quorum size cannot exceed number of regions"
          end
          
          # Validate failover configuration
          if failover.health_check_interval < 10 || failover.health_check_interval > 300
            errors << "Health check interval must be between 10 and 300 seconds"
          end
          
          # Validate global database configuration
          if global_database.engine == 'dynamodb' && global_database.instance_class
            errors << "DynamoDB does not use instance classes"
          end
          
          if global_database.backup_retention_days < 1 || global_database.backup_retention_days > 35
            errors << "Backup retention must be between 1 and 35 days"
          end
          
          # Validate application configuration
          if application
            if application.task_cpu < 256 || application.task_cpu > 16384
              errors << "Task CPU must be between 256 and 16384"
            end
            
            if application.task_memory < 512 || application.task_memory > 32768
              errors << "Task memory must be between 512 and 32768"
            end
            
            if application.desired_count < 1
              errors << "Desired count must be at least 1"
            end
          end
          
          # Validate traffic routing
          if traffic_routing.cross_region_latency_threshold_ms < 1
            errors << "Cross-region latency threshold must be at least 1ms"
          end
          
          # Validate compliance regions
          if compliance_regions.any? && !compliance_regions.all? { |r| region_names.include?(r) }
            errors << "Compliance regions must be subset of configured regions"
          end
          
          raise ArgumentError, errors.join(", ") unless errors.empty?
          
          true
        end
      end
    end
  end
end