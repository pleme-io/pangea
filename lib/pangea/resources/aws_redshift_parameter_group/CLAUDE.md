# AWS Redshift Parameter Group - Technical Documentation

## Architecture Overview

AWS Redshift Parameter Groups provide centralized configuration management for Redshift clusters. They control critical aspects like workload management (WLM), query monitoring, concurrency scaling, and security settings.

### Key Concepts

1. **Workload Management (WLM)**: Queue-based query routing and resource allocation
2. **Query Monitoring Rules**: Automated query governance and control
3. **Concurrency Scaling**: Elastic cluster capacity for burst workloads
4. **Performance Tuning**: Cache, analyze, and optimization parameters

## Implementation Details

### Type Safety with Dry::Struct

The `RedshiftParameterGroupAttributes` class provides validation:

```ruby
# Name validation
- Must start with lowercase letter
- Only lowercase letters, numbers, hyphens
- Maximum 255 characters

# Parameter validation
- Parameter names must be lowercase with underscores
- Values must be strings (converted from other types)
- Known parameter names are validated
```

### Resource Outputs

The resource returns:
- `id` - Parameter group ID
- `name` - Parameter group name
- `arn` - Parameter group ARN

### Computed Properties

1. **Configuration Status**
   - `has_wlm_configuration?` - WLM configured
   - `query_monitoring_enabled?` - Monitoring active
   - `result_caching_enabled?` - Cache enabled
   - `concurrency_scaling_enabled?` - Scaling active
   - `auto_analyze_enabled?` - Auto stats enabled

2. **Performance Metrics**
   - `concurrency_scaling_limit` - Max scaling clusters
   - `performance_impact_score` - Performance estimate

## Advanced Features

### Workload Management (WLM) Configuration

WLM divides cluster memory into queues for different workloads:

```ruby
# Complex WLM setup
wlm_queues = [
  {
    name: "superuser",
    memory_percent: 5,
    user_group: ["admin"],
    priority: "highest"
  },
  {
    name: "etl",
    memory_percent: 40,
    timeout_ms: 0, # No timeout
    user_group: ["etl_users"],
    priority: "high"
  },
  {
    name: "analytics",
    memory_percent: 30,
    timeout_ms: 600000, # 10 minutes
    query_group_wild_card: 1,
    priority: "normal"
  },
  {
    name: "reporting",
    memory_percent: 20,
    timeout_ms: 300000, # 5 minutes
    priority: "low"
  },
  {
    name: "default",
    memory_percent: 5,
    timeout_ms: 120000 # 2 minutes
  }
]

wlm_param = RedshiftParameterGroupAttributes.wlm_configuration(wlm_queues)
```

### Query Monitoring Rules

Automated query governance:

```ruby
# Comprehensive monitoring rules
monitoring_rules = [
  {
    name: "abort_expensive_queries",
    conditions: [
      { "query_cpu_usage_percent": { ">": 80 } },
      { "query_execution_time": { ">": 1800 } }
    ],
    action: "abort",
    priority: 1
  },
  {
    name: "log_high_io_queries",
    conditions: [
      { "query_blocks_read": { ">": 1000000 } }
    ],
    action: "log",
    priority: 2
  },
  {
    name: "hop_short_queries",
    conditions: [
      { "query_execution_time": { "<": 10 } }
    ],
    action: "hop", # Move to next queue
    priority: 3
  }
]

rules_param = RedshiftParameterGroupAttributes.query_monitoring_rules(monitoring_rules)
```

## Best Practices

### 1. Workload Isolation

```ruby
# Separate parameter groups per workload
aws_redshift_parameter_group(:etl_isolated, {
  name: "etl-isolated-params",
  parameters: [
    RedshiftParameterGroupAttributes.wlm_configuration([
      { name: "etl_critical", memory_percent: 70, timeout_ms: 0 },
      { name: "etl_standard", memory_percent: 25, timeout_ms: 0 },
      { name: "default", memory_percent: 5 }
    ]),
    { name: "max_concurrency_scaling_clusters", value: "1" },
    { name: "statement_timeout", value: "0" }
  ]
})
```

### 2. Security Hardening

```ruby
# Security-focused configuration
aws_redshift_parameter_group(:hardened, {
  name: "security-hardened",
  parameters: [
    { name: "require_ssl", value: "true" },
    { name: "use_fips_ssl", value: "true" },
    { name: "enable_user_activity_logging", value: "true" },
    { name: "enable_query_logging", value: "true" },
    { name: "enable_case_sensitive_identifier", value: "true" },
    { name: "force_acl", value: "true" }
  ],
  tags: {
    SecurityProfile: "hardened",
    ComplianceRequired: "true"
  }
})
```

### 3. Performance Optimization

```ruby
# Performance-tuned parameters
aws_redshift_parameter_group(:performance, {
  name: "high-performance",
  parameters: [
    # Concurrency scaling for burst capacity
    { name: "max_concurrency_scaling_clusters", value: "10" },
    
    # Result caching for repeated queries
    { name: "enable_result_cache_for_session", value: "true" },
    
    # Automatic table analysis
    { name: "auto_analyze", value: "true" },
    { name: "analyze_threshold_percent", value: "10" },
    
    # Query optimization
    { name: "enable_hypopg", value: "true" },
    { name: "nested_loop_join", value: "on" },
    
    # Memory settings
    { name: "statement_mem", value: "256MB" }
  ]
})
```

## Common Patterns

### 1. Environment-Specific Parameters

```ruby
environments = {
  dev: { concurrency: "0", timeout: "300000", logging: "false" },
  staging: { concurrency: "1", timeout: "600000", logging: "true" },
  prod: { concurrency: "5", timeout: "0", logging: "true" }
}

environments.each do |env, settings|
  aws_redshift_parameter_group(:"#{env}_params", {
    name: "#{env}-parameters",
    parameters: [
      { name: "max_concurrency_scaling_clusters", value: settings[:concurrency] },
      { name: "statement_timeout", value: settings[:timeout] },
      { name: "enable_user_activity_logging", value: settings[:logging] }
    ],
    tags: { Environment: env.to_s }
  })
end
```

### 2. Compliance Profiles

```ruby
compliance_profiles = {
  hipaa: [
    { name: "require_ssl", value: "true" },
    { name: "use_fips_ssl", value: "true" },
    { name: "enable_user_activity_logging", value: "true" },
    { name: "enable_audit_logging", value: "true" }
  ],
  pci: [
    { name: "require_ssl", value: "true" },
    { name: "enable_user_activity_logging", value: "true" },
    { name: "force_acl", value: "true" },
    { name: "enable_query_logging", value: "true" }
  ]
}

compliance_profiles.each do |profile, params|
  aws_redshift_parameter_group(:"#{profile}_compliant", {
    name: "#{profile}-compliant",
    parameters: params,
    tags: {
      Compliance: profile.to_s.upcase,
      Audited: "true"
    }
  })
end
```

### 3. Time-Based Configurations

```ruby
# Business hours vs off-hours settings
aws_redshift_parameter_group(:business_hours, {
  name: "business-hours-params",
  parameters: [
    { name: "max_concurrency_scaling_clusters", value: "5" },
    { name: "statement_timeout", value: "300000" } # 5 min timeout
  ]
})

aws_redshift_parameter_group(:off_hours, {
  name: "off-hours-params",
  parameters: [
    { name: "max_concurrency_scaling_clusters", value: "0" },
    { name: "statement_timeout", value: "0" } # No timeout for batch
  ]
})
```

## Integration Examples

### With Redshift Clusters

```ruby
# Create optimized parameter group
param_group_ref = aws_redshift_parameter_group(:analytics_optimized, {
  name: "analytics-optimized",
  parameters: RedshiftParameterGroupAttributes.parameters_for_workload(:analytics)
})

# Apply to cluster
aws_redshift_cluster(:analytics_cluster, {
  cluster_identifier: "analytics-cluster",
  cluster_parameter_group_name: param_group_ref.outputs[:name],
  node_type: "ra3.4xlarge",
  number_of_nodes: 3
})
```

### Dynamic Parameter Updates

```ruby
# Parameter group for A/B testing configurations
aws_redshift_parameter_group(:ab_test, {
  name: "ab-test-params",
  parameters: [
    { name: "enable_result_cache_for_session", value: ENV['ENABLE_CACHE'] || "true" },
    { name: "max_concurrency_scaling_clusters", value: ENV['MAX_SCALING'] || "2" }
  ],
  tags: {
    TestGroup: ENV['TEST_GROUP'] || "control"
  }
})
```

## Troubleshooting

### Common Issues

1. **WLM Queue Starvation**
   - Check memory allocation percentages
   - Verify queue priorities
   - Monitor queue wait times

2. **Query Timeout Issues**
   - Review statement_timeout settings
   - Check WLM queue timeouts
   - Analyze long-running queries

3. **Concurrency Scaling Costs**
   - Monitor scaling cluster usage
   - Set appropriate limits
   - Use query monitoring rules

## Performance Impact Analysis

### Parameter Effects on Performance

```ruby
# Performance impact calculation
def calculate_performance_impact(parameters)
  impact = 1.0
  
  # Positive impacts
  impact *= 1.3 if parameters.include?({ name: "enable_result_cache_for_session", value: "true" })
  impact *= 1.2 if parameters.include?({ name: "auto_analyze", value: "true" })
  impact *= 1.4 if parameters.any? { |p| p[:name] == "max_concurrency_scaling_clusters" && p[:value].to_i > 0 }
  
  # Negative impacts
  impact *= 0.9 if parameters.include?({ name: "enable_user_activity_logging", value: "true" })
  impact *= 0.95 if parameters.include?({ name: "use_fips_ssl", value: "true" })
  
  impact
end
```