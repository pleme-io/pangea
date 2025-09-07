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


require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/aws_cloudwatch_dashboard/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS CloudWatch Dashboard with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] CloudWatch Dashboard attributes
      # @option attributes [String] :dashboard_name The name of the dashboard
      # @option attributes [Hash] :dashboard_body The dashboard body as a hash (will be converted to JSON)
      # @option attributes [String] :dashboard_body_json The dashboard body as a JSON string
      # @option attributes [Array] :widgets Array of widget configurations
      # @return [ResourceReference] Reference object with outputs and computed properties
      #
      # @example Simple dashboard with JSON body
      #   dashboard = aws_cloudwatch_dashboard(:app_dashboard, {
      #     dashboard_name: "application-monitoring",
      #     dashboard_body_json: JSON.pretty_generate({
      #       widgets: [
      #         {
      #           type: "metric",
      #           x: 0, y: 0, width: 12, height: 6,
      #           properties: {
      #             metrics: [
      #               ["AWS/EC2", "CPUUtilization", "InstanceId", "i-1234567890abcdef0"]
      #             ],
      #             view: "timeSeries",
      #             region: "us-east-1",
      #             title: "EC2 CPU Utilization"
      #           }
      #         }
      #       ]
      #     })
      #   })
      #
      # @example Dashboard with widget configuration
      #   dashboard = aws_cloudwatch_dashboard(:comprehensive_dashboard, {
      #     dashboard_name: "production-overview",
      #     widgets: [
      #       {
      #         type: "metric",
      #         x: 0, y: 0, width: 12, height: 6,
      #         properties: {
      #           metrics: [
      #             ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", alb.arn_suffix]
      #           ],
      #           view: "timeSeries",
      #           region: "us-east-1",
      #           title: "Load Balancer Request Count",
      #           period: 300,
      #           stat: "Sum"
      #         }
      #       },
      #       {
      #         type: "text",
      #         x: 12, y: 0, width: 12, height: 6,
      #         properties: {
      #           markdown: "# Production Dashboard\\n\\nMonitoring key metrics for production environment."
      #         }
      #       }
      #     ]
      #   })
      #
      # @example Complex monitoring dashboard
      #   dashboard = aws_cloudwatch_dashboard(:microservices_dashboard, {
      #     dashboard_name: "microservices-health",
      #     widgets: [
      #       {
      #         type: "metric",
      #         x: 0, y: 0, width: 8, height: 6,
      #         properties: {
      #           metrics: [
      #             ["AWS/ECS", "CPUUtilization", "ServiceName", "user-service"],
      #             ["AWS/ECS", "CPUUtilization", "ServiceName", "order-service"]
      #           ],
      #           view: "timeSeries",
      #           title: "Service CPU Utilization",
      #           yaxis: { left: { min: 0, max: 100 } }
      #         }
      #       },
      #       {
      #         type: "number",
      #         x: 8, y: 0, width: 8, height: 6,
      #         properties: {
      #           metrics: [
      #             ["AWS/ApplicationELB", "HTTPCode_Target_2XX_Count", "LoadBalancer", alb.arn_suffix]
      #           ],
      #           view: "singleValue",
      #           title: "Successful Requests (24h)"
      #         }
      #       },
      #       {
      #         type: "log",
      #         x: 16, y: 0, width: 8, height: 6,
      #         properties: {
      #           query: "fields @timestamp, @message\\n| filter @message like /ERROR/\\n| sort @timestamp desc\\n| limit 20",
      #           source: "/application/user-service",
      #           title: "Recent Errors"
      #         }
      #       }
      #     ]
      #   })
      def aws_cloudwatch_dashboard(name, attributes = {})
        # Validate attributes using dry-struct
        dashboard_attrs = Types::Types::CloudWatchDashboardAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_cloudwatch_dashboard, name) do
          dashboard_name dashboard_attrs.dashboard_name
          dashboard_body dashboard_attrs.to_h[:dashboard_body]
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_cloudwatch_dashboard',
          name: name,
          resource_attributes: dashboard_attrs.to_h,
          outputs: {
            dashboard_arn: "${aws_cloudwatch_dashboard.#{name}.dashboard_arn}",
            dashboard_name: "${aws_cloudwatch_dashboard.#{name}.dashboard_name}"
          },
          computed_properties: {
            widget_count: dashboard_attrs.widget_count,
            has_custom_body: dashboard_attrs.has_custom_body?,
            uses_widgets: dashboard_attrs.uses_widgets?,
            dashboard_grid_height: dashboard_attrs.dashboard_grid_height,
            estimated_monthly_cost_usd: dashboard_attrs.estimated_monthly_cost_usd
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)