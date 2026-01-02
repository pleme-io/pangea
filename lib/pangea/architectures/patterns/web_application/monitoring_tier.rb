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

require 'json'

module Pangea
  module Architectures
    module Patterns
      module WebApplication
        # Monitoring tier creation for web application
        module MonitoringTier
          private

          def create_monitoring_tier(name, arch_ref, arch_attrs, base_tags)
            monitoring_resources = {}

            monitoring_resources[:log_group] = create_log_group(name, arch_attrs, base_tags)
            monitoring_resources[:dashboard] = create_dashboard(name, arch_ref)

            monitoring_resources
          end

          def create_log_group(name, arch_attrs, base_tags)
            aws_cloudwatch_log_group(
              architecture_resource_name(name, :log_group),
              name: "/aws/application/#{name}",
              retention_in_days: arch_attrs.log_retention_days,
              tags: base_tags.merge(Tier: 'monitoring', Component: 'logs')
            )
          end

          def create_dashboard(name, arch_ref)
            aws_cloudwatch_dashboard(
              architecture_resource_name(name, :dashboard),
              dashboard_name: "#{name.to_s.gsub('_', '-')}-Dashboard",
              dashboard_body: generate_dashboard_body(arch_ref)
            )
          end

          def generate_dashboard_body(arch_ref)
            JSON.generate({
                            widgets: [
                              alb_metrics_widget(arch_ref),
                              asg_metrics_widget(arch_ref)
                            ]
                          })
          end

          def alb_metrics_widget(arch_ref)
            {
              type: 'metric',
              properties: {
                metrics: [
                  ['AWS/ApplicationELB', 'RequestCount', 'LoadBalancer',
                   arch_ref.compute[:load_balancer][:load_balancer].arn],
                  ['AWS/ApplicationELB', 'TargetResponseTime', 'LoadBalancer',
                   arch_ref.compute[:load_balancer][:load_balancer].arn]
                ],
                period: 300, stat: 'Average', region: 'us-east-1',
                title: 'Application Load Balancer Metrics'
              }
            }
          end

          def asg_metrics_widget(arch_ref)
            {
              type: 'metric',
              properties: {
                metrics: [
                  ['AWS/AutoScaling', 'GroupDesiredCapacity', 'AutoScalingGroupName',
                   arch_ref.compute[:auto_scaling_group].name],
                  ['AWS/AutoScaling', 'GroupInServiceInstances', 'AutoScalingGroupName',
                   arch_ref.compute[:auto_scaling_group].name]
                ],
                period: 300, stat: 'Average', region: 'us-east-1',
                title: 'Auto Scaling Group Metrics'
              }
            }
          end
        end
      end
    end
  end
end
