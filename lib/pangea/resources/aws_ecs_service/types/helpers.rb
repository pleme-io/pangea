# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

module Pangea
  module Resources
    module AWS
      module Types
        class EcsServiceAttributes
          def using_fargate?
            launch_type == "FARGATE" || capacity_provider_strategy.any? { |cp| cp.capacity_provider.include?("FARGATE") }
          end

          def load_balanced? = load_balancer.any?
          def service_discovery_enabled? = service_registries.any?
          def service_connect_enabled? = service_connect_configuration&.dig(:enabled)

          def estimated_monthly_cost
            cost = 0.0
            cost += desired_count * 50.0 if using_fargate?
            cost += 5.0 if service_connect_enabled?
            cost += load_balancer.size * 8.0 if load_balanced?
            cost
          end

          def deployment_safe?
            deployment_configuration.deployment_circuit_breaker[:enable] &&
              deployment_configuration.deployment_circuit_breaker[:rollback]
          end
        end
      end
    end
  end
end
