# AWS CloudWatch Log Metric Filter - Architecture Documentation

## Core Concepts

### Metric Filter Design Philosophy

CloudWatch Log Metric Filters transform log data into actionable metrics, enabling real-time monitoring and alerting on application behavior. This resource implements:

1. **Log-to-Metric Transformation**: Convert unstructured logs into structured metrics
2. **Pattern-Based Extraction**: Flexible pattern matching for various log formats
3. **Dimensional Analysis**: Multi-dimensional metrics for detailed insights
4. **Real-Time Processing**: Near-instantaneous metric generation from log events

### Implementation Architecture

```
Log Metric Filter
├── Pattern Engine
│   ├── Space-Delimited Parser
│   ├── JSON Path Evaluator
│   ├── Text Matcher
│   └── Key-Value Parser
├── Metric Transformation
│   ├── Value Extraction
│   ├── Dimension Mapping
│   ├── Unit Assignment
│   └── Default Handling
└── CloudWatch Integration
    ├── Metric Publishing
    ├── Namespace Management
    └── Dimension Tracking
```

## Type Safety Implementation

### Validation Layers

1. **Pattern Validation**
   - Syntax validation for different pattern types
   - Field reference validation
   - Expression correctness checking

2. **Metric Configuration Validation**
   - Namespace format validation
   - Metric name constraints
   - Value expression validation
   - Unit enumeration enforcement

3. **Dimension Validation**
   - Key format validation
   - Value reference checking
   - Cardinality warnings

### Type Definitions

```ruby
# Metric transformation with strict typing
class MetricTransformation < Dry::Struct
  attribute :name, Resources::Types::String
  attribute :namespace, Resources::Types::String
  attribute :value, Resources::Types::String
  attribute :unit, Resources::Types::String.enum(...CloudWatch units...)
end

# Pattern type detection
def pattern_type
  case pattern
  when /^\[/ then :space_delimited
  when /\{.*\}/ then :json
  when /\w+\s*=\s*/ then :key_value
  else :text
  end
end
```

## Advanced Patterns

### 1. Multi-Stage Metric Extraction

Implement complex metric extraction pipelines:

```ruby
# Stage 1: Extract raw performance data
raw_perf_filter = aws_cloudwatch_log_metric_filter(:raw_performance, {
  name: "raw-performance-data",
  log_group_name: app_logs.name,
  pattern: '[timestamp, request_id, operation, duration_ms, memory_mb, cpu_percent]',
  metric_transformation: {
    name: "RawPerformance",
    namespace: "Application/Performance/Raw",
    value: "$duration_ms",
    dimensions: {
      Operation: "$operation"
    }
  }
})

# Stage 2: Calculate derived metrics
high_latency_filter = aws_cloudwatch_log_metric_filter(:high_latency, {
  name: "high-latency-operations",
  log_group_name: app_logs.name,
  pattern: '[timestamp, request_id, operation, duration_ms>1000, ...]',
  metric_transformation: {
    name: "HighLatencyCount",
    namespace: "Application/Performance/Alerts",
    value: "1",
    dimensions: {
      Operation: "$operation",
      Severity: "HIGH"
    }
  }
})

# Stage 3: Resource usage correlation
resource_correlation_filter = aws_cloudwatch_log_metric_filter(:resource_correlation, {
  name: "high-resource-operations",
  log_group_name: app_logs.name,
  pattern: '[timestamp, request_id, operation, duration_ms>500, memory_mb>512, cpu_percent>80]',
  metric_transformation: {
    name: "ResourceIntensiveOperations",
    namespace: "Application/Performance/Resources",
    value: "1",
    dimensions: {
      Operation: "$operation",
      ResourceType: "COMPUTE_INTENSIVE"
    }
  }
})
```

### 2. Security Incident Detection

Build comprehensive security monitoring:

```ruby
# Detect suspicious patterns
security_patterns = {
  sql_injection: {
    pattern: 'SELECT.*FROM.*WHERE.*OR.*1=1',
    metric: "SQLInjectionAttempts"
  },
  path_traversal: {
    pattern: '../',
    metric: "PathTraversalAttempts"
  },
  command_injection: {
    pattern: '; rm -rf',
    metric: "CommandInjectionAttempts"
  }
}

security_patterns.each do |attack_type, config|
  aws_cloudwatch_log_metric_filter(:"security_#{attack_type}", {
    name: "security-#{attack_type.to_s.gsub('_', '-')}",
    log_group_name: waf_logs.name,
    pattern: config[:pattern],
    metric_transformation: {
      name: config[:metric],
      namespace: "Security/Attacks",
      value: "1",
      default_value: 0,
      dimensions: {
        AttackType: attack_type.to_s.upcase,
        Severity: "CRITICAL"
      }
    }
  })
end

# Aggregate security score
security_score_filter = aws_cloudwatch_log_metric_filter(:security_score, {
  name: "security-risk-score",
  log_group_name: security_aggregator.name,
  pattern: '{ $.risk_score > 0 }',
  metric_transformation: {
    name: "SecurityRiskScore",
    namespace: "Security/RiskManagement",
    value: "$.risk_score",
    dimensions: {
      Service: "$.service",
      Environment: "$.environment"
    }
  }
})
```

### 3. Business Metrics Extraction

Extract business KPIs from application logs:

```ruby
# Order processing metrics
order_metrics = aws_cloudwatch_log_metric_filter(:order_processing, {
  name: "order-processing-metrics",
  log_group_name: order_service_logs.name,
  pattern: '{ $.event_type = "ORDER_PROCESSED" }',
  metric_transformation: {
    name: "OrderValue",
    namespace: "Business/Orders",
    value: "$.order_total",
    unit: "None",
    dimensions: {
      Currency: "$.currency",
      PaymentMethod: "$.payment_method",
      CustomerTier: "$.customer_tier"
    }
  }
})

# Conversion funnel tracking
conversion_filter = aws_cloudwatch_log_metric_filter(:conversion_funnel, {
  name: "conversion-funnel-tracking",
  log_group_name: analytics_logs.name,
  pattern: '{ $.event = "FUNNEL_STEP" }',
  metric_transformation: {
    name: "FunnelConversion",
    namespace: "Business/Analytics",
    value: "1",
    dimensions: {
      Step: "$.step_name",
      Source: "$.traffic_source",
      Device: "$.device_type"
    }
  }
})
```

### 4. Cost Optimization Metrics

Track and optimize infrastructure costs:

```ruby
# Lambda execution cost tracking
lambda_cost_filter = aws_cloudwatch_log_metric_filter(:lambda_costs, {
  name: "lambda-execution-costs",
  log_group_name: "/aws/lambda/#{function_name}",
  pattern: '[START RequestId: request_id Version: version]',
  metric_transformation: {
    name: "ExecutionCount",
    namespace: "Cost/Lambda",
    value: "1",
    dimensions: {
      FunctionName: function_name,
      Version: "$version"
    }
  }
})

# Database query cost estimation
db_cost_filter = aws_cloudwatch_log_metric_filter(:database_costs, {
  name: "expensive-database-queries",
  log_group_name: db_logs.name,
  pattern: '{ $.query_cost > 10 }',
  metric_transformation: {
    name: "ExpensiveQueryCost",
    namespace: "Cost/Database",
    value: "$.query_cost",
    dimensions: {
      QueryType: "$.query_type",
      Table: "$.primary_table"
    }
  }
})
```

## Pattern Language Deep Dive

### Space-Delimited Patterns

```ruby
# Basic format: [field1, field2, field3, ...]
# With conditions: [field1, field2=value, field3>100, ...]
# With wildcards: [field1, field2=prefix*, ..., field_n]

# Complex example with multiple conditions
complex_filter = aws_cloudwatch_log_metric_filter(:complex_space, {
  name: "complex-space-delimited",
  log_group_name: logs.name,
  pattern: '[timestamp, ip, user, latency>100, status=5*, size, ..., trace_id]',
  metric_transformation: {
    name: "SlowErrors",
    namespace: "Application/Issues",
    value: "$latency",
    dimensions: {
      User: "$user",
      StatusCode: "$status",
      TraceId: "$trace_id"
    }
  }
})
```

### JSON Pattern Expressions

```ruby
# Comparison operators: =, !=, <, <=, >, >=
# Logical operators: &&, ||
# Existence check: EXISTS($.field)
# Regex: $.field = /pattern/

# Advanced JSON filtering
advanced_json = aws_cloudwatch_log_metric_filter(:json_advanced, {
  name: "advanced-json-filtering",
  log_group_name: logs.name,
  pattern: '{ ($.severity = "ERROR" || $.severity = "CRITICAL") && $.response_time > 1000 && EXISTS($.user_id) }',
  metric_transformation: {
    name: "CriticalSlowRequests",
    namespace: "Application/Performance",
    value: "$.response_time",
    dimensions: {
      Severity: "$.severity",
      Endpoint: "$.endpoint",
      UserId: "$.user_id"
    }
  }
})
```

## Performance Optimization

### Metric Cardinality Management

```ruby
# High cardinality - be careful with costs
high_cardinality = aws_cloudwatch_log_metric_filter(:high_cardinality, {
  name: "user-specific-metrics",
  log_group_name: logs.name,
  pattern: '{ $.event = "USER_ACTION" }',
  metric_transformation: {
    name: "UserActions",
    namespace: "Application/Users",
    value: "1",
    dimensions: {
      UserId: "$.user_id",        # Potentially millions of values
      Action: "$.action",          # Dozens of values
      Timestamp: "$.timestamp"     # Infinite values - DON'T DO THIS
    }
  }
})

# Better approach - controlled cardinality
controlled_cardinality = aws_cloudwatch_log_metric_filter(:controlled_cardinality, {
  name: "user-segment-metrics",
  log_group_name: logs.name,
  pattern: '{ $.event = "USER_ACTION" }',
  metric_transformation: {
    name: "UserSegmentActions",
    namespace: "Application/UserSegments",
    value: "1",
    dimensions: {
      UserSegment: "$.user_segment",  # Limited values (e.g., "free", "pro", "enterprise")
      ActionCategory: "$.action_category",  # Grouped actions
      Region: "$.region"  # Limited geographic regions
    }
  }
})
```

### Pattern Performance Tips

1. **Specific Patterns First**: More specific patterns filter faster
2. **Avoid Regex When Possible**: Exact matches are faster
3. **Limit JSON Depth**: Deep JSON traversal impacts performance
4. **Use Indexes**: Structure logs to enable efficient filtering

## Monitoring Strategy

### Layered Monitoring Approach

```ruby
# Layer 1: High-level health metrics
health_filter = aws_cloudwatch_log_metric_filter(:health_check, {
  name: "application-health",
  log_group_name: health_logs.name,
  pattern: '{ $.health_status != "healthy" }',
  metric_transformation: {
    name: "UnhealthyChecks",
    namespace: "Application/Health",
    value: "1"
  }
})

# Layer 2: Component-specific metrics
components = ['api', 'database', 'cache', 'queue']
components.each do |component|
  aws_cloudwatch_log_metric_filter(:"#{component}_health", {
    name: "#{component}-health-metrics",
    log_group_name: "/aws/application/#{component}",
    pattern: "{ $.component = \"#{component}\" && $.status = \"error\" }",
    metric_transformation: {
      name: "ComponentErrors",
      namespace: "Application/Components",
      value: "1",
      dimensions: {
        Component: component.upcase
      }
    }
  })
end

# Layer 3: Detailed diagnostics
diagnostic_filter = aws_cloudwatch_log_metric_filter(:diagnostics, {
  name: "detailed-diagnostics",
  log_group_name: diagnostic_logs.name,
  pattern: '{ $.level = "DEBUG" && $.category = "PERFORMANCE" }',
  metric_transformation: {
    name: "DiagnosticMetrics",
    namespace: "Application/Diagnostics",
    value: "$.metric_value",
    dimensions: {
      MetricType: "$.metric_type",
      Component: "$.component",
      Operation: "$.operation"
    }
  }
})
```

## Integration Patterns

### With EventBridge

```ruby
# Create metric filter for anomaly detection
anomaly_filter = aws_cloudwatch_log_metric_filter(:anomalies, {
  name: "anomaly-detection",
  log_group_name: ml_logs.name,
  pattern: '{ $.anomaly_score > 0.8 }',
  metric_transformation: {
    name: "AnomalyScore",
    namespace: "ML/Anomalies",
    value: "$.anomaly_score"
  }
})

# Create EventBridge rule triggered by metric
aws_eventbridge_rule(:anomaly_response, {
  name: "high-anomaly-score",
  event_pattern: jsonencode({
    source: ["aws.cloudwatch"],
    "detail-type": ["CloudWatch Alarm State Change"],
    detail: {
      alarmName: ["high-anomaly-score-alarm"]
    }
  })
})
```

### With Step Functions

```ruby
# Track workflow execution metrics
workflow_filter = aws_cloudwatch_log_metric_filter(:workflow_metrics, {
  name: "step-function-metrics",
  log_group_name: "/aws/vendedlogs/states/#{state_machine_name}",
  pattern: '{ $.type = "TaskFailed" }',
  metric_transformation: {
    name: "WorkflowFailures",
    namespace: "StepFunctions/Execution",
    value: "1",
    dimensions: {
      StateMachine: state_machine_name,
      TaskName: "$.taskName",
      ErrorType: "$.error"
    }
  }
})
```

## Best Practices

### Design Principles

1. **Start Simple**: Begin with basic patterns and evolve
2. **Test Thoroughly**: Use CloudWatch Logs Insights for pattern testing
3. **Monitor Costs**: Track metric count and dimension cardinality
4. **Document Patterns**: Maintain pattern documentation with examples
5. **Version Control**: Track pattern changes over time

### Anti-Patterns to Avoid

1. **Unbounded Dimensions**: Don't use timestamps or IDs as dimensions
2. **Over-Extraction**: Don't create metrics for every log field
3. **Complex Patterns**: Keep patterns readable and maintainable
4. **Missing Defaults**: Always set default_value for sporadic metrics

## Future Enhancements

### Planned Features

1. **Pattern Builder DSL**: Ruby DSL for complex pattern construction
2. **Metric Aggregation**: Built-in aggregation before publishing
3. **Pattern Libraries**: Reusable pattern templates
4. **Cost Estimator**: Predict metric costs based on patterns

### Extension Points

The current implementation provides extension points for:
- Custom pattern validators
- Metric transformation pipelines
- Dimension enrichment
- Pattern optimization algorithms