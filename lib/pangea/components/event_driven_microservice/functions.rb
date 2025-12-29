# frozen_string_literal: true

module Pangea
  module Components
    module EventDrivenMicroservice
      # Lambda function creation
      module Functions
        def create_lambda_function(name, function_name, config, role_ref, component_attrs, tags)
          aws_lambda_function(name, {
            function_name: function_name,
            role: role_ref.arn,
            handler: config.handler,
            runtime: config.runtime,
            timeout: config.timeout,
            memory_size: config.memory_size,
            environment: lambda_environment(config, component_attrs),
            layers: config.layers,
            reserved_concurrent_executions: config.reserved_concurrent_executions,
            dead_letter_config: lambda_dead_letter_config(config),
            vpc_config: lambda_vpc_config(component_attrs),
            tracing_config: { mode: 'Active' },
            tags: tags
          }.compact)
        end

        def create_command_handler(name, component_attrs, lambda_role_ref, component_tag_set)
          create_lambda_function(
            component_resource_name(name, :command_handler),
            "#{name}-command-handler",
            component_attrs.command_handler,
            lambda_role_ref,
            component_attrs,
            component_tag_set
          )
        end

        def create_query_handler(name, component_attrs, lambda_role_ref, component_tag_set)
          return nil unless component_attrs.query_handler

          create_lambda_function(
            component_resource_name(name, :query_handler),
            "#{name}-query-handler",
            component_attrs.query_handler,
            lambda_role_ref,
            component_attrs,
            component_tag_set
          )
        end

        def create_event_processor(name, component_attrs, lambda_role_ref, component_tag_set)
          return nil unless component_attrs.event_processor

          create_lambda_function(
            component_resource_name(name, :event_processor),
            "#{name}-event-processor",
            component_attrs.event_processor,
            lambda_role_ref,
            component_attrs,
            component_tag_set
          )
        end

        private

        def lambda_environment(config, component_attrs)
          {
            variables: config.environment_variables.merge({
              SERVICE_NAME: component_attrs.service_name,
              EVENT_STORE_TABLE: component_attrs.event_store.table_name
            })
          }
        end

        def lambda_dead_letter_config(config)
          return nil unless config.dead_letter_config_arn

          { target_arn: config.dead_letter_config_arn }
        end

        def lambda_vpc_config(component_attrs)
          return nil unless component_attrs.vpc_ref

          {
            subnet_ids: component_attrs.subnet_refs.map(&:id),
            security_group_ids: component_attrs.security_group_refs.map(&:id)
          }
        end
      end
    end
  end
end
