# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

module Pangea
  module Components
    module MicroserviceDeploymentComponent
      module Logging
        def create_log_group(name, component_attrs, component_tag_set)
          log_group_name = component_attrs.log_group_name || "/ecs/#{component_attrs.task_definition_family}"
          aws_cloudwatch_log_group(component_resource_name(name, :log_group), {
            name: log_group_name, retention_in_days: component_attrs.log_retention_days, tags: component_tag_set
          })
        end

        def create_log_streams(name, component_attrs, log_group_ref)
          component_attrs.container_definitions.each_with_object({}) do |container, log_streams|
            log_stream_ref = aws_cloudwatch_log_stream(
              component_resource_name(name, :log_stream, container.name.to_sym),
              { name: "#{component_attrs.log_stream_prefix}/#{container.name}", log_group_name: log_group_ref.name }
            )
            log_streams[container.name.to_sym] = log_stream_ref
          end
        end
      end
    end
  end
end
