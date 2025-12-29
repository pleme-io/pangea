# frozen_string_literal: true

module Pangea
  module Components
    module EventDrivenMicroservice
      # Helper methods for cost estimation and outputs
      module Helpers
        def estimate_event_driven_cost(attrs)
          cost = 0.0
          cost += lambda_cost_estimate(attrs)
          cost += dynamodb_cost_estimate(attrs)
          cost += eventbridge_cost_estimate(attrs)
          cost += sqs_cost_estimate(attrs)
          cost += monitoring_cost_estimate(attrs)
          cost.round(2)
        end

        def build_outputs(component_attrs, resources, event_source_mappings)
          {
            service_name: component_attrs.service_name,
            command_handler_arn: resources[:command_handler].arn,
            query_handler_arn: resources[:query_handler]&.arn,
            event_processor_arn: resources[:event_processor]&.arn,
            event_store_name: resources[:event_store].name,
            event_store_stream_arn: resources[:event_store].stream_arn,
            event_sources: format_event_sources(component_attrs, event_source_mappings),
            patterns_enabled: enabled_patterns(component_attrs),
            monitoring_features: enabled_monitoring_features(component_attrs),
            estimated_monthly_cost: estimate_event_driven_cost(component_attrs)
          }
        end

        private

        def lambda_cost_estimate(attrs)
          requests_per_month = 1_000_000
          request_cost = (requests_per_month / 1_000_000) * 0.20
          compute_cost = (requests_per_month * 0.5 * attrs.command_handler.memory_size / 1024) * 0.0000166667
          request_cost + compute_cost
        end

        def dynamodb_cost_estimate(attrs)
          base = 25.0
          base += 20.0 if attrs.cqrs&.enabled
          base
        end

        def eventbridge_cost_estimate(attrs)
          eventbridge_sources = attrs.event_sources.count { |s| s.type == 'EventBridge' }
          eventbridge_sources * 1.0
        end

        def sqs_cost_estimate(attrs)
          attrs.dead_letter_queue_enabled ? 0.50 : 0.0
        end

        def monitoring_cost_estimate(attrs)
          cost = 5.0 # Logs and metrics
          cost += 3.0 if attrs.monitoring.dashboard_enabled
          cost
        end

        def format_event_sources(component_attrs, event_source_mappings)
          component_attrs.event_sources.map.with_index do |source, index|
            { type: source.type, mapping: event_source_mappings.values[index] }
          end
        end

        def enabled_patterns(attrs)
          [
            'Event Sourcing',
            ('CQRS' if attrs.cqrs&.enabled),
            ('Saga Orchestration' if attrs.saga&.enabled),
            ('Event Replay' if attrs.event_replay.enabled),
            ('Dead Letter Queue' if attrs.dead_letter_queue_enabled)
          ].compact
        end

        def enabled_monitoring_features(attrs)
          [
            ('CloudWatch Dashboard' if attrs.monitoring.dashboard_enabled),
            'CloudWatch Alarms',
            ('Email Notifications' if attrs.monitoring.alarm_email),
            'X-Ray Tracing'
          ].compact
        end
      end
    end
  end
end
