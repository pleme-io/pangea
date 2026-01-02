# frozen_string_literal: true

require 'json'

module Pangea
  module Components
    module EventDrivenMicroservice
      # CloudWatch dashboard, alarms, and SNS notifications
      module Monitoring
        def create_monitoring_resources(name, component_attrs, resources, component_tag_set)
          monitoring = {}

          if component_attrs.monitoring.dashboard_enabled
            monitoring[:dashboard] = create_dashboard(name, component_tag_set)
          end

          monitoring[:alarms] = create_alarms(name, component_attrs, resources, component_tag_set)

          if component_attrs.monitoring.alarm_email
            monitoring.merge!(create_alarm_notifications(name, component_attrs, monitoring[:alarms], component_tag_set))
          end

          monitoring
        end

        private

        def create_dashboard(name, _tags)
          aws_cloudwatch_dashboard(
            component_resource_name(name, :dashboard),
            {
              dashboard_name: "#{name}-event-driven-dashboard",
              dashboard_body: JSON.generate(dashboard_widgets)
            }
          )
        end

        def dashboard_widgets
          {
            widgets: [
              lambda_metrics_widget,
              dynamodb_metrics_widget
            ]
          }
        end

        def lambda_metrics_widget
          {
            type: 'metric',
            properties: {
              metrics: [
                ['AWS/Lambda', 'Invocations', { stat: 'Sum' }],
                ['.', 'Errors', { stat: 'Sum' }],
                ['.', 'Duration', { stat: 'Average' }],
                ['.', 'ConcurrentExecutions', { stat: 'Maximum' }]
              ],
              period: 300,
              stat: 'Average',
              region: '${AWS::Region}',
              title: 'Lambda Metrics'
            }
          }
        end

        def dynamodb_metrics_widget
          {
            type: 'metric',
            properties: {
              metrics: [
                ['AWS/DynamoDB', 'UserErrors', { stat: 'Sum' }],
                ['.', 'SystemErrors', { stat: 'Sum' }],
                ['.', 'ConsumedReadCapacityUnits', { stat: 'Sum' }],
                ['.', 'ConsumedWriteCapacityUnits', { stat: 'Sum' }]
              ],
              period: 300,
              stat: 'Sum',
              region: '${AWS::Region}',
              title: 'DynamoDB Metrics'
            }
          }
        end

        def create_alarms(name, component_attrs, resources, tags)
          alarms = {}
          alarms[:error_rate] = create_error_alarm(name, component_attrs, resources, tags)
          alarms[:latency] = create_latency_alarm(name, component_attrs, resources, tags)

          if component_attrs.dead_letter_queue_enabled && resources[:dead_letter_queue]
            alarms[:dlq] = create_dlq_alarm(name, component_attrs, resources[:dead_letter_queue], tags)
          end

          alarms
        end

        def create_error_alarm(name, component_attrs, resources, tags)
          aws_cloudwatch_metric_alarm(
            component_resource_name(name, :error_alarm),
            {
              alarm_name: "#{name}-lambda-error-rate",
              comparison_operator: 'GreaterThanThreshold',
              evaluation_periods: '2',
              metric_name: 'Errors',
              namespace: 'AWS/Lambda',
              period: '300',
              statistic: 'Average',
              threshold: (component_attrs.monitoring.error_rate_threshold * 100).to_s,
              alarm_description: 'Lambda error rate is too high',
              dimensions: { FunctionName: resources[:command_handler].function_name },
              tags: tags
            }
          )
        end

        def create_latency_alarm(name, component_attrs, resources, tags)
          aws_cloudwatch_metric_alarm(
            component_resource_name(name, :latency_alarm),
            {
              alarm_name: "#{name}-event-processing-latency",
              comparison_operator: 'GreaterThanThreshold',
              evaluation_periods: '3',
              metric_name: 'Duration',
              namespace: 'AWS/Lambda',
              period: '300',
              statistic: 'Average',
              threshold: component_attrs.monitoring.event_processing_threshold.to_s,
              alarm_description: 'Event processing is taking too long',
              dimensions: { FunctionName: resources[:command_handler].function_name },
              tags: tags
            }
          )
        end

        def create_dlq_alarm(name, component_attrs, dlq_ref, tags)
          aws_cloudwatch_metric_alarm(
            component_resource_name(name, :dlq_alarm),
            {
              alarm_name: "#{name}-dlq-messages",
              comparison_operator: 'GreaterThanThreshold',
              evaluation_periods: '1',
              metric_name: 'ApproximateNumberOfMessagesVisible',
              namespace: 'AWS/SQS',
              period: '300',
              statistic: 'Maximum',
              threshold: component_attrs.monitoring.dead_letter_threshold.to_s,
              alarm_description: 'Dead letter queue has too many messages',
              dimensions: { QueueName: dlq_ref.name },
              tags: tags
            }
          )
        end

        def create_alarm_notifications(name, component_attrs, alarms, tags)
          topic_ref = aws_sns_topic(
            component_resource_name(name, :alarm_topic),
            {
              name: "#{name}-alarms",
              display_name: "#{component_attrs.service_name} Alarms",
              tags: tags
            }
          )

          subscription_ref = aws_sns_topic_subscription(
            component_resource_name(name, :alarm_subscription),
            {
              topic_arn: topic_ref.arn,
              protocol: 'email',
              endpoint: component_attrs.monitoring.alarm_email
            }
          )

          update_alarms_with_actions(name, alarms, topic_ref)

          { alarm_topic: topic_ref, alarm_subscription: subscription_ref }
        end

        def update_alarms_with_actions(name, alarms, topic_ref)
          alarms.each do |alarm_name, alarm_ref|
            aws_cloudwatch_metric_alarm(
              component_resource_name(name, :alarm_action, alarm_name),
              {
                alarm_name: alarm_ref.alarm_name,
                alarm_actions: [topic_ref.arn],
                insufficient_data_actions: [topic_ref.arn]
              }
            )
          end
        end
      end
    end
  end
end
