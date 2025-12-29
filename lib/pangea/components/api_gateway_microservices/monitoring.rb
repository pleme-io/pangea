# frozen_string_literal: true

module Pangea
  module Components
    module ApiGatewayMicroservices
      # CloudWatch alarms for API Gateway
      module Monitoring
        def create_api_alarms(name, api_ref, stage_ref, component_tag_set)
          {
            errors_4xx: create_4xx_alarm(name, api_ref, stage_ref, component_tag_set),
            errors_5xx: create_5xx_alarm(name, api_ref, stage_ref, component_tag_set),
            latency: create_latency_alarm(name, api_ref, stage_ref, component_tag_set)
          }
        end

        private

        def create_4xx_alarm(name, api_ref, stage_ref, tags)
          aws_cloudwatch_metric_alarm(
            component_resource_name(name, :alarm_4xx),
            {
              alarm_name: "#{name}-api-4xx-errors",
              comparison_operator: 'GreaterThanThreshold',
              evaluation_periods: '2',
              metric_name: '4XXError',
              namespace: 'AWS/ApiGateway',
              period: '300',
              statistic: 'Sum',
              threshold: '100',
              alarm_description: 'API Gateway 4XX errors are high',
              dimensions: { ApiName: api_ref.name, Stage: stage_ref.stage_name },
              tags: tags
            }
          )
        end

        def create_5xx_alarm(name, api_ref, stage_ref, tags)
          aws_cloudwatch_metric_alarm(
            component_resource_name(name, :alarm_5xx),
            {
              alarm_name: "#{name}-api-5xx-errors",
              comparison_operator: 'GreaterThanThreshold',
              evaluation_periods: '1',
              metric_name: '5XXError',
              namespace: 'AWS/ApiGateway',
              period: '60',
              statistic: 'Sum',
              threshold: '10',
              alarm_description: 'API Gateway 5XX errors detected',
              dimensions: { ApiName: api_ref.name, Stage: stage_ref.stage_name },
              tags: tags
            }
          )
        end

        def create_latency_alarm(name, api_ref, stage_ref, tags)
          aws_cloudwatch_metric_alarm(
            component_resource_name(name, :alarm_latency),
            {
              alarm_name: "#{name}-api-high-latency",
              comparison_operator: 'GreaterThanThreshold',
              evaluation_periods: '2',
              metric_name: 'Latency',
              namespace: 'AWS/ApiGateway',
              period: '300',
              statistic: 'Average',
              threshold: '1000',
              alarm_description: 'API Gateway latency is high',
              dimensions: { ApiName: api_ref.name, Stage: stage_ref.stage_name },
              tags: tags
            }
          )
        end
      end
    end
  end
end
