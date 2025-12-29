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

require "json"

module Pangea
  module Components
    module CarbonAwareCompute
      # CloudWatch monitoring resources for Carbon Aware Compute
      module Monitoring
        def create_carbon_metric(input)
          aws_cloudwatch_metric_alarm(:"#{input.name}-carbon-metric", {
            alarm_name: "#{input.name}-carbon-emissions",
            comparison_operator: "GreaterThanThreshold",
            evaluation_periods: 1,
            metric_name: "CarbonEmissions",
            namespace: metric_namespace(input),
            period: 300,
            statistic: "Average",
            threshold: input.carbon_intensity_threshold.to_f,
            alarm_description: "Carbon emissions metric for #{input.name}",
            treat_missing_data: "notBreaching"
          })
        end

        def create_efficiency_metric(input)
          aws_cloudwatch_metric_alarm(:"#{input.name}-efficiency-metric", {
            alarm_name: "#{input.name}-compute-efficiency",
            comparison_operator: "LessThanThreshold",
            evaluation_periods: 2,
            metric_name: "ComputeEfficiency",
            namespace: metric_namespace(input),
            period: 300,
            statistic: "Average",
            threshold: 80.0,
            alarm_description: "Compute efficiency metric for #{input.name}",
            treat_missing_data: "notBreaching"
          })
        end

        def create_monitoring_dashboard(input, _carbon_metric, _efficiency_metric)
          aws_cloudwatch_dashboard(:"#{input.name}-dashboard", {
            dashboard_name: "#{input.name}-carbon-aware-dashboard",
            dashboard_body: JSON.pretty_generate(dashboard_widgets(input))
          })
        end

        def create_high_carbon_alarm(input, _metric)
          aws_cloudwatch_alarm(:"#{input.name}-high-carbon-alarm", {
            alarm_name: "#{input.name}-high-carbon-intensity",
            comparison_operator: "GreaterThanThreshold",
            evaluation_periods: 2,
            metric_name: "CarbonIntensity",
            namespace: metric_namespace(input),
            period: 900,
            statistic: "Average",
            threshold: input.carbon_intensity_threshold.to_f,
            alarm_description: "Alert when carbon intensity exceeds threshold",
            alarm_actions: [],
            treat_missing_data: "notBreaching",
            tags: input.tags
          })
        end

        def create_efficiency_alarm(input, _metric)
          aws_cloudwatch_alarm(:"#{input.name}-low-efficiency-alarm", {
            alarm_name: "#{input.name}-low-compute-efficiency",
            comparison_operator: "LessThanThreshold",
            evaluation_periods: 3,
            metric_name: "ComputeEfficiency",
            namespace: metric_namespace(input),
            period: 1800,
            statistic: "Average",
            threshold: 70.0,
            alarm_description: "Alert when compute efficiency is low",
            alarm_actions: [],
            treat_missing_data: "notBreaching",
            tags: input.tags
          })
        end

        private

        def metric_namespace(input)
          "CarbonAwareCompute/#{input.name}"
        end

        def dashboard_widgets(input)
          {
            widgets: [
              carbon_emissions_widget(input),
              workload_execution_widget(input),
              regional_carbon_widget(input),
              efficiency_widget(input)
            ]
          }
        end

        def carbon_emissions_widget(input)
          {
            type: "metric",
            properties: {
              metrics: [
                [metric_namespace(input), "CarbonEmissions", { stat: "Average" }],
                [".", "CarbonIntensity", { stat: "Average", yAxis: "right" }]
              ],
              period: 300,
              stat: "Average",
              region: "us-east-1",
              title: "Carbon Emissions & Intensity",
              yAxis: { left: { label: "gCO2eq" }, right: { label: "gCO2/kWh" } }
            }
          }
        end

        def workload_execution_widget(input)
          {
            type: "metric",
            properties: {
              metrics: [
                [metric_namespace(input), "WorkloadsScheduled", { stat: "Sum" }],
                [".", "WorkloadsShifted", { stat: "Sum" }],
                [".", "WorkloadsExecuted", { stat: "Sum" }]
              ],
              period: 3600,
              stat: "Sum",
              region: "us-east-1",
              title: "Workload Execution Metrics"
            }
          }
        end

        def regional_carbon_widget(input)
          {
            type: "metric",
            properties: {
              metrics: input.preferred_regions.map do |region|
                [metric_namespace(input), "RegionCarbonIntensity", { "RegionName": region }]
              end,
              period: 900,
              stat: "Average",
              region: "us-east-1",
              title: "Regional Carbon Intensity"
            }
          }
        end

        def efficiency_widget(input)
          {
            type: "metric",
            properties: {
              metrics: [
                [metric_namespace(input), "ComputeEfficiency", { stat: "Average" }],
                [".", "CostSavings", { stat: "Sum", yAxis: "right" }]
              ],
              period: 3600,
              stat: "Average",
              region: "us-east-1",
              title: "Efficiency & Cost Optimization"
            }
          }
        end
      end
    end
  end
end
