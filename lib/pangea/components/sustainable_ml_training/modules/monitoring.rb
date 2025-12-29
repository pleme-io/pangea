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
    module SustainableMLTraining
      # Monitoring resources: metrics, dashboard, alarms
      module Monitoring
        def create_training_metrics(input)
          metrics = []
          metrics << create_gpu_utilization_alarm(input)
          metrics << create_carbon_emissions_alarm(input) if input.track_carbon_emissions
          metrics << create_model_size_alarm(input)
          metrics
        end

        def create_carbon_dashboard(input, _metrics)
          aws_cloudwatch_dashboard(:"#{input.name}-carbon-dashboard", {
            dashboard_name: "#{input.name}-sustainable-ml-dashboard",
            dashboard_body: JSON.pretty_generate(build_dashboard_body(input))
          })
        end

        def create_efficiency_alarms(input, metrics)
          alarms = metrics.dup
          alarms << create_training_efficiency_alarm(input)
          alarms << create_carbon_threshold_alarm(input) if input.track_carbon_emissions
          alarms
        end

        private

        def create_gpu_utilization_alarm(input)
          aws_cloudwatch_metric_alarm(:"#{input.name}-gpu-utilization", {
            alarm_name: "#{input.name}-gpu-utilization",
            comparison_operator: "LessThanThreshold",
            evaluation_periods: 2,
            metric_name: "GPUUtilization",
            namespace: "AWS/SageMaker",
            period: 300,
            statistic: "Average",
            threshold: 70.0,
            alarm_description: "Alert when GPU utilization is low",
            treat_missing_data: "notBreaching"
          })
        end

        def create_carbon_emissions_alarm(input)
          aws_cloudwatch_metric_alarm(:"#{input.name}-carbon-emissions", {
            alarm_name: "#{input.name}-training-carbon",
            comparison_operator: "GreaterThanThreshold",
            evaluation_periods: 1,
            metric_name: "CarbonEmissions",
            namespace: "SustainableML/#{input.name}",
            period: 3600,
            statistic: "Sum",
            threshold: 100.0,
            alarm_description: "Alert on high carbon emissions",
            treat_missing_data: "notBreaching"
          })
        end

        def create_model_size_alarm(input)
          aws_cloudwatch_metric_alarm(:"#{input.name}-model-size", {
            alarm_name: "#{input.name}-model-size",
            comparison_operator: "GreaterThanThreshold",
            evaluation_periods: 1,
            metric_name: "ModelSize",
            namespace: "SustainableML/#{input.name}",
            period: 3600,
            statistic: "Maximum",
            threshold: 1000.0, # MB
            alarm_description: "Alert when model size is large",
            treat_missing_data: "notBreaching"
          })
        end

        def create_training_efficiency_alarm(input)
          aws_cloudwatch_alarm(:"#{input.name}-training-efficiency", {
            alarm_name: "#{input.name}-low-training-efficiency",
            comparison_operator: "LessThanThreshold",
            evaluation_periods: 3,
            metric_name: "TrainingEfficiency",
            namespace: "SustainableML/#{input.name}",
            period: 1800,
            statistic: "Average",
            threshold: 0.7,
            alarm_description: "Alert when training efficiency is low",
            treat_missing_data: "notBreaching",
            tags: input.tags
          })
        end

        def create_carbon_threshold_alarm(input)
          aws_cloudwatch_alarm(:"#{input.name}-carbon-threshold", {
            alarm_name: "#{input.name}-carbon-threshold-exceeded",
            comparison_operator: "GreaterThanThreshold",
            evaluation_periods: 2,
            metric_name: "CarbonIntensity",
            namespace: "SustainableML/#{input.name}",
            period: 900,
            statistic: "Average",
            threshold: input.carbon_intensity_threshold.to_f,
            alarm_description: "Alert when carbon intensity exceeds threshold",
            treat_missing_data: "notBreaching",
            tags: input.tags
          })
        end

        def build_dashboard_body(input)
          {
            widgets: [
              carbon_metrics_widget(input),
              resource_utilization_widget,
              training_progress_widget(input),
              sustainability_impact_widget(input)
            ]
          }
        end

        def carbon_metrics_widget(input)
          {
            type: "metric",
            properties: {
              metrics: [
                ["SustainableML/#{input.name}", "CarbonIntensity", { stat: "Average" }],
                [".", "RenewablePercentage", { stat: "Average", yAxis: "right" }]
              ],
              period: 300, stat: "Average", region: "us-east-1",
              title: "Training Carbon Metrics",
              yAxis: { left: { label: "gCO2/kWh" }, right: { label: "Renewable %" } }
            }
          }
        end

        def resource_utilization_widget
          {
            type: "metric",
            properties: {
              metrics: [
                ["AWS/SageMaker", "GPUUtilization", { stat: "Average" }],
                [".", "GPUMemoryUtilization", { stat: "Average" }],
                [".", "CPUUtilization", { stat: "Average" }]
              ],
              period: 300, stat: "Average", region: "us-east-1",
              title: "Resource Utilization"
            }
          }
        end

        def training_progress_widget(input)
          {
            type: "metric",
            properties: {
              metrics: [
                ["SustainableML/#{input.name}", "TrainingProgress", { stat: "Maximum" }],
                [".", "ValidationAccuracy", { stat: "Maximum" }],
                [".", "TrainingLoss", { stat: "Minimum", yAxis: "right" }]
              ],
              period: 600, stat: "Average", region: "us-east-1",
              title: "Training Progress"
            }
          }
        end

        def sustainability_impact_widget(input)
          {
            type: "metric",
            properties: {
              metrics: [
                ["SustainableML/#{input.name}", "EnergyConsumption", { stat: "Sum" }],
                [".", "CarbonEmissions", { stat: "Sum" }],
                [".", "CostSavings", { stat: "Sum", yAxis: "right" }]
              ],
              period: 3600, stat: "Sum", region: "us-east-1",
              title: "Sustainability Impact"
            }
          }
        end
      end
    end
  end
end
