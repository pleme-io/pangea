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
    module SpotInstanceCarbonOptimizer
      # CloudWatch monitoring resource creation methods
      module Monitoring
        def create_efficiency_metrics(input)
          [
            aws_cloudwatch_metric_alarm(:"#{input.name}-carbon-intensity-metric", {
              alarm_name: "#{input.name}-average-carbon-intensity",
              comparison_operator: "GreaterThanThreshold",
              evaluation_periods: 2,
              metric_name: "AverageCarbonIntensity",
              namespace: "SpotCarbonOptimizer/#{input.name}",
              period: 300,
              statistic: "Average",
              threshold: input.carbon_intensity_threshold.to_f,
              treat_missing_data: "notBreaching"
            }),
            aws_cloudwatch_metric_alarm(:"#{input.name}-renewable-percentage-metric", {
              alarm_name: "#{input.name}-renewable-percentage",
              comparison_operator: "LessThanThreshold",
              evaluation_periods: 2,
              metric_name: "RenewablePercentage",
              namespace: "SpotCarbonOptimizer/#{input.name}",
              period: 300,
              statistic: "Average",
              threshold: input.renewable_percentage_minimum.to_f,
              treat_missing_data: "notBreaching"
            }),
            aws_cloudwatch_metric_alarm(:"#{input.name}-migration-frequency-metric", {
              alarm_name: "#{input.name}-migration-frequency",
              comparison_operator: "GreaterThanThreshold",
              evaluation_periods: 1,
              metric_name: "MigrationCount",
              namespace: "SpotCarbonOptimizer/#{input.name}",
              period: 3600,
              statistic: "Sum",
              threshold: 10.0,
              treat_missing_data: "notBreaching"
            })
          ]
        end

        def create_carbon_dashboard(input, spot_fleets, metrics)
          aws_cloudwatch_dashboard(:"#{input.name}-carbon-dashboard", {
            dashboard_name: "#{input.name}-spot-carbon-dashboard",
            dashboard_body: JSON.pretty_generate(build_dashboard_body(input))
          })
        end

        def create_carbon_alarms(input, metrics)
          alarms = metrics.dup

          if input.alert_on_high_carbon
            alarms << aws_cloudwatch_alarm(:"#{input.name}-high-carbon-alarm", {
              alarm_name: "#{input.name}-high-carbon-usage",
              comparison_operator: "GreaterThanThreshold",
              evaluation_periods: 3,
              metric_name: "HighCarbonInstancePercentage",
              namespace: "SpotCarbonOptimizer/#{input.name}",
              period: 900,
              statistic: "Average",
              threshold: 25.0,
              alarm_description: "Alert when >25% instances in high-carbon regions",
              treat_missing_data: "notBreaching",
              tags: input.tags
            })
          end

          alarms
        end

        private

        def build_dashboard_body(input)
          {
            widgets: [
              build_carbon_intensity_widget(input),
              build_fleet_capacity_widget(input),
              build_carbon_impact_widget(input),
              build_migration_activity_widget(input)
            ]
          }
        end

        def build_carbon_intensity_widget(input)
          {
            type: "metric",
            properties: {
              metrics: input.allowed_regions.map { |region|
                ["SpotCarbonOptimizer/#{input.name}", "RegionalCarbonIntensity",
                 { "Region": region }]
              },
              period: 300,
              stat: "Average",
              region: "us-east-1",
              title: "Regional Carbon Intensity",
              yAxis: {
                left: { min: 0, label: "gCO2/kWh" }
              }
            }
          }
        end

        def build_fleet_capacity_widget(input)
          {
            type: "metric",
            properties: {
              metrics: [
                ["SpotCarbonOptimizer/#{input.name}", "TotalFleetCapacity", { stat: "Average" }],
                [".", "ActiveInstances", { stat: "Sum" }],
                [".", "SpotSavings", { stat: "Sum", yAxis: "right" }]
              ],
              period: 300,
              stat: "Average",
              region: "us-east-1",
              title: "Fleet Capacity and Savings",
              yAxis: {
                left: { label: "Instances" },
                right: { label: "Savings ($)" }
              }
            }
          }
        end

        def build_carbon_impact_widget(input)
          {
            type: "metric",
            properties: {
              metrics: [
                ["SpotCarbonOptimizer/#{input.name}", "CarbonEmissionsAvoided", { stat: "Sum" }],
                [".", "RenewableEnergyUsage", { stat: "Average", yAxis: "right" }]
              ],
              period: 3600,
              stat: "Sum",
              region: "us-east-1",
              title: "Carbon Impact",
              yAxis: {
                left: { label: "gCO2 Avoided" },
                right: { label: "Renewable %" }
              }
            }
          }
        end

        def build_migration_activity_widget(input)
          {
            type: "metric",
            properties: {
              metrics: [
                ["SpotCarbonOptimizer/#{input.name}", "MigrationCount", { stat: "Sum" }],
                [".", "MigrationDuration", { stat: "Average" }],
                [".", "MigrationSuccess", { stat: "Average", yAxis: "right" }]
              ],
              period: 3600,
              stat: "Sum",
              region: "us-east-1",
              title: "Migration Activity"
            }
          }
        end
      end
    end
  end
end
