# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

module Pangea
  module Components
    module MicroserviceDeploymentComponent
      module Service
        def create_task_definition(name, component_attrs, container_defs, component_tag_set)
          aws_ecs_task_definition(component_resource_name(name, :task_definition), {
            family: component_attrs.task_definition_family, network_mode: 'awsvpc',
            requires_compatibilities: [component_attrs.launch_type], cpu: component_attrs.task_cpu,
            memory: component_attrs.task_memory, task_role_arn: component_attrs.task_role_arn,
            execution_role_arn: component_attrs.execution_role_arn,
            container_definitions: JSON.generate(container_defs), tags: component_tag_set
          }.compact)
        end

        def create_service_discovery(name, component_attrs, component_tag_set)
          return nil unless component_attrs.service_discovery
          sd_config = component_attrs.service_discovery
          aws_service_discovery_service(component_resource_name(name, :service_discovery), {
            name: sd_config.service_name, dns_config: sd_config.dns_config,
            health_check_custom_config: sd_config.health_check_custom_config,
            namespace_id: sd_config.namespace_id, tags: component_tag_set
          })
        end

        def build_service_registry(sd_service_ref, component_attrs, container_defs)
          return nil unless sd_service_ref
          [{
            registry_arn: sd_service_ref.arn,
            container_name: component_attrs.container_name || container_defs.find { |c| c[:essential] }[:name],
            container_port: component_attrs.container_port
          }]
        end

        def build_load_balancers(component_attrs, container_defs)
          component_attrs.target_group_refs.map do |tg_ref|
            {
              target_group_arn: tg_ref.arn,
              container_name: component_attrs.container_name || container_defs.find { |c| c[:essential] }[:name],
              container_port: component_attrs.container_port
            }
          end
        end

        def create_ecs_service(name, component_attrs, task_def_ref, load_balancers, service_registry, component_tag_set)
          service_attrs = {
            name: "#{name}-service", cluster: component_attrs.cluster_ref.arn,
            task_definition: task_def_ref.arn, desired_count: component_attrs.desired_count,
            launch_type: component_attrs.launch_type, platform_version: component_attrs.platform_version,
            enable_execute_command: component_attrs.enable_execute_command,
            network_configuration: build_network_config(component_attrs),
            deployment_configuration: build_deployment_config(component_attrs),
            health_check_grace_period_seconds: load_balancers.any? ? component_attrs.health_check_grace_period : nil,
            load_balancer: load_balancers.empty? ? nil : load_balancers,
            service_registries: service_registry, tags: component_tag_set
          }.compact
          aws_ecs_service(component_resource_name(name, :service), service_attrs)
        end

        private

        def build_network_config(component_attrs)
          {
            awsvpc_configuration: {
              subnets: component_attrs.subnet_refs.map(&:id),
              security_groups: component_attrs.security_group_refs.map(&:id),
              assign_public_ip: component_attrs.assign_public_ip ? 'ENABLED' : 'DISABLED'
            }
          }
        end

        def build_deployment_config(component_attrs)
          {
            maximum_percent: component_attrs.deployment_maximum_percent,
            minimum_healthy_percent: component_attrs.deployment_minimum_healthy_percent,
            deployment_circuit_breaker: {
              enable: component_attrs.circuit_breaker.enabled, rollback: component_attrs.circuit_breaker.rollback
            }
          }
        end
      end
    end
  end
end
