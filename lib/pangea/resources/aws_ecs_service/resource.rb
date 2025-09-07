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


require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/aws_ecs_service/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS ECS Service with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] ECS service attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_ecs_service(name, attributes = {})
        # Validate attributes using dry-struct
        service_attrs = AWS::Types::Types::EcsServiceAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_ecs_service, name) do
          # Core configuration
          name service_attrs.name
          cluster service_attrs.cluster
          task_definition service_attrs.task_definition
          
          # Scheduling
          desired_count service_attrs.desired_count unless service_attrs.scheduling_strategy == "DAEMON"
          scheduling_strategy service_attrs.scheduling_strategy if service_attrs.scheduling_strategy != "REPLICA"
          
          # Launch type or capacity providers
          if service_attrs.launch_type
            launch_type service_attrs.launch_type
            platform_version service_attrs.platform_version if service_attrs.launch_type == "FARGATE"
          end
          
          # Capacity provider strategy
          service_attrs.capacity_provider_strategy.each do |strategy|
            capacity_provider_strategy do
              capacity_provider strategy.capacity_provider
              weight strategy.weight
              base strategy.base if strategy.base > 0
            end
          end
          
          # Load balancers
          service_attrs.load_balancer.each do |lb|
            load_balancer do
              target_group_arn lb.target_group_arn
              container_name lb.container_name
              container_port lb.container_port
            end
          end
          
          # Network configuration (required for awsvpc)
          if service_attrs.network_configuration
            network_configuration do
              subnets service_attrs.network_configuration.subnets
              security_groups service_attrs.network_configuration.security_groups if service_attrs.network_configuration.security_groups
              assign_public_ip service_attrs.network_configuration.assign_public_ip
            end
          end
          
          # Service registries
          service_attrs.service_registries.each do |registry|
            service_registries do
              registry_arn registry.registry_arn
              port registry.port if registry.port
              container_port registry.container_port if registry.container_port
              container_name registry.container_name if registry.container_name
            end
          end
          
          # Deployment configuration
          deployment_configuration do
            deployment_circuit_breaker do
              enable service_attrs.deployment_configuration.deployment_circuit_breaker[:enable]
              rollback service_attrs.deployment_configuration.deployment_circuit_breaker[:rollback]
            end
            maximum_percent service_attrs.deployment_configuration.maximum_percent
            minimum_healthy_percent service_attrs.deployment_configuration.minimum_healthy_percent
          end
          
          # Placement constraints
          service_attrs.placement_constraints.each do |constraint|
            placement_constraints do
              type constraint.type
              expression constraint.expression if constraint.expression
            end
          end
          
          # Placement strategy
          service_attrs.placement_strategy.each do |strategy|
            placement_strategy do
              type strategy.type
              field strategy.field if strategy.field
            end
          end
          
          # Health check grace period
          health_check_grace_period_seconds service_attrs.health_check_grace_period_seconds if service_attrs.health_check_grace_period_seconds
          
          # Other configurations
          enable_ecs_managed_tags service_attrs.enable_ecs_managed_tags
          enable_execute_command service_attrs.enable_execute_command
          propagate_tags service_attrs.propagate_tags if service_attrs.propagate_tags != "NONE"
          
          # Deployment controller
          deployment_controller do
            type service_attrs.deployment_controller[:type]
          end
          
          # Service Connect configuration
          if service_attrs.service_connect_configuration
            service_connect_configuration do
              enabled service_attrs.service_connect_configuration[:enabled]
              namespace service_attrs.service_connect_configuration[:namespace] if service_attrs.service_connect_configuration[:namespace]
              
              # Service configurations
              if service_attrs.service_connect_configuration[:services]
                service_attrs.service_connect_configuration[:services].each do |svc|
                  service do
                    port_name svc[:port_name]
                    discovery_name svc[:discovery_name] if svc[:discovery_name]
                    ingress_port_override svc[:ingress_port_override] if svc[:ingress_port_override]
                    
                    # Client aliases
                    if svc[:client_aliases]
                      svc[:client_aliases].each do |alias_config|
                        client_alias do
                          port alias_config[:port]
                          dns_name alias_config[:dns_name] if alias_config[:dns_name]
                        end
                      end
                    end
                    
                    # Timeout configuration
                    if svc[:timeout]
                      timeout do
                        idle_timeout_seconds svc[:timeout][:idle_timeout_seconds] if svc[:timeout][:idle_timeout_seconds]
                        per_request_timeout_seconds svc[:timeout][:per_request_timeout_seconds] if svc[:timeout][:per_request_timeout_seconds]
                      end
                    end
                    
                    # TLS configuration
                    if svc[:tls]
                      tls do
                        issuer_certificate_authority do
                          aws_pca_authority_arn svc[:tls][:issuer_certificate_authority][:aws_pca_authority_arn]
                        end
                        kms_key svc[:tls][:kms_key] if svc[:tls][:kms_key]
                        role_arn svc[:tls][:role_arn] if svc[:tls][:role_arn]
                      end
                    end
                  end
                end
              end
              
              # Log configuration for Service Connect
              if service_attrs.service_connect_configuration[:log_configuration]
                log_configuration do
                  log_driver service_attrs.service_connect_configuration[:log_configuration][:log_driver]
                  options service_attrs.service_connect_configuration[:log_configuration][:options] if service_attrs.service_connect_configuration[:log_configuration][:options]
                  
                  if service_attrs.service_connect_configuration[:log_configuration][:secret_options]
                    service_attrs.service_connect_configuration[:log_configuration][:secret_options].each do |secret|
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
          
          # Lifecycle configurations
          wait_for_steady_state service_attrs.wait_for_steady_state
          force_new_deployment service_attrs.force_new_deployment
          
          # Apply tags if present
          if service_attrs.tags.any?
            tags do
              service_attrs.tags.each do |key, value|
                public_send(key, value)
              end
            end
          end
        end
        
        # Return resource reference with available outputs
        ref = ResourceReference.new(
          type: 'aws_ecs_service',
          name: name,
          resource_attributes: service_attrs.to_h,
          outputs: {
            id: "${aws_ecs_service.#{name}.id}",
            name: "${aws_ecs_service.#{name}.name}",
            cluster: "${aws_ecs_service.#{name}.cluster}",
            iam_role: "${aws_ecs_service.#{name}.iam_role}",
            desired_count: "${aws_ecs_service.#{name}.desired_count}",
            launch_type: "${aws_ecs_service.#{name}.launch_type}",
            platform_version: "${aws_ecs_service.#{name}.platform_version}",
            task_definition: "${aws_ecs_service.#{name}.task_definition}",
            load_balancers: "${aws_ecs_service.#{name}.load_balancers}",
            service_registries: "${aws_ecs_service.#{name}.service_registries}",
            tags_all: "${aws_ecs_service.#{name}.tags_all}"
          }
        )
        
        # Add computed properties via method delegation
        ref.define_singleton_method(:using_fargate?) { service_attrs.using_fargate? }
        ref.define_singleton_method(:load_balanced?) { service_attrs.load_balanced? }
        ref.define_singleton_method(:service_discovery_enabled?) { service_attrs.service_discovery_enabled? }
        ref.define_singleton_method(:service_connect_enabled?) { service_attrs.service_connect_enabled? }
        ref.define_singleton_method(:estimated_monthly_cost) { service_attrs.estimated_monthly_cost }
        ref.define_singleton_method(:deployment_safe?) { service_attrs.deployment_safe? }
        ref.define_singleton_method(:is_daemon_service?) { service_attrs.scheduling_strategy == "DAEMON" }
        
        ref
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)