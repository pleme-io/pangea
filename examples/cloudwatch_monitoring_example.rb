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

# CloudWatch Monitoring Example - demonstrates all three CloudWatch resources

template :cloudwatch_monitoring do
  provider :aws do
    region "us-east-1"
  end

  # Create log groups for different purposes
  app_logs = aws_cloudwatch_log_group(:app_logs, {
    name: "/application/web-service",
    retention_in_days: 14,
    tags: {
      Environment: "production",
      Application: "web-service",
      LogType: "application"
    }
  })

  audit_logs = aws_cloudwatch_log_group(:audit_logs, {
    name: "/audit/security-events",
    retention_in_days: 365,
    log_group_class: "INFREQUENT_ACCESS",
    tags: {
      Environment: "production",
      DataClassification: "confidential",
      LogType: "audit"
    }
  })

  # Create log streams within the log groups
  app_stream = aws_cloudwatch_log_stream(:app_instance_stream, {
    name: "instance-001/application",
    log_group_name: app_logs.name
  })

  audit_stream = aws_cloudwatch_log_stream(:security_events_stream, {
    name: "security-analyzer/#{Time.now.strftime('%Y-%m-%d')}",
    log_group_name: audit_logs.name
  })

  # Create a comprehensive monitoring dashboard
  monitoring_dashboard = aws_cloudwatch_dashboard(:production_monitoring, {
    dashboard_name: "production-monitoring-overview",
    widgets: [
      # Application metrics
      {
        type: "metric",
        x: 0, y: 0, width: 12, height: 6,
        properties: {
          metrics: [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", "web-service-alb"],
            ["AWS/ApplicationELB", "HTTPCode_Target_2XX_Count", "LoadBalancer", "web-service-alb"],
            ["AWS/ApplicationELB", "HTTPCode_Target_5XX_Count", "LoadBalancer", "web-service-alb"]
          ],
          view: "timeSeries",
          title: "Application Load Balancer Metrics",
          region: "us-east-1",
          period: 300
        }
      },
      
      # Response time
      {
        type: "metric",
        x: 12, y: 0, width: 12, height: 6,
        properties: {
          metrics: [
            ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", "web-service-alb"]
          ],
          view: "timeSeries",
          title: "Response Time",
          region: "us-east-1",
          period: 300,
          yaxis: { left: { min: 0 } }
        }
      },
      
      # Documentation widget
      {
        type: "text",
        x: 0, y: 6, width: 8, height: 4,
        properties: {
          markdown: <<~MARKDOWN
            # Production Monitoring Dashboard
            
            ## Key Metrics
            - **Request Volume**: Total requests per minute
            - **Success Rate**: 2XX responses percentage
            - **Error Rate**: 5XX responses count
            - **Response Time**: Average response time in seconds
            
            ## Alert Thresholds
            - **High Response Time**: > 1 second
            - **Error Rate**: > 1% of total requests
            - **Low Success Rate**: < 95% success rate
            
            **Dashboard Updated**: #{Time.now.strftime('%Y-%m-%d %H:%M UTC')}
          MARKDOWN
        }
      },
      
      # Recent application logs
      {
        type: "log",
        x: 8, y: 6, width: 16, height: 4,
        properties: {
          query: <<~QUERY,
            fields @timestamp, @message, level
            | filter level = "ERROR" or level = "WARN"
            | sort @timestamp desc
            | limit 20
          QUERY
          source: app_logs.name,
          title: "Recent Application Warnings and Errors"
        }
      },
      
      # Security events log analysis
      {
        type: "log",
        x: 0, y: 10, width: 24, height: 6,
        properties: {
          query: <<~QUERY,
            fields @timestamp, event_type, source_ip, user_agent, result
            | filter event_type = "login_attempt" and result = "failed"
            | stats count() by source_ip
            | sort count desc
            | limit 10
          QUERY
          source: audit_logs.name,
          title: "Failed Login Attempts by IP Address"
        }
      }
    ]
  })

  # Output important resource information
  output :log_groups do
    value [
      {
        name: app_logs.name,
        arn: app_logs.arn,
        type: "application",
        estimated_cost: "#{app_logs.computed_properties[:estimated_monthly_cost_usd]}"
      },
      {
        name: audit_logs.name,
        arn: audit_logs.arn,
        type: "audit",
        estimated_cost: "#{audit_logs.computed_properties[:estimated_monthly_cost_usd]}"
      }
    ]
  end

  output :log_streams do
    value [
      {
        name: app_stream.name,
        log_group: app_stream.log_group_name,
        type: app_stream.computed_properties[:stream_type]
      },
      {
        name: audit_stream.name,
        log_group: audit_stream.log_group_name,
        type: audit_stream.computed_properties[:stream_type]
      }
    ]
  end

  output :monitoring_dashboard do
    value {
      name: monitoring_dashboard.dashboard_name,
      arn: monitoring_dashboard.dashboard_arn,
      widget_count: monitoring_dashboard.computed_properties[:widget_count],
      estimated_monthly_cost: "#{monitoring_dashboard.computed_properties[:estimated_monthly_cost_usd]}"
    }
  end
end