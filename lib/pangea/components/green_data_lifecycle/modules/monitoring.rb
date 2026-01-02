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
    module GreenDataLifecycle
      # Monitoring resources for Green Data Lifecycle component
      module Monitoring
        STORAGE_CLASSES = %w[
          STANDARD STANDARD_IA GLACIER_IR GLACIER_FLEXIBLE DEEP_ARCHIVE
        ].freeze

        private

        def create_storage_metrics(input, bucket)
          STORAGE_CLASSES.map do |storage_class|
            create_storage_class_metric(input, bucket, storage_class)
          end
        end

        def create_storage_class_metric(input, bucket, storage_class)
          resource_name = storage_class.downcase.gsub('_', '-')
          aws_cloudwatch_metric_alarm(:"#{input.name}-#{resource_name}-metric", {
            alarm_name: "#{input.name}-#{storage_class}-storage",
            comparison_operator: "GreaterThanThreshold",
            evaluation_periods: 1,
            metric_name: "BucketSizeBytes",
            namespace: "AWS/S3",
            period: 86_400,
            statistic: "Average",
            threshold: 0,
            dimensions: [
              { name: "BucketName", value: bucket.bucket },
              { name: "StorageType", value: storage_class }
            ],
            treat_missing_data: "notBreaching"
          })
        end

        def create_carbon_dashboard(input, bucket, _metrics)
          aws_cloudwatch_dashboard(:"#{input.name}-carbon-dashboard", {
            dashboard_name: "#{input.name}-green-storage-dashboard",
            dashboard_body: JSON.pretty_generate(dashboard_widgets(input, bucket))
          })
        end

        def dashboard_widgets(input, bucket)
          {
            widgets: [
              carbon_footprint_widget(input),
              storage_distribution_widget(bucket),
              lifecycle_activity_widget(input),
              efficiency_metrics_widget(input)
            ]
          }
        end

        def carbon_footprint_widget(input)
          {
            type: "metric",
            properties: {
              metrics: [
                ["GreenDataLifecycle/#{input.name}", "TotalCarbonFootprint", { stat: "Average" }],
                [".", "CarbonPerGB", { stat: "Average", yAxis: "right" }]
              ],
              period: 86_400,
              stat: "Average",
              region: "us-east-1",
              title: "Storage Carbon Footprint",
              yAxis: { left: { label: "Total gCO2" }, right: { label: "gCO2/GB" } }
            }
          }
        end

        def storage_distribution_widget(bucket)
          {
            type: "metric",
            properties: {
              metrics: Types::STORAGE_CARBON_INTENSITY.keys.map { |storage_class|
                ["AWS/S3", "BucketSizeBytes",
                 { "BucketName": bucket.bucket, "StorageType": storage_class }]
              },
              period: 86_400,
              stat: "Average",
              region: "us-east-1",
              title: "Storage Distribution by Class",
              stacked: true
            }
          }
        end

        def lifecycle_activity_widget(input)
          {
            type: "metric",
            properties: {
              metrics: [
                ["GreenDataLifecycle/#{input.name}", "ObjectsTransitioned", { stat: "Sum" }],
                [".", "ObjectsArchived", { stat: "Sum" }],
                [".", "ObjectsDeleted", { stat: "Sum" }]
              ],
              period: 86_400,
              stat: "Sum",
              region: "us-east-1",
              title: "Lifecycle Activity"
            }
          }
        end

        def efficiency_metrics_widget(input)
          {
            type: "metric",
            properties: {
              metrics: [
                ["GreenDataLifecycle/#{input.name}", "AccessPatternScore", { stat: "Average" }],
                [".", "StorageEfficiency", { stat: "Average" }],
                [".", "CarbonEfficiency", { stat: "Average" }]
              ],
              period: 86_400,
              stat: "Average",
              region: "us-east-1",
              title: "Efficiency Metrics",
              yAxis: { left: { min: 0, max: 100 } }
            }
          }
        end

        def create_efficiency_alarms(input, _metrics)
          alarms = []
          alarms << create_high_carbon_alarm(input) if input.alert_on_high_storage_carbon
          alarms << create_inefficient_storage_alarm(input)
          alarms
        end

        def create_high_carbon_alarm(input)
          aws_cloudwatch_alarm(:"#{input.name}-high-carbon-alarm", {
            alarm_name: "#{input.name}-high-storage-carbon",
            comparison_operator: "GreaterThanThreshold",
            evaluation_periods: 2,
            metric_name: "CarbonPerGB",
            namespace: "GreenDataLifecycle/#{input.name}",
            period: 86_400,
            statistic: "Average",
            threshold: input.carbon_threshold_gco2_per_gb,
            alarm_description: "Alert when storage carbon intensity is high",
            treat_missing_data: "notBreaching",
            tags: input.tags
          })
        end

        def create_inefficient_storage_alarm(input)
          aws_cloudwatch_alarm(:"#{input.name}-inefficient-storage-alarm", {
            alarm_name: "#{input.name}-inefficient-storage",
            comparison_operator: "LessThanThreshold",
            evaluation_periods: 3,
            metric_name: "StorageEfficiency",
            namespace: "GreenDataLifecycle/#{input.name}",
            period: 86_400,
            statistic: "Average",
            threshold: 70.0,
            alarm_description: "Alert when storage efficiency is low",
            treat_missing_data: "notBreaching",
            tags: input.tags
          })
        end
      end
    end
  end
end
