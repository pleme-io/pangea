# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
        class EcsServiceAttributes < Dry::Struct
          transform_keys(&:to_sym)

          attribute :name, Pangea::Resources::Types::String
          attribute :cluster, Pangea::Resources::Types::String
          attribute :task_definition, Pangea::Resources::Types::String
          attribute :desired_count, Pangea::Resources::Types::Integer.constrained(gteq: 0).default(1)
          attribute :scheduling_strategy, Pangea::Resources::Types::String.constrained(included_in: ["REPLICA", "DAEMON"]).default("REPLICA")
          attribute? :launch_type, Pangea::Resources::Types::String.constrained(included_in: ["EC2", "FARGATE", "EXTERNAL"]).optional
          attribute :capacity_provider_strategy, Pangea::Resources::Types::Array.of(EcsCapacityProviderStrategy).default([].freeze)
          attribute :platform_version, Pangea::Resources::Types::String.default("LATEST")
          attribute :load_balancer, Pangea::Resources::Types::Array.of(EcsLoadBalancer).default([].freeze)
          attribute? :network_configuration, EcsNetworkConfiguration.optional
          attribute :service_registries, Pangea::Resources::Types::Array.of(EcsServiceRegistries).default([].freeze)
          attribute :deployment_configuration, EcsDeploymentConfiguration.default(EcsDeploymentConfiguration.new)
          attribute :placement_constraints, Pangea::Resources::Types::Array.of(EcsPlacementConstraint).default([].freeze)
          attribute :placement_strategy, Pangea::Resources::Types::Array.of(EcsPlacementStrategy).default([].freeze)
          attribute? :health_check_grace_period_seconds, Pangea::Resources::Types::Integer.constrained(gteq: 0).optional
          attribute :enable_ecs_managed_tags, Pangea::Resources::Types::Bool.default(true)
          attribute :enable_execute_command, Pangea::Resources::Types::Bool.default(false)
          attribute :propagate_tags, Pangea::Resources::Types::String.constrained(included_in: ["TASK_DEFINITION", "SERVICE", "NONE"]).default("NONE")
          attribute :deployment_controller, Pangea::Resources::Types::Hash.schema(type: Pangea::Resources::Types::String.constrained(included_in: ["ECS", "CODE_DEPLOY", "EXTERNAL"])).default({ type: "ECS" })
          attribute? :service_connect_configuration, Pangea::Resources::Types::Hash.optional
          attribute :tags, Pangea::Resources::Types::AwsTags.default({}.freeze)
          attribute :wait_for_steady_state, Pangea::Resources::Types::Bool.default(false)
          attribute :force_new_deployment, Pangea::Resources::Types::Bool.default(false)

          def self.new(attributes = {})
            attrs = super(attributes)
            raise Dry::Struct::Error, "Invalid task definition" unless attrs.task_definition.match?(/^(arn:aws|[\w\-:]+)/)
            if attrs.scheduling_strategy == "DAEMON"
              raise Dry::Struct::Error, "desired_count must be 0 for DAEMON" if attrs.desired_count != 0
              raise Dry::Struct::Error, "placement_strategy invalid with DAEMON" if attrs.placement_strategy.any?
            end
            raise Dry::Struct::Error, "Cannot mix launch_type and capacity_provider" if attrs.launch_type && attrs.capacity_provider_strategy.any?
            raise Dry::Struct::Error, "health_check_grace_period requires load_balancer" if attrs.health_check_grace_period_seconds && attrs.load_balancer.empty?
            if attrs.service_connect_configuration&.dig(:enabled) && attrs.service_connect_configuration[:services].to_a.empty?
              raise Dry::Struct::Error, "Service Connect requires service configuration"
            end
            attrs
          end
        end
      end
    end
  end
end
