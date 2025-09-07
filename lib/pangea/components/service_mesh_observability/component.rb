# frozen_string_literal: true

require 'pangea/components/base'
require 'pangea/components/service_mesh_observability/types'
require 'pangea/resources/aws'
require 'json'

module Pangea
  module Components
    # Comprehensive observability stack for distributed microservices with tracing, metrics, and service maps
    # Creates X-Ray tracing, CloudWatch dashboards, alarms, and service visualization
    def service_mesh_observability(name, attributes = {})
      include Base
      include Resources::AWS
      
      # Validate and set defaults
      component_attrs = ServiceMeshObservability::ServiceMeshObservabilityAttributes.new(attributes)
      component_attrs.validate!
      
      # Generate component-specific tags
      component_tag_set = component_tags('ServiceMeshObservability', name, component_attrs.tags)
      
      resources = {}
      
      # Create X-Ray encryption configuration if enabled
      if component_attrs.xray_enabled && component_attrs.xray_encryption_config[:type] == "KMS"
        xray_encryption_ref = aws_xray_encryption_config(
          component_resource_name(name, :xray_encryption),
          {
            type: "KMS",
            key_id: component_attrs.xray_encryption_config[:key_id] || "alias/aws/xray"
          }
        )
        resources[:xray_encryption] = xray_encryption_ref
      end
      
      # Create X-Ray sampling rules for each service
      sampling_rules = {}
      component_attrs.services.each do |service|
        sampling_rule_ref = aws_xray_sampling_rule(
          component_resource_name(name, :sampling_rule, service.name.to_sym),
          {
            rule_name: "#{name}-#{service.name}-sampling",
            priority: 9000,
            version: 1,
            reservoir_size: 1,
            fixed_rate: component_attrs.tracing.sampling_rate,
            url_path: "*",
            host: "*",
            http_method: "*",
            service_type: "*",
            service_name: service.name,
            resource_arn: "*",
            attributes: {
              namespace: service.namespace
            },
            tags: component_tag_set
          }
        )
        sampling_rules[service.name.to_sym] = sampling_rule_ref
      end
      resources[:sampling_rules] = sampling_rules
      
      # Create log groups for service logs if not existing
      log_groups = {}
      if component_attrs.log_aggregation.enabled
        component_attrs.services.each do |service|
          log_group_name = "/ecs/#{service.name}"
          log_group_ref = aws_cloudwatch_log_group(
            component_resource_name(name, :log_group, service.name.to_sym),
            {
              name: log_group_name,
              retention_in_days: component_attrs.log_aggregation.retention_days,
              tags: component_tag_set
            }
          )
          log_groups[service.name.to_sym] = log_group_ref
        end
        resources[:log_groups] = log_groups
      end
      
      # Create metric filters for log-based metrics
      metric_filters = {}
      if component_attrs.log_aggregation.enabled && component_attrs.log_aggregation.filter_patterns.any?
        component_attrs.log_aggregation.filter_patterns.each_with_index do |filter, index|
          metric_filter_ref = aws_cloudwatch_log_metric_filter(
            component_resource_name(name, :metric_filter, "filter#{index}".to_sym),
            {
              name: filter[:name] || "#{name}-filter-#{index}",
              log_group_name: filter[:log_group] || log_groups.values.first.name,
              pattern: filter[:pattern],
              metric_transformation: {
                name: filter[:metric_name],
                namespace: filter[:namespace] || "#{component_attrs.mesh_name}/CustomMetrics",
                value: filter[:value] || "1",
                default_value: filter[:default_value]
              }
            }
          )
          metric_filters["filter#{index}".to_sym] = metric_filter_ref
        end
      end
      resources[:metric_filters] = metric_filters unless metric_filters.empty?
      
      # Create X-Ray group for service mesh
      xray_group_ref = aws_xray_group(
        component_resource_name(name, :xray_group),
        {
          group_name: component_attrs.mesh_name,
          filter_expression: "service(\"#{component_attrs.services.map(&:name).join('\" OR \"')}\")",
          insights_configuration: component_attrs.xray_insights_enabled ? {
            insights_enabled: true,
            notifications_enabled: component_attrs.alerting.enabled
          } : nil,
          tags: component_tag_set
        }.compact
      )
      resources[:xray_group] = xray_group_ref
      
      # Create SNS topic for alerts if configured
      if component_attrs.alerting.enabled && !component_attrs.alerting.notification_channel_ref
        alert_topic_ref = aws_sns_topic(
          component_resource_name(name, :alert_topic),
          {
            name: "#{name}-alerts",
            display_name: "#{component_attrs.mesh_name} Alerts",
            tags: component_tag_set
          }
        )
        resources[:alert_topic] = alert_topic_ref
      end
      
      notification_arn = component_attrs.alerting.notification_channel_ref&.arn || 
                        (resources[:alert_topic]&.arn if component_attrs.alerting.enabled)
      
      # Create CloudWatch alarms for each service
      alarms = {}
      if component_attrs.alerting.enabled
        component_attrs.services.each do |service|
          service_alarms = {}
          
          # High latency alarm
          latency_alarm_ref = aws_cloudwatch_metric_alarm(
            component_resource_name(name, :alarm_latency, service.name.to_sym),
            {
              alarm_name: "#{name}-#{service.name}-high-latency",
              comparison_operator: "GreaterThanThreshold",
              evaluation_periods: "2",
              metric_name: "TracedRequestLatency",
              namespace: "AWS/X-Ray",
              period: "300",
              statistic: "Average",
              threshold: component_attrs.alerting.latency_threshold_ms.to_s,
              alarm_description: "Service #{service.name} latency is high",
              dimensions: {
                ServiceName: service.name
              },
              alarm_actions: notification_arn ? [notification_arn] : nil,
              tags: component_tag_set
            }.compact
          )
          service_alarms[:latency] = latency_alarm_ref
          
          # Error rate alarm
          error_alarm_ref = aws_cloudwatch_metric_alarm(
            component_resource_name(name, :alarm_errors, service.name.to_sym),
            {
              alarm_name: "#{name}-#{service.name}-error-rate",
              comparison_operator: "GreaterThanThreshold",
              evaluation_periods: "2",
              threshold: (component_attrs.alerting.error_rate_threshold * 100).to_s,
              alarm_description: "Service #{service.name} error rate is high",
              alarm_actions: notification_arn ? [notification_arn] : nil,
              tags: component_tag_set,
              metric_query: [
                {
                  id: "error_rate",
                  expression: "(errors / requests) * 100",
                  label: "Error Rate",
                  return_data: true
                },
                {
                  id: "errors",
                  metric: {
                    metric_name: "ErrorCount",
                    namespace: "AWS/X-Ray",
                    period: 300,
                    stat: "Sum",
                    dimensions: {
                      ServiceName: service.name
                    }
                  }
                },
                {
                  id: "requests",
                  metric: {
                    metric_name: "TracedRequestCount",
                    namespace: "AWS/X-Ray",
                    period: 300,
                    stat: "Sum",
                    dimensions: {
                      ServiceName: service.name
                    }
                  }
                }
              ]
            }
          )
          service_alarms[:error_rate] = error_alarm_ref
          
          # Availability alarm
          availability_alarm_ref = aws_cloudwatch_metric_alarm(
            component_resource_name(name, :alarm_availability, service.name.to_sym),
            {
              alarm_name: "#{name}-#{service.name}-availability",
              comparison_operator: "LessThanThreshold",
              evaluation_periods: "3",
              threshold: (component_attrs.alerting.availability_threshold * 100).to_s,
              alarm_description: "Service #{service.name} availability is low",
              alarm_actions: notification_arn ? [notification_arn] : nil,
              tags: component_tag_set,
              metric_query: [
                {
                  id: "availability",
                  expression: "(1 - (errors / requests)) * 100",
                  label: "Availability",
                  return_data: true
                },
                {
                  id: "errors",
                  metric: {
                    metric_name: "ErrorCount",
                    namespace: "AWS/X-Ray",
                    period: 300,
                    stat: "Sum",
                    dimensions: {
                      ServiceName: service.name
                    }
                  }
                },
                {
                  id: "requests",
                  metric: {
                    metric_name: "TracedRequestCount",
                    namespace: "AWS/X-Ray",
                    period: 300,
                    stat: "Sum",
                    dimensions: {
                      ServiceName: service.name
                    }
                  }
                }
              ]
            }
          )
          service_alarms[:availability] = availability_alarm_ref
          
          # ECS/Fargate specific alarms if task definition provided
          if service.task_definition_ref
            cpu_alarm_ref = aws_cloudwatch_metric_alarm(
              component_resource_name(name, :alarm_cpu, service.name.to_sym),
              {
                alarm_name: "#{name}-#{service.name}-cpu-high",
                comparison_operator: "GreaterThanThreshold",
                evaluation_periods: "2",
                metric_name: "CPUUtilization",
                namespace: "AWS/ECS",
                period: "300",
                statistic: "Average",
                threshold: "80",
                alarm_description: "Service #{service.name} CPU utilization is high",
                dimensions: {
                  ServiceName: service.name,
                  ClusterName: service.cluster_ref.name
                },
                alarm_actions: notification_arn ? [notification_arn] : nil,
                tags: component_tag_set
              }.compact
            )
            service_alarms[:cpu] = cpu_alarm_ref
            
            memory_alarm_ref = aws_cloudwatch_metric_alarm(
              component_resource_name(name, :alarm_memory, service.name.to_sym),
              {
                alarm_name: "#{name}-#{service.name}-memory-high",
                comparison_operator: "GreaterThanThreshold",
                evaluation_periods: "2",
                metric_name: "MemoryUtilization",
                namespace: "AWS/ECS",
                period: "300",
                statistic: "Average",
                threshold: "80",
                alarm_description: "Service #{service.name} memory utilization is high",
                dimensions: {
                  ServiceName: service.name,
                  ClusterName: service.cluster_ref.name
                },
                alarm_actions: notification_arn ? [notification_arn] : nil,
                tags: component_tag_set
              }.compact
            )
            service_alarms[:memory] = memory_alarm_ref
          end
          
          alarms[service.name.to_sym] = service_alarms
        end
      end
      resources[:alarms] = alarms
      
      # Create CloudWatch Dashboard
      dashboard_name = component_attrs.dashboard_name || "#{name}-service-mesh"
      
      # Build dashboard widgets
      dashboard_widgets = []
      
      # Service map widget
      if component_attrs.service_map.enabled
        dashboard_widgets << {
          type: "metric",
          x: 0,
          y: 0,
          width: 24,
          height: 8,
          properties: {
            title: "Service Map",
            view: "servicemap",
            region: "${AWS::Region}",
            period: component_attrs.service_map.update_interval
          }
        }
      end
      
      # Request metrics
      dashboard_widgets << {
        type: "metric",
        x: 0,
        y: 8,
        width: 12,
        height: 6,
        properties: {
          title: "Request Rates",
          metrics: component_attrs.services.map do |service|
            ["AWS/X-Ray", "TracedRequestCount", { ServiceName: service.name }]
          end,
          period: 300,
          stat: "Sum",
          region: "${AWS::Region}",
          yAxis: { left: { label: "Requests" } }
        }
      }
      
      # Latency metrics
      dashboard_widgets << {
        type: "metric",
        x: 12,
        y: 8,
        width: 12,
        height: 6,
        properties: {
          title: "Service Latencies",
          metrics: component_attrs.services.map do |service|
            ["AWS/X-Ray", "TracedRequestLatency", { ServiceName: service.name }]
          end,
          period: 300,
          stat: "Average",
          region: "${AWS::Region}",
          yAxis: { left: { label: "Milliseconds" } }
        }
      }
      
      # Error rates
      dashboard_widgets << {
        type: "metric",
        x: 0,
        y: 14,
        width: 12,
        height: 6,
        properties: {
          title: "Error Rates",
          metrics: [],
          period: 300,
          stat: "Average",
          region: "${AWS::Region}",
          yAxis: { left: { label: "Error %" } },
          annotations: {
            horizontal: [{
              label: "Error Threshold",
              value: component_attrs.alerting.error_rate_threshold * 100
            }]
          }
        }
      }
      
      # Resource utilization (if ECS/Fargate)
      if component_attrs.services.any? { |s| s.task_definition_ref }
        dashboard_widgets << {
          type: "metric",
          x: 12,
          y: 14,
          width: 12,
          height: 6,
          properties: {
            title: "Resource Utilization",
            metrics: component_attrs.services.select { |s| s.task_definition_ref }.flat_map do |service|
              [
                ["AWS/ECS", "CPUUtilization", { ServiceName: service.name, ClusterName: service.cluster_ref.name }],
                [".", "MemoryUtilization", { ServiceName: service.name, ClusterName: service.cluster_ref.name }]
              ]
            end,
            period: 300,
            stat: "Average",
            region: "${AWS::Region}",
            yAxis: { left: { label: "Percentage" } }
          }
        }
      end
      
      # Add custom widgets if provided
      component_attrs.dashboard_widgets.each_with_index do |widget, index|
        dashboard_widgets << {
          type: widget.type,
          x: (index % 2) * 12,
          y: 20 + (index / 2) * 6,
          width: widget.width,
          height: widget.height,
          properties: widget.properties.merge({
            title: widget.title,
            metrics: widget.metrics
          })
        }
      end
      
      dashboard_ref = aws_cloudwatch_dashboard(
        component_resource_name(name, :dashboard),
        {
          dashboard_name: dashboard_name,
          dashboard_body: JSON.generate({
            widgets: dashboard_widgets,
            periodOverride: "auto",
            start: "-PT6H"
          })
        }
      )
      resources[:dashboard] = dashboard_ref
      
      # Create CloudWatch Logs Insights queries
      insights_queries = {}
      if component_attrs.log_aggregation.enabled && component_attrs.log_aggregation.insights_queries.any?
        component_attrs.log_aggregation.insights_queries.each_with_index do |query, index|
          query_ref = aws_cloudwatch_query_definition(
            component_resource_name(name, :insights_query, "query#{index}".to_sym),
            {
              name: query[:name] || "#{name}-query-#{index}",
              query_string: query[:query],
              log_group_names: query[:log_groups] || log_groups.values.map(&:name)
            }
          )
          insights_queries["query#{index}".to_sym] = query_ref
        end
      end
      resources[:insights_queries] = insights_queries unless insights_queries.empty?
      
      # Create Container Insights configuration if enabled
      if component_attrs.container_insights_enabled
        component_attrs.services.each do |service|
          if service.cluster_ref
            container_insights_ref = aws_ecs_cluster_capacity_providers(
              component_resource_name(name, :container_insights, service.name.to_sym),
              {
                cluster_name: service.cluster_ref.name,
                capacity_providers: ["FARGATE", "FARGATE_SPOT"],
                default_capacity_provider_strategy: [{
                  capacity_provider: "FARGATE",
                  weight: 1,
                  base: 0
                }]
              }
            )
            # Note: Container Insights is typically enabled at cluster creation
            # This is a placeholder for the configuration
          end
        end
      end
      
      # Create anomaly detectors if enabled
      anomaly_detectors = {}
      if component_attrs.anomaly_detection_enabled
        component_attrs.services.each do |service|
          anomaly_detector_ref = aws_cloudwatch_anomaly_detector(
            component_resource_name(name, :anomaly_detector, service.name.to_sym),
            {
              metric_name: "TracedRequestLatency",
              namespace: "AWS/X-Ray",
              dimensions: {
                ServiceName: service.name
              },
              stat: "Average"
            }
          )
          anomaly_detectors[service.name.to_sym] = anomaly_detector_ref
        end
      end
      resources[:anomaly_detectors] = anomaly_detectors unless anomaly_detectors.empty?
      
      # Calculate outputs
      outputs = {
        mesh_name: component_attrs.mesh_name,
        dashboard_url: "https://console.aws.amazon.com/cloudwatch/home?region=${AWS::Region}#dashboards:name=#{dashboard_name}",
        xray_service_map_url: "https://console.aws.amazon.com/xray/home?region=${AWS::Region}#/service-map",
        
        services_monitored: component_attrs.services.map(&:name),
        
        observability_features: [
          ("X-Ray Distributed Tracing" if component_attrs.xray_enabled),
          ("Service Map Visualization" if component_attrs.service_map.enabled),
          ("CloudWatch Dashboard" if resources[:dashboard]),
          ("Container Insights" if component_attrs.container_insights_enabled),
          ("Log Aggregation" if component_attrs.log_aggregation.enabled),
          ("Anomaly Detection" if component_attrs.anomaly_detection_enabled),
          ("Cost Tracking" if component_attrs.cost_tracking_enabled)
        ].compact,
        
        monitoring_metrics: [
          "Request Rate",
          "Latency (p50, p90, p99)",
          "Error Rate",
          "Availability",
          ("CPU Utilization" if component_attrs.services.any? { |s| s.task_definition_ref }),
          ("Memory Utilization" if component_attrs.services.any? { |s| s.task_definition_ref })
        ].compact,
        
        alarms_configured: alarms.values.flat_map { |service_alarms| service_alarms.keys }.uniq.map(&:to_s),
        
        sampling_rate: component_attrs.tracing.sampling_rate,
        log_retention_days: component_attrs.log_aggregation.retention_days,
        
        estimated_monthly_cost: estimate_observability_cost(component_attrs)
      }
      
      create_component_reference(
        'service_mesh_observability',
        name,
        component_attrs.to_h,
        resources,
        outputs
      )
    end
    
    private
    
    def estimate_observability_cost(attrs)
      cost = 0.0
      
      # X-Ray costs
      if attrs.xray_enabled
        # Estimated traces per month
        traces_per_month = attrs.services.length * 1_000_000 * attrs.tracing.sampling_rate
        cost += (traces_per_month / 1_000_000) * 5.00  # $5 per million traces
        cost += (traces_per_month / 1_000_000) * 0.50  # $0.50 per million traces retrieved
      end
      
      # CloudWatch Logs costs
      if attrs.log_aggregation.enabled
        # Estimated log ingestion
        log_gb_per_month = attrs.services.length * 50  # 50GB per service estimate
        cost += log_gb_per_month * 0.50  # $0.50 per GB ingested
        
        # Log storage
        cost += log_gb_per_month * 0.03  # $0.03 per GB stored
      end
      
      # CloudWatch Metrics costs
      # First 10,000 metrics free, then $0.30 per metric
      metrics_count = attrs.services.length * 10  # Estimate 10 metrics per service
      if metrics_count > 10000
        cost += (metrics_count - 10000) * 0.30
      end
      
      # CloudWatch Alarms costs
      if attrs.alerting.enabled
        alarms_count = attrs.services.length * 4  # 4 alarms per service
        cost += alarms_count * 0.10  # $0.10 per alarm
      end
      
      # CloudWatch Dashboard costs
      cost += 3.00  # $3 per dashboard
      
      # Container Insights costs (if enabled)
      if attrs.container_insights_enabled
        cost += attrs.services.length * 5.00  # Estimated $5 per service
      end
      
      cost.round(2)
    end
  end
end