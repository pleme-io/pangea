# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

module Pangea
  module Resources
    module AWS
      # DSL methods for building ECS service resource blocks
      # Extended into the resource block context to provide builder methods
      module EcsServiceConnectDsl
        def build_core_config(attrs)
          name attrs.name
          cluster attrs.cluster
          task_definition attrs.task_definition
        end

        def build_scheduling_config(attrs)
          desired_count attrs.desired_count unless attrs.scheduling_strategy == "DAEMON"
          scheduling_strategy attrs.scheduling_strategy if attrs.scheduling_strategy != "REPLICA"
        end

        def build_launch_config(attrs)
          return unless attrs.launch_type

          launch_type attrs.launch_type
          platform_version attrs.platform_version if attrs.launch_type == "FARGATE"
        end

        def build_capacity_provider_strategy(attrs)
          attrs.capacity_provider_strategy.each do |strategy|
            capacity_provider_strategy do
              capacity_provider strategy.capacity_provider
              weight strategy.weight
              base strategy.base if strategy.base > 0
            end
          end
        end

        def build_load_balancers(attrs)
          attrs.load_balancer.each do |lb|
            load_balancer do
              target_group_arn lb.target_group_arn
              container_name lb.container_name
              container_port lb.container_port
            end
          end
        end

        def build_network_config(attrs)
          return unless attrs.network_configuration

          network_configuration do
            subnets attrs.network_configuration.subnets
            security_groups attrs.network_configuration.security_groups if attrs.network_configuration.security_groups
            assign_public_ip attrs.network_configuration.assign_public_ip
          end
        end

        def build_service_registries(attrs)
          attrs.service_registries.each do |registry|
            service_registries do
              registry_arn registry.registry_arn
              port registry.port if registry.port
              container_port registry.container_port if registry.container_port
              container_name registry.container_name if registry.container_name
            end
          end
        end

        def build_deployment_config(attrs)
          deployment_configuration do
            deployment_circuit_breaker do
              enable attrs.deployment_configuration.deployment_circuit_breaker[:enable]
              rollback attrs.deployment_configuration.deployment_circuit_breaker[:rollback]
            end
            maximum_percent attrs.deployment_configuration.maximum_percent
            minimum_healthy_percent attrs.deployment_configuration.minimum_healthy_percent
          end

          deployment_controller do
            type attrs.deployment_controller[:type]
          end
        end

        def build_placement_config(attrs)
          attrs.placement_constraints.each do |constraint|
            placement_constraints do
              type constraint.type
              expression constraint.expression if constraint.expression
            end
          end

          attrs.placement_strategy.each do |strategy|
            placement_strategy do
              type strategy.type
              field strategy.field if strategy.field
            end
          end
        end

        def build_additional_config(attrs)
          health_check_grace_period_seconds attrs.health_check_grace_period_seconds if attrs.health_check_grace_period_seconds
          enable_ecs_managed_tags attrs.enable_ecs_managed_tags
          enable_execute_command attrs.enable_execute_command
          propagate_tags attrs.propagate_tags if attrs.propagate_tags != "NONE"
        end

        def build_service_connect_config(attrs)
          config = attrs.service_connect_configuration
          return unless config

          service_connect_configuration do
            enabled config[:enabled]
            namespace config[:namespace] if config[:namespace]

            build_service_connect_services(config[:services]) if config[:services]
            build_service_connect_log_config(config[:log_configuration]) if config[:log_configuration]
          end
        end

        def build_lifecycle_config(attrs)
          wait_for_steady_state attrs.wait_for_steady_state
          force_new_deployment attrs.force_new_deployment
        end

        def build_tags(attrs)
          return unless attrs.tags.any?

          tags do
            attrs.tags.each { |key, value| public_send(key, value) }
          end
        end

        # Service Connect nested block builders
        def build_service_connect_services(services)
          services.each { |svc| build_service_connect_service(svc) }
        end

        def build_service_connect_service(svc)
          service do
            port_name svc[:port_name]
            discovery_name svc[:discovery_name] if svc[:discovery_name]
            ingress_port_override svc[:ingress_port_override] if svc[:ingress_port_override]

            build_client_aliases(svc[:client_aliases]) if svc[:client_aliases]
            build_timeout_config(svc[:timeout]) if svc[:timeout]
            build_tls_config(svc[:tls]) if svc[:tls]
          end
        end

        def build_client_aliases(aliases)
          aliases.each do |alias_config|
            client_alias do
              port alias_config[:port]
              dns_name alias_config[:dns_name] if alias_config[:dns_name]
            end
          end
        end

        def build_timeout_config(timeout_config)
          timeout do
            idle_timeout_seconds timeout_config[:idle_timeout_seconds] if timeout_config[:idle_timeout_seconds]
            per_request_timeout_seconds timeout_config[:per_request_timeout_seconds] if timeout_config[:per_request_timeout_seconds]
          end
        end

        def build_tls_config(tls_config)
          tls do
            issuer_certificate_authority do
              aws_pca_authority_arn tls_config[:issuer_certificate_authority][:aws_pca_authority_arn]
            end
            kms_key tls_config[:kms_key] if tls_config[:kms_key]
            role_arn tls_config[:role_arn] if tls_config[:role_arn]
          end
        end

        def build_service_connect_log_config(log_config)
          log_configuration do
            log_driver log_config[:log_driver]
            options log_config[:options] if log_config[:options]

            log_config[:secret_options]&.each do |secret|
              secret_option do
                name secret[:name]
                value_from secret[:value_from]
              end
            end
          end
        end
      end
    end
  end
end
