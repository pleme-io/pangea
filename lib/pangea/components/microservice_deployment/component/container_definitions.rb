# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

module Pangea
  module Components
    module MicroserviceDeploymentComponent
      module ContainerDefinitions
        def build_container_definitions(component_attrs, log_group_ref)
          container_defs = component_attrs.container_definitions.map do |container|
            build_container_definition(container, component_attrs, log_group_ref)
          end
          add_xray_sidecar(container_defs, component_attrs, log_group_ref) if xray_enabled?(component_attrs)
          container_defs
        end

        private

        def build_container_definition(container, component_attrs, log_group_ref)
          definition = {
            name: container.name, image: container.image, cpu: container.cpu, memory: container.memory,
            essential: container.essential, portMappings: container.port_mappings, environment: container.environment,
            secrets: container.secrets, healthCheck: empty_to_nil(container.health_check),
            dependsOn: empty_to_nil(container.depends_on), ulimits: empty_to_nil(container.ulimits),
            mountPoints: empty_to_nil(container.mount_points), volumesFrom: empty_to_nil(container.volume_from),
            logConfiguration: build_log_configuration(container, component_attrs, log_group_ref)
          }.compact
          add_xray_env(definition, component_attrs, container)
          definition
        end

        def build_log_configuration(container, component_attrs, log_group_ref)
          return container.log_configuration unless container.log_configuration.empty?
          {
            logDriver: 'awslogs',
            options: {
              'awslogs-group' => log_group_ref.name, 'awslogs-region' => '${AWS::Region}',
              'awslogs-stream-prefix' => "#{component_attrs.log_stream_prefix}/#{container.name}"
            }
          }
        end

        def add_xray_env(definition, component_attrs, container)
          return unless xray_enabled?(component_attrs) && container.essential
          definition[:environment] ||= []
          definition[:environment] << { name: 'AWS_XRAY_DAEMON_ADDRESS', value: 'localhost:2000' }
        end

        def add_xray_sidecar(container_defs, component_attrs, log_group_ref)
          container_defs << {
            name: 'xray-daemon', image: 'public.ecr.aws/xray/aws-xray-daemon:latest', cpu: 32, memory: 256,
            essential: false, portMappings: [{ containerPort: 2000, protocol: 'udp' }],
            logConfiguration: {
              logDriver: 'awslogs',
              options: {
                'awslogs-group' => log_group_ref.name, 'awslogs-region' => '${AWS::Region}',
                'awslogs-stream-prefix' => "#{component_attrs.log_stream_prefix}/xray"
              }
            }
          }
        end

        def xray_enabled?(component_attrs)
          component_attrs.tracing.enabled && component_attrs.tracing.x_ray
        end

        def empty_to_nil(value)
          value.empty? ? nil : value
        end
      end
    end
  end
end
