# frozen_string_literal: true

require 'json'

module Pangea
  module Components
    module EventDrivenMicroservice
      # Event source mappings for EventBridge, SQS, Kinesis
      module EventSources
        def create_event_source_mappings(name, component_attrs, handler_refs, component_tag_set)
          mappings = {}

          component_attrs.event_sources.each_with_index do |source, index|
            case source.type
            when 'EventBridge'
              mappings["eventbridge#{index}".to_sym] = create_eventbridge_mapping(
                name, source, index, handler_refs[:command_handler], component_tag_set
              )
            when 'SQS'
              mappings["sqs#{index}".to_sym] = create_sqs_mapping(
                name, source, index, handler_refs[:command_handler]
              )
            when 'Kinesis', 'DynamoDB'
              target = handler_refs[:event_processor] || handler_refs[:command_handler]
              mappings["stream#{index}".to_sym] = create_stream_mapping(name, source, index, target)
            end
          end

          mappings
        end

        private

        def create_eventbridge_mapping(name, source, index, command_handler_ref, tags)
          rule_ref = aws_eventbridge_rule(
            component_resource_name(name, :event_rule, "source#{index}".to_sym),
            {
              name: "#{name}-event-rule-#{index}",
              description: "Event rule for event-driven microservice",
              event_pattern: JSON.generate(source.event_pattern),
              state: 'ENABLED',
              tags: tags
            }
          )

          permission_ref = aws_lambda_permission(
            component_resource_name(name, :event_permission, "source#{index}".to_sym),
            {
              statement_id: "AllowEventBridge#{index}",
              action: 'lambda:InvokeFunction',
              function_name: command_handler_ref.function_name,
              principal: 'events.amazonaws.com',
              source_arn: rule_ref.arn
            }
          )

          target_ref = aws_eventbridge_target(
            component_resource_name(name, :event_target, "source#{index}".to_sym),
            eventbridge_target_config(rule_ref, command_handler_ref, source, index)
          )

          { rule: rule_ref, permission: permission_ref, target: target_ref }
        end

        def eventbridge_target_config(rule_ref, handler_ref, source, index)
          {
            rule: rule_ref.name,
            target_id: "Lambda#{index}",
            arn: handler_ref.arn,
            retry_policy: {
              maximum_retry_attempts: source.maximum_retry_attempts,
              maximum_event_age_in_seconds: 3600
            },
            dead_letter_config: source.on_failure_destination_arn ? {
              arn: source.on_failure_destination_arn
            } : nil
          }.compact
        end

        def create_sqs_mapping(name, source, index, command_handler_ref)
          aws_lambda_event_source_mapping(
            component_resource_name(name, :sqs_mapping, "source#{index}".to_sym),
            {
              event_source_arn: source.source_arn || source.source_ref.arn,
              function_name: command_handler_ref.function_name,
              batch_size: source.batch_size,
              maximum_batching_window_in_seconds: source.maximum_batching_window,
              function_response_types: ['ReportBatchItemFailures']
            }
          )
        end

        def create_stream_mapping(name, source, index, target_handler_ref)
          aws_lambda_event_source_mapping(
            component_resource_name(name, :stream_mapping, "source#{index}".to_sym),
            {
              event_source_arn: source.source_arn || source.source_ref.arn,
              function_name: target_handler_ref.function_name,
              batch_size: source.batch_size,
              maximum_batching_window_in_seconds: source.maximum_batching_window,
              starting_position: source.starting_position,
              parallelization_factor: source.parallelization_factor,
              maximum_retry_attempts: source.maximum_retry_attempts,
              on_failure: source.on_failure_destination_arn ? {
                destination_arn: source.on_failure_destination_arn
              } : nil
            }.compact
          )
        end
      end
    end
  end
end
