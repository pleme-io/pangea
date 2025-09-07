# Service Mesh Observability Component

Comprehensive observability stack for distributed microservices with distributed tracing, metrics aggregation, service map visualization, and intelligent alerting.

## Overview

The `service_mesh_observability` component creates a complete observability solution for microservices architectures with:

- **Distributed Tracing**: AWS X-Ray integration with custom sampling rules
- **Service Map Visualization**: Real-time dependency mapping and flow analysis
- **Metrics Aggregation**: CloudWatch metrics with custom dashboards
- **Log Aggregation**: Centralized logging with CloudWatch Logs Insights
- **Intelligent Alerting**: Threshold-based and anomaly detection alerts
- **Container Insights**: Deep visibility into containerized workloads
- **Cost Tracking**: Monitor and optimize observability costs

## Usage

### Basic Service Mesh Observability

```ruby
# Create observability stack for a simple microservice architecture
observability = service_mesh_observability(:platform_observability, {
  mesh_name: "platform-mesh",
  
  services: [
    {
      name: "api-gateway",
      cluster_ref: ecs_cluster_ref,
      task_definition_ref: api_gateway_task_ref,
      port: 8080,
      protocol: "HTTP",
      health_check_path: "/health"
    },
    {
      name: "user-service",
      cluster_ref: ecs_cluster_ref,
      task_definition_ref: user_service_task_ref,
      port: 3000,
      protocol: "HTTP"
    },
    {
      name: "order-service",
      cluster_ref: ecs_cluster_ref,
      task_definition_ref: order_service_task_ref,
      port: 3001,
      protocol: "HTTP"
    }
  ],
  
  alerting: {
    enabled: true,
    notification_channel_ref: ops_sns_topic_ref,
    latency_threshold_ms: 1000,
    error_rate_threshold: 0.05
  }
})
```

### Advanced Observability with Custom Configuration

```ruby
# Create comprehensive observability for complex microservices
advanced_observability = service_mesh_observability(:ecommerce_observability, {
  mesh_name: "ecommerce-mesh",
  mesh_description: "E-commerce platform service mesh observability",
  
  services: [
    {
      name: "frontend",
      namespace: "web",
      cluster_ref: web_cluster_ref,
      task_definition_ref: frontend_task_ref,
      port: 80,
      protocol: "HTTP"
    },
    {
      name: "product-api",
      namespace: "api",
      cluster_ref: api_cluster_ref,
      task_definition_ref: product_api_task_ref,
      port: 8080,
      protocol: "HTTP",
      health_check_path: "/api/health"
    },
    {
      name: "payment-service",
      namespace: "api",
      cluster_ref: api_cluster_ref,
      task_definition_ref: payment_task_ref,
      port: 8443,
      protocol: "GRPC"
    },
    {
      name: "inventory-service",
      namespace: "backend",
      cluster_ref: backend_cluster_ref,
      task_definition_ref: inventory_task_ref,
      port: 3000,
      protocol: "HTTP"
    }
  ],
  
  # X-Ray configuration
  xray_enabled: true,
  xray_encryption_config: {
    type: "KMS",
    key_id: xray_kms_key_ref.id
  },
  xray_insights_enabled: true,
  
  # Distributed tracing
  tracing: {
    enabled: true,
    sampling_rate: 0.1,  # Sample 10% of requests
    trace_id_header: "X-Amzn-Trace-Id",
    span_header: "X-Span-Id"
  },
  
  # Metrics collection
  metrics: {
    enabled: true,
    collection_interval: 60,
    detailed_metrics: true,
    prometheus_enabled: true,
    prometheus_port: 9090,
    custom_metrics: [
      {
        name: "checkout_completion_rate",
        namespace: "Ecommerce/Business",
        dimensions: { Service: "frontend" }
      }
    ]
  },
  
  # Service map configuration
  service_map: {
    enabled: true,
    update_interval: 300,
    include_external_services: true,
    group_by_namespace: true
  },
  
  # Advanced alerting
  alerting: {
    enabled: true,
    notification_channel_ref: pagerduty_sns_ref,
    latency_threshold_ms: 500,  # Strict SLA
    error_rate_threshold: 0.01,  # 1% error rate
    availability_threshold: 0.999,  # 99.9% availability
    circuit_breaker_threshold: 10
  },
  
  # Log aggregation
  log_aggregation: {
    enabled: true,
    retention_days: 90,
    filter_patterns: [
      {
        name: "error-filter",
        pattern: "[timestamp, request_id, level=ERROR, ...]",
        metric_name: "ErrorCount",
        metric_namespace: "Ecommerce/Logs"
      },
      {
        name: "slow-request-filter",
        pattern: "[timestamp, request_id, level, latency > 1000, ...]",
        metric_name: "SlowRequestCount"
      }
    ],
    insights_queries: [
      {
        name: "Top Errors by Service",
        query: "fields @timestamp, service, @message | filter level = 'ERROR' | stats count() by service"
      },
      {
        name: "Request Latency P95",
        query: "fields latency | filter latency > 0 | stats percentile(latency, 95) by bin(5m)"
      }
    ]
  },
  
  # Enhanced monitoring
  enhanced_monitoring_enabled: true,
  anomaly_detection_enabled: true,
  container_insights_enabled: true,
  
  # Cost tracking
  cost_tracking_enabled: true,
  cost_allocation_tags: {
    Environment: "production",
    CostCenter: "engineering",
    Team: "platform"
  }
})
```

### Kubernetes Service Mesh Observability

```ruby
# Create observability for Kubernetes-based microservices
k8s_observability = service_mesh_observability(:k8s_mesh_observability, {
  mesh_name: "k8s-service-mesh",
  
  services: [
    {
      name: "istio-gateway",
      namespace: "istio-system",
      cluster_ref: eks_cluster_ref,
      deployment_ref: istio_gateway_deployment_ref,
      port: 80,
      protocol: "HTTP"
    },
    {
      name: "productpage",
      namespace: "bookinfo",
      cluster_ref: eks_cluster_ref,
      deployment_ref: productpage_deployment_ref,
      port: 9080,
      protocol: "HTTP"
    },
    {
      name: "reviews",
      namespace: "bookinfo",
      cluster_ref: eks_cluster_ref,
      deployment_ref: reviews_deployment_ref,
      port: 9080,
      protocol: "HTTP"
    }
  ],
  
  # Custom dashboard widgets
  dashboard_widgets: [
    {
      type: "metric",
      title: "Service Mesh Request Rate",
      metrics: [
        ["Kubernetes", "pod_network_rx_bytes", { Namespace: "bookinfo" }],
        ["Kubernetes", "pod_network_tx_bytes", { Namespace: "bookinfo" }]
      ],
      width: 12,
      height: 6
    },
    {
      type: "log",
      title: "Recent Errors",
      width: 24,
      height: 8,
      properties: {
        query: "SOURCE '/aws/containerinsights/k8s-cluster/application' | fields @timestamp, kubernetes.pod_name, log | filter log like /ERROR/"
      }
    }
  ],
  
  dashboard_name: "k8s-service-mesh-dashboard",
  dashboard_refresh_interval: 60
})
```

### Multi-Region Service Mesh Observability

```ruby
# Create observability for multi-region microservices
global_observability = service_mesh_observability(:global_mesh_observability, {
  mesh_name: "global-service-mesh",
  
  services: [
    {
      name: "global-lb",
      namespace: "edge",
      cluster_ref: us_east_cluster_ref,
      task_definition_ref: global_lb_task_ref,
      port: 443,
      protocol: "TCP"
    },
    {
      name: "api-us-east",
      namespace: "regional",
      cluster_ref: us_east_cluster_ref,
      task_definition_ref: api_task_ref,
      port: 8080
    },
    {
      name: "api-eu-west",
      namespace: "regional",
      cluster_ref: eu_west_cluster_ref,
      task_definition_ref: api_task_ref,
      port: 8080
    },
    {
      name: "api-ap-south",
      namespace: "regional",
      cluster_ref: ap_south_cluster_ref,
      task_definition_ref: api_task_ref,
      port: 8080
    }
  ],
  
  # Global service map
  service_map: {
    enabled: true,
    update_interval: 60,  # More frequent updates for global view
    include_external_services: true,
    group_by_namespace: true
  },
  
  # Regional alerting thresholds
  alerting: {
    enabled: true,
    latency_threshold_ms: 2000,  # Higher threshold for cross-region
    error_rate_threshold: 0.02,
    availability_threshold: 0.995
  },
  
  # Extended log retention for compliance
  log_aggregation: {
    enabled: true,
    retention_days: 365,
    insights_queries: [
      {
        name: "Cross-Region Latency",
        query: "fields region, latency | stats avg(latency) by region, bin(5m)"
      }
    ]
  }
})
```

## Inputs

### Required Inputs

- `mesh_name`: Name of the service mesh
- `services`: Array of service configurations to monitor

### Service Configuration

```ruby
{
  name: "service-name",
  namespace: "default",
  cluster_ref: ecs_cluster_ref,
  task_definition_ref: task_def_ref,  # For ECS
  deployment_ref: deployment_ref,      # For K8s
  port: 80,
  protocol: "HTTP",  # HTTP, GRPC, TCP
  health_check_path: "/health"
}
```

### Optional Inputs

- `mesh_description`: Description of the service mesh
- `xray_enabled`: Enable X-Ray tracing (default: true)
- `xray_encryption_config`: X-Ray encryption settings
- `tracing`: Distributed tracing configuration
- `metrics`: Metrics collection configuration
- `service_map`: Service map visualization settings
- `alerting`: Alerting configuration
- `log_aggregation`: Log aggregation settings
- `dashboard_widgets`: Custom dashboard widgets
- `container_insights_enabled`: Enable Container Insights (default: true)
- `anomaly_detection_enabled`: Enable anomaly detection (default: false)

## Outputs

The component returns a `ComponentReference` with:

- `mesh_name`: Name of the service mesh
- `dashboard_url`: CloudWatch dashboard URL
- `xray_service_map_url`: X-Ray service map URL
- `services_monitored`: List of monitored services
- `observability_features`: Enabled features list
- `monitoring_metrics`: Available metrics
- `alarms_configured`: Configured alarm types
- `sampling_rate`: Tracing sampling rate
- `log_retention_days`: Log retention period
- `estimated_monthly_cost`: Estimated AWS costs

## Resources Created

- `aws_xray_encryption_config`: X-Ray encryption configuration
- `aws_xray_sampling_rule`: Sampling rules for each service
- `aws_xray_group`: X-Ray group for service mesh
- `aws_cloudwatch_log_group`: Log groups for services
- `aws_cloudwatch_log_metric_filter`: Log-based metrics
- `aws_cloudwatch_metric_alarm`: Service health alarms
- `aws_cloudwatch_dashboard`: Unified observability dashboard
- `aws_cloudwatch_query_definition`: Logs Insights queries
- `aws_cloudwatch_anomaly_detector`: Anomaly detection (optional)
- `aws_sns_topic`: Alert notification topic (optional)

## Best Practices

1. **Tracing Strategy**
   - Set appropriate sampling rates (0.1-0.5 for production)
   - Use consistent trace headers across services
   - Implement trace ID propagation in all services
   - Include business context in trace segments

2. **Metrics Design**
   - Define SLIs (Service Level Indicators) for each service
   - Create custom metrics for business KPIs
   - Use dimensions wisely to control costs
   - Set up percentile metrics for latency

3. **Alerting Philosophy**
   - Alert on symptoms, not causes
   - Set thresholds based on SLOs
   - Use multi-metric alarms for accuracy
   - Implement alert fatigue prevention

4. **Log Management**
   - Structure logs in JSON format
   - Include correlation IDs in all logs
   - Set appropriate retention periods
   - Use log insights for complex queries

5. **Cost Optimization**
   - Adjust sampling rates based on traffic
   - Use log filtering to reduce ingestion
   - Set retention policies appropriately
   - Monitor observability costs regularly