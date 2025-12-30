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

# Sub-types
require_relative 'types/container_definition'
require_relative 'types/service_discovery_config'
require_relative 'types/circuit_breaker_config'
require_relative 'types/auto_scaling_config'
require_relative 'types/health_check_config'
require_relative 'types/tracing_config'

module Pangea
  module Components
    module MicroserviceDeployment
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
            valid_combinations = fargate_cpu_memory_combinations
            unless valid_combinations[task_cpu]&.include?(task_memory)
              errors << "Invalid CPU/Memory combination for Fargate: #{task_cpu}/#{task_memory}"
            end
          end

          validate_containers!(errors)
          validate_auto_scaling!(errors)
          validate_health_check!(errors)
          validate_tracing!(errors)
          validate_deployment!(errors)

          raise ArgumentError, errors.join(", ") unless errors.empty?

          true
        end

        private

        def fargate_cpu_memory_combinations
          {
            "256" => ["512", "1024", "2048"],
            "512" => ["1024", "2048", "3072", "4096"],
            "1024" => ["2048", "3072", "4096", "5120", "6144", "7168", "8192"],
            "2048" => %w[4096 5120 6144 7168 8192 9216 10240 11264 12288 13312 14336 15360 16384],
            "4096" => %w[8192 9216 10240 11264 12288 13312 14336 15360 16384 17408 18432 19456
                         20480 21504 22528 23552 24576 25600 26624 27648 28672 29696 30720]
          }
        end

        def validate_containers!(errors)
          errors << "At least one container definition is required" if container_definitions.empty?
          essential_count = container_definitions.count(&:essential)
          errors << "At least one container must be marked as essential" if essential_count.zero?
        end

        def validate_auto_scaling!(errors)
          return unless auto_scaling.enabled

          if auto_scaling.min_tasks >= auto_scaling.max_tasks
            errors << "Auto-scaling min_tasks must be less than max_tasks"
          end
          errors << "Auto-scaling min_tasks must be at least 1" if auto_scaling.min_tasks < 1
        end

        def validate_health_check!(errors)
          errors << "Health check path must start with /" unless health_check.path.start_with?("/")
        end

        def validate_tracing!(errors)
          return unless tracing.enabled

          unless tracing.sampling_rate.between?(0, 1)
            errors << "Tracing sampling rate must be between 0 and 1"
          end
        end

        def validate_deployment!(errors)
          if deployment_minimum_healthy_percent >= deployment_maximum_percent
            errors << "Deployment minimum healthy percent must be less than maximum percent"
          end
          if enable_blue_green && target_group_refs.length < 2
            errors << "Blue-green deployment requires at least 2 target groups"
          end
        end
      end
    end
  end
end
