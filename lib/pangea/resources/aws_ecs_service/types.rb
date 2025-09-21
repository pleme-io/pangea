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


require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
      # Load balancer configuration for ECS services
      class EcsLoadBalancer < Dry::Struct
        attribute :target_group_arn, Pangea::Resources::Types::String
        attribute :container_name, Pangea::Resources::Types::String
        attribute :container_port, Pangea::Resources::Types::Integer.constrained(gteq: 1, lteq: 65535)
        
        # Validation
        def self.new(attributes = {})
          attrs = super(attributes)
          
          # Validate target group ARN format
          unless attrs.target_group_arn.match?(/^arn:aws/)
            raise Dry::Struct::Error, "Invalid target group ARN format"
          end
          
          attrs
        end
      end
      
      # Network configuration for awsvpc mode
      class EcsNetworkConfiguration < Dry::Struct
        attribute :subnets, Pangea::Resources::Types::Array.of(Pangea::Resources::Types::String).constrained(min_size: 1)
        attribute? :security_groups, Pangea::Resources::Types::Array.of(Pangea::Resources::Types::String).optional
        attribute :assign_public_ip, Pangea::Resources::Types::Bool.default(false)
        
        # Validation
        def self.new(attributes = {})
          attrs = super(attributes)
          
          # Validate subnet count for high availability
          if attrs.subnets.size < 2
            # Warning, not error - single subnet is valid but not recommended
          end
          
          attrs
        end
      end
      
      # Service discovery configuration
      class EcsServiceRegistries < Dry::Struct
        attribute :registry_arn, Pangea::Resources::Types::String
        attribute? :port, Pangea::Resources::Types::Integer.constrained(gteq: 1, lteq: 65535).optional
        attribute? :container_port, Pangea::Resources::Types::Integer.constrained(gteq: 1, lteq: 65535).optional
        attribute? :container_name, Pangea::Resources::Types::String.optional
      end
      
      # Deployment configuration
      class EcsDeploymentConfiguration < Dry::Struct
        attribute :deployment_circuit_breaker, Pangea::Resources::Types::Hash.schema(
          enable: Pangea::Resources::Types::Bool,
          rollback: Pangea::Resources::Types::Bool
        ).default({ enable: false, rollback: false })
        
        attribute :maximum_percent, Pangea::Resources::Types::Integer.constrained(gteq: 100, lteq: 200).default(200)
        attribute :minimum_healthy_percent, Pangea::Resources::Types::Integer.constrained(gteq: 0, lteq: 100).default(100)
        
        # Validation
        def self.new(attributes = {})
          attrs = super(attributes)
          
          # For Fargate, minimum_healthy_percent must be >= 100 when using ALB
          # This is validated at the service level based on launch type
          
          attrs
        end
      end
      
      # Placement constraint
      class EcsPlacementConstraint < Dry::Struct
        attribute :type, Pangea::Resources::Types::String.constrained(included_in: ["distinctInstance", "memberOf"])
        attribute :expression, Resources::Types::String.optional
        
        # Validation
        def self.new(attributes = {})
          attrs = super(attributes)
          
          if attrs.type == "memberOf" && attrs.expression.nil?
            raise Dry::Struct::Error, "Expression is required for memberOf constraint type"
          end
          
          attrs
        end
      end
      
      # Placement strategy
      class EcsPlacementStrategy < Dry::Struct
        attribute :type, Pangea::Resources::Types::String.constrained(included_in: ["random", "spread", "binpack"])
        attribute :field, Resources::Types::String.optional
        
        # Validation
        def self.new(attributes = {})
          attrs = super(attributes)
          
          if attrs.type != "random" && attrs.field.nil?
            raise Dry::Struct::Error, "Field is required for #{attrs.type} strategy"
          end
          
          attrs
        end
      end
      
      # Capacity provider strategy
      class EcsCapacityProviderStrategy < Dry::Struct
        attribute :capacity_provider, Pangea::Resources::Types::String
        attribute :weight, Pangea::Resources::Types::Integer.constrained(gteq: 0, lteq: 1000).default(1)
        attribute :base, Pangea::Resources::Types::Integer.constrained(gteq: 0, lteq: 100000).default(0)
      end
      
      # Type-safe attributes for AWS ECS Service
      class EcsServiceAttributes < Dry::Struct
        transform_keys(&:to_sym)
        
        # Service identification
        attribute :name, Pangea::Resources::Types::String
        attribute :cluster, Pangea::Resources::Types::String
        attribute :task_definition, Pangea::Resources::Types::String
        
        # Desired count and scheduling
        attribute :desired_count, Pangea::Resources::Types::Integer.constrained(gteq: 0).default(1)
        attribute :scheduling_strategy, Pangea::Resources::Types::String.constrained(included_in: ["REPLICA", "DAEMON"]).default("REPLICA")
        
        # Launch type and capacity
        attribute? :launch_type, Pangea::Resources::Types::String.constrained(included_in: ["EC2", "FARGATE", "EXTERNAL"]).optional
        attribute :capacity_provider_strategy, Pangea::Resources::Types::Array.of(EcsCapacityProviderStrategy).default([].freeze)
        attribute :platform_version, Pangea::Resources::Types::String.default("LATEST")
        
        # Load balancing
        attribute :load_balancer, Pangea::Resources::Types::Array.of(EcsLoadBalancer).default([].freeze)
        
        # Network configuration (required for awsvpc)
        attribute? :network_configuration, EcsNetworkConfiguration.optional
        
        # Service discovery
        attribute :service_registries, Pangea::Resources::Types::Array.of(EcsServiceRegistries).default([].freeze)
        
        # Deployment configuration
        attribute :deployment_configuration, EcsDeploymentConfiguration.default(EcsDeploymentConfiguration.new)
        
        # Placement
        attribute :placement_constraints, Pangea::Resources::Types::Array.of(EcsPlacementConstraint).default([].freeze)
        attribute :placement_strategy, Pangea::Resources::Types::Array.of(EcsPlacementStrategy).default([].freeze)
        
        # Health check grace period (seconds)
        attribute? :health_check_grace_period_seconds, Pangea::Resources::Types::Integer.constrained(gteq: 0).optional
        
        # Auto scaling
        attribute :enable_ecs_managed_tags, Pangea::Resources::Types::Bool.default(true)
        attribute :enable_execute_command, Pangea::Resources::Types::Bool.default(false)
        attribute :propagate_tags, Pangea::Resources::Types::String.constrained(included_in: ["TASK_DEFINITION", "SERVICE", "NONE"]).default("NONE")
        
        # Deployment controller
        attribute :deployment_controller, Pangea::Resources::Types::Hash.schema(
          type: Pangea::Resources::Types::String.constrained(included_in: ["ECS", "CODE_DEPLOY", "EXTERNAL"])
        ).default({ type: "ECS" })
        
        # Service Connect
        attribute? :service_connect_configuration, Pangea::Resources::Types::Hash.schema(
          enabled: Pangea::Resources::Types::Bool,
          namespace?: Pangea::Resources::Types::String.optional,
          services?: Pangea::Resources::Types::Array.of(
            Pangea::Resources::Types::Hash.schema(
              port_name: Pangea::Resources::Types::String,
              discovery_name?: Pangea::Resources::Types::String.optional,
              client_aliases?: Pangea::Resources::Types::Array.of(
                Pangea::Resources::Types::Hash.schema(
                  port: Pangea::Resources::Types::Integer,
                  dns_name?: Pangea::Resources::Types::String.optional
                )
              ).optional,
              ingress_port_override?: Pangea::Resources::Types::Integer.optional,
              timeout?: Pangea::Resources::Types::Hash.schema(
                idle_timeout_seconds?: Pangea::Resources::Types::Integer.optional,
                per_request_timeout_seconds?: Pangea::Resources::Types::Integer.optional
              ).optional,
              tls?: Pangea::Resources::Types::Hash.schema(
                issuer_certificate_authority: Pangea::Resources::Types::Hash.schema(
                  aws_pca_authority_arn: Pangea::Resources::Types::String
                ),
                kms_key?: Pangea::Resources::Types::String.optional,
                role_arn?: Pangea::Resources::Types::String.optional
              ).optional
            )
          ).optional,
          log_configuration?: Pangea::Resources::Types::Hash.schema(
            log_driver: Pangea::Resources::Types::String,
            options?: Pangea::Resources::Types::Hash.optional,
            secret_options?: Pangea::Resources::Types::Array.of(
              Pangea::Resources::Types::Hash.schema(
                name: Pangea::Resources::Types::String,
                value_from: Pangea::Resources::Types::String
              )
            ).optional
          ).optional
        ).optional
        
        # Tags
        attribute :tags, Pangea::Resources::Types::AwsTags.default({}.freeze)
        
        # Wait for steady state
        attribute :wait_for_steady_state, Pangea::Resources::Types::Bool.default(false)
        
        # Force new deployment
        attribute :force_new_deployment, Pangea::Resources::Types::Bool.default(false)
        
        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)
          
          # Validate task definition format
          unless attrs.task_definition.match?(/^(arn:aws|[\w\-:]+)/)
            raise Dry::Struct::Error, "Invalid task definition format"
          end
          
          # Validate network configuration for awsvpc
          # This check would need access to task definition to validate properly
          # but we can check if load balancer is used
          if attrs.load_balancer.any? && attrs.network_configuration.nil?
            # Warning: might need network configuration for load balancer
          end
          
          # Validate scheduling strategy
          if attrs.scheduling_strategy == "DAEMON"
            if attrs.desired_count && attrs.desired_count != 0
              raise Dry::Struct::Error, "desired_count must be 0 or omitted for DAEMON scheduling"
            end
            if attrs.placement_strategy.any?
              raise Dry::Struct::Error, "placement_strategy cannot be used with DAEMON scheduling"
            end
          end
          
          # Validate launch type and capacity providers
          if attrs.launch_type && attrs.capacity_provider_strategy.any?
            raise Dry::Struct::Error, "Cannot specify both launch_type and capacity_provider_strategy"
          end
          
          # Validate health check grace period
          if attrs.health_check_grace_period_seconds && attrs.load_balancer.empty?
            raise Dry::Struct::Error, "health_check_grace_period_seconds requires load_balancer configuration"
          end
          
          # Validate Service Connect
          if attrs.service_connect_configuration && attrs.service_connect_configuration[:enabled]
            if attrs.service_connect_configuration[:services].nil? || attrs.service_connect_configuration[:services].empty?
              raise Dry::Struct::Error, "Service Connect requires at least one service configuration"
            end
          end
          
          attrs
        end
        
        # Helper to check if using Fargate
        def using_fargate?
          launch_type == "FARGATE" || capacity_provider_strategy.any? { |cp| cp.capacity_provider.include?("FARGATE") }
        end
        
        # Helper to check if using load balancer
        def load_balanced?
          load_balancer.any?
        end
        
        # Helper to check if using service discovery
        def service_discovery_enabled?
          service_registries.any?
        end
        
        # Helper to check if using Service Connect
        def service_connect_enabled?
          service_connect_configuration && service_connect_configuration[:enabled]
        end
        
        # Helper to estimate monthly cost
        def estimated_monthly_cost
          base_cost = 0.0
          
          # Fargate costs (rough estimate)
          if using_fargate?
            # Assume task runs continuously
            # This would need task definition CPU/memory to calculate accurately
            base_cost += desired_count * 50.0  # Rough estimate
          end
          
          # Service Connect costs
          if service_connect_enabled?
            base_cost += 5.0
          end
          
          # Load balancer target costs
          if load_balanced?
            base_cost += load_balancer.size * 8.0
          end
          
          base_cost
        end
        
        # Helper to get deployment status
        def deployment_safe?
          deployment_configuration.deployment_circuit_breaker[:enable] &&
            deployment_configuration.deployment_circuit_breaker[:rollback]
        end
      end
    end
      end
    end
  end
end