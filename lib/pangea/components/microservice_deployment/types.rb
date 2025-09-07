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
      # Container definition attributes
      class ContainerDefinition < Dry::Struct
        transform_keys(&:to_sym)
        
        attribute :name, Types::String
        attribute :image, Types::String
        attribute :cpu, Types::Integer.default(256)
        attribute :memory, Types::Integer.default(512)
        attribute :essential, Types::Bool.default(true)
        attribute :port_mappings, Types::Array.of(Types::Hash).default([].freeze)
        attribute :environment, Types::Array.of(Types::Hash).default([].freeze)
        attribute :secrets, Types::Array.of(Types::Hash).default([].freeze)
        attribute :health_check, Types::Hash.default({}.freeze)
        attribute :log_configuration, Types::Hash.default({}.freeze)
        attribute :depends_on, Types::Array.of(Types::Hash).default([].freeze)
        attribute :ulimits, Types::Array.of(Types::Hash).default([].freeze)
        attribute :mount_points, Types::Array.of(Types::Hash).default([].freeze)
        attribute :volume_from, Types::Array.of(Types::Hash).default([].freeze)
      end
      
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
      
      # Circuit breaker configuration for resilience
      class CircuitBreakerConfig < Dry::Struct
        transform_keys(&:to_sym)
        
        attribute :enabled, Types::Bool.default(true)
        attribute :threshold, Types::Integer.default(5)
        attribute :timeout, Types::Integer.default(60)
        attribute :rollback, Types::Bool.default(true)
      end
      
      # Auto-scaling configuration
      class AutoScalingConfig < Dry::Struct
        transform_keys(&:to_sym)
        
        attribute :enabled, Types::Bool.default(true)
        attribute :min_tasks, Types::Integer.default(2)
        attribute :max_tasks, Types::Integer.default(10)
        attribute :target_cpu, Types::Float.default(70.0)
        attribute :target_memory, Types::Float.default(70.0)
        attribute :scale_out_cooldown, Types::Integer.default(300)
        attribute :scale_in_cooldown, Types::Integer.default(300)
      end
      
      # Health check configuration
      class HealthCheckConfig < Dry::Struct
        transform_keys(&:to_sym)
        
        attribute :path, Types::String.default("/health")
        attribute :interval, Types::Integer.default(30)
        attribute :timeout, Types::Integer.default(5)
        attribute :healthy_threshold, Types::Integer.default(2)
        attribute :unhealthy_threshold, Types::Integer.default(3)
        attribute :matcher, Types::String.default("200")
      end
      
      # Distributed tracing configuration
      class TracingConfig < Dry::Struct
        transform_keys(&:to_sym)
        
        attribute :enabled, Types::Bool.default(true)
        attribute :sampling_rate, Types::Float.default(0.1)
        attribute :x_ray, Types::Bool.default(true)
        attribute :jaeger, Types::Bool.default(false)
        attribute :zipkin, Types::Bool.default(false)
      end
      
      # Main component attributes
      class MicroserviceDeploymentAttributes < Dry::Struct
        transform_keys(&:to_sym)
        
        # Core configuration
        attribute :cluster_ref, Types::ResourceReference
        attribute :task_definition_family, Types::String
        attribute :container_definitions, Types::Array.of(ContainerDefinition)
        
        # Network configuration
        attribute :vpc_ref, Types::ResourceReference
        attribute :subnet_refs, Types::Array.of(Types::ResourceReference).constrained(min_size: 2)
        attribute :security_group_refs, Types::Array.of(Types::ResourceReference).default([].freeze)
        attribute :assign_public_ip, Types::Bool.default(false)
        
        # Service configuration
        attribute :desired_count, Types::Integer.default(2)
        attribute :launch_type, Types::String.default("FARGATE")
        attribute :platform_version, Types::String.default("LATEST")
        attribute :enable_execute_command, Types::Bool.default(true)
        
        # Task configuration
        attribute :task_cpu, Types::String.default("256")
        attribute :task_memory, Types::String.default("512")
        attribute :task_role_arn, Types::String.optional
        attribute :execution_role_arn, Types::String.optional
        
        # Load balancer configuration
        attribute :target_group_refs, Types::Array.of(Types::ResourceReference).default([].freeze)
        attribute :container_name, Types::String.optional
        attribute :container_port, Types::Integer.default(80)
        
        # Service discovery
        attribute :service_discovery, ServiceDiscoveryConfig.optional
        
        # Resilience patterns
        attribute :circuit_breaker, CircuitBreakerConfig.default { CircuitBreakerConfig.new({}) }
        attribute :health_check_grace_period, Types::Integer.default(60)
        
        # Auto-scaling
        attribute :auto_scaling, AutoScalingConfig.default { AutoScalingConfig.new({}) }
        
        # Health checks
        attribute :health_check, HealthCheckConfig.default { HealthCheckConfig.new({}) }
        
        # Distributed tracing
        attribute :tracing, TracingConfig.default { TracingConfig.new({}) }
        
        # Deployment configuration
        attribute :deployment_minimum_healthy_percent, Types::Integer.default(50)
        attribute :deployment_maximum_percent, Types::Integer.default(200)
        attribute :enable_blue_green, Types::Bool.default(false)
        
        # Logging configuration
        attribute :log_group_name, Types::String.optional
        attribute :log_retention_days, Types::Integer.default(7)
        attribute :log_stream_prefix, Types::String.default("ecs")
        
        # Tags
        attribute :tags, Types::Hash.default({}.freeze)
        
        # Custom validations
        def validate!
          errors = []
          
          # Validate CPU/Memory combinations for Fargate
          if launch_type == "FARGATE"
            valid_combinations = {
              "256" => ["512", "1024", "2048"],
              "512" => ["1024", "2048", "3072", "4096"],
              "1024" => ["2048", "3072", "4096", "5120", "6144", "7168", "8192"],
              "2048" => ["4096", "5120", "6144", "7168", "8192", "9216", "10240", "11264", "12288", "13312", "14336", "15360", "16384"],
              "4096" => ["8192", "9216", "10240", "11264", "12288", "13312", "14336", "15360", "16384", "17408", "18432", "19456", "20480", "21504", "22528", "23552", "24576", "25600", "26624", "27648", "28672", "29696", "30720"]
            }
            
            unless valid_combinations[task_cpu]&.include?(task_memory)
              errors << "Invalid CPU/Memory combination for Fargate: #{task_cpu}/#{task_memory}"
            end
          end
          
          # Validate container definitions
          if container_definitions.empty?
            errors << "At least one container definition is required"
          end
          
          # Validate essential containers
          essential_count = container_definitions.count { |c| c.essential }
          if essential_count == 0
            errors << "At least one container must be marked as essential"
          end
          
          # Validate auto-scaling configuration
          if auto_scaling.enabled
            if auto_scaling.min_tasks >= auto_scaling.max_tasks
              errors << "Auto-scaling min_tasks must be less than max_tasks"
            end
            
            if auto_scaling.min_tasks < 1
              errors << "Auto-scaling min_tasks must be at least 1"
            end
          end
          
          # Validate health check path
          if health_check.path !~ /^\//
            errors << "Health check path must start with /"
          end
          
          # Validate tracing sampling rate
          if tracing.enabled && (tracing.sampling_rate < 0 || tracing.sampling_rate > 1)
            errors << "Tracing sampling rate must be between 0 and 1"
          end
          
          # Validate deployment percentages
          if deployment_minimum_healthy_percent >= deployment_maximum_percent
            errors << "Deployment minimum healthy percent must be less than maximum percent"
          end
          
          # Validate blue-green deployment requirements
          if enable_blue_green && target_group_refs.length < 2
            errors << "Blue-green deployment requires at least 2 target groups"
          end
          
          raise ArgumentError, errors.join(", ") unless errors.empty?
          
          true
        end
      end
    end
  end
end