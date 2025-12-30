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

module Pangea
  module Components
    module ApplicationLoadBalancer
      # Creates CloudWatch monitoring alarms for ALB
      module Monitoring
        extend self

        def create_alarms(name, alb_ref, component_tag_set, context)
          {
            response_time: create_response_time_alarm(name, alb_ref, component_tag_set, context),
            unhealthy_hosts: create_unhealthy_hosts_alarm(name, alb_ref, component_tag_set, context),
            error_rate: create_error_rate_alarm(name, alb_ref, component_tag_set, context)
          }
        end

        private

        def create_response_time_alarm(name, alb_ref, component_tag_set, context)
          context.aws_cloudwatch_metric_alarm(
            context.component_resource_name(name, :alarm, :response_time),
            {
              alarm_name: "#{name}-alb-high-response-time",
              comparison_operator: 'GreaterThanThreshold',
              evaluation_periods: '2',
              metric_name: 'TargetResponseTime',
              namespace: 'AWS/ApplicationELB',
              period: '300',
              statistic: 'Average',
              threshold: '1.0',
              alarm_description: 'ALB target response time is high',
              dimensions: { LoadBalancer: alb_ref.arn_suffix },
              tags: component_tag_set
            }
          )
        end

        def create_unhealthy_hosts_alarm(name, alb_ref, component_tag_set, context)
          context.aws_cloudwatch_metric_alarm(
            context.component_resource_name(name, :alarm, :unhealthy_hosts),
            {
              alarm_name: "#{name}-alb-unhealthy-hosts",
              comparison_operator: 'GreaterThanThreshold',
              evaluation_periods: '2',
              metric_name: 'UnHealthyHostCount',
              namespace: 'AWS/ApplicationELB',
              period: '300',
              statistic: 'Average',
              threshold: '0',
              alarm_description: 'ALB has unhealthy targets',
              dimensions: { LoadBalancer: alb_ref.arn_suffix },
              tags: component_tag_set
            }
          )
        end

        def create_error_rate_alarm(name, alb_ref, component_tag_set, context)
          context.aws_cloudwatch_metric_alarm(
            context.component_resource_name(name, :alarm, :error_rate),
            {
              alarm_name: "#{name}-alb-high-error-rate",
              comparison_operator: 'GreaterThanThreshold',
              evaluation_periods: '3',
              metric_name: 'HTTPCode_ELB_5XX_Count',
              namespace: 'AWS/ApplicationELB',
              period: '300',
              statistic: 'Sum',
              threshold: '10',
              alarm_description: 'ALB 5xx error rate is high',
              dimensions: { LoadBalancer: alb_ref.arn_suffix },
              tags: component_tag_set
            }
          )
        end
      end
    end
  end
end
