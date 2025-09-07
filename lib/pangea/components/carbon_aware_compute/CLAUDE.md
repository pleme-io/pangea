# Carbon Aware Compute - Architecture Documentation

## Component Purpose

The Carbon Aware Compute component represents a paradigm shift in cloud computing sustainability. It transforms traditional "always-on" or "schedule-only" workload execution into an intelligent system that considers the environmental impact of computational work. By integrating real-time carbon intensity data with workload scheduling, this component enables organizations to reduce their carbon footprint without sacrificing functionality.

## Architecture Decisions

### 1. Serverless-First Architecture

**Decision**: Use Lambda functions for all compute operations rather than persistent EC2 instances or containers.

**Rationale**: 
- Zero idle emissions - functions only consume energy when executing
- Automatic scaling eliminates over-provisioning
- Reduced operational overhead allows focus on optimization logic
- Native integration with EventBridge for scheduling

**Trade-offs**:
- 15-minute execution limit requires workload chunking
- Cold starts may impact time-sensitive workloads
- Limited to Lambda-compatible runtimes

### 2. DynamoDB for State Management

**Decision**: Use DynamoDB for workload queue and carbon data caching.

**Rationale**:
- Serverless, eliminating always-on database instances
- Pay-per-request pricing aligns with sustainability goals
- Built-in TTL for automatic data lifecycle management
- Global secondary indexes enable efficient queries

**Trade-offs**:
- Eventually consistent reads may cause slight delays
- Limited query flexibility compared to SQL databases
- Requires careful partition key design

### 3. Multi-Strategy Optimization

**Decision**: Support time-shifting, location-shifting, and combined strategies.

**Rationale**:
- Different workloads have different flexibility constraints
- Maximizes carbon reduction opportunities
- Allows gradual adoption (start with time-shifting only)
- Future-proof as more regions become renewable

**Implementation**:
- Strategy pattern for optimization algorithms
- Pluggable scoring functions for different approaches
- Configurable weights for carbon vs. cost optimization

### 4. Real-Time Carbon Data Integration

**Decision**: Cache external carbon intensity data with 15-minute refresh.

**Rationale**:
- Grid carbon intensity changes throughout the day
- External APIs have rate limits and latency
- 15-minute cache balances freshness with API costs
- Fallback to historical patterns if API fails

**Data Sources**:
- Primary: Electricity Maps API (requires subscription)
- Secondary: WattTime API (marginal emissions)
- Fallback: Historical regional patterns

### 5. Graviton and Spot Instance Defaults

**Decision**: Enable ARM processors and spot instances by default.

**Rationale**:
- Graviton provides 20% better energy efficiency
- Spot instances use excess capacity (already provisioned)
- Both reduce cost and carbon footprint
- Can be disabled for compatibility

**Implementation**:
- Architecture-aware Lambda deployment
- Spot instance integration for long-running workloads
- Automatic fallback to on-demand if needed

## Security Architecture

### 1. Least Privilege IAM

Each Lambda function has minimal required permissions:
- Scheduler: Read/write DynamoDB, invoke executor
- Executor: Read/write specific DynamoDB items, emit metrics
- Monitor: Read carbon APIs, write cache, emit metrics

### 2. VPC Integration

- Functions deploy into customer VPC for network isolation
- Security groups restrict outbound to required services
- VPC endpoints eliminate internet gateway requirements

### 3. Encryption

- All data encrypted at rest (DynamoDB, CloudWatch Logs)
- TLS for all API communications
- KMS integration for sensitive workload data

## Scalability Patterns

### 1. Horizontal Scaling

- Lambda concurrency scales automatically
- DynamoDB on-demand handles any workload
- Regional distribution reduces single-region load

### 2. Workload Batching

- Small workloads grouped for efficiency
- Reduces Lambda invocation overhead
- Improves carbon calculations accuracy

### 3. Multi-Region Architecture

- Each region operates independently
- Cross-region replication for global workloads
- Regional carbon data caching reduces API calls

## Cost Optimization

### 1. Intelligent Resource Allocation

- Right-sized Lambda memory based on workload type
- Automatic adjustment based on execution patterns
- Spot instance bidding for cost reduction

### 2. Efficient Scheduling

- Batch similar workloads together
- Minimize Lambda cold starts
- Use EventBridge for cost-effective scheduling

### 3. Data Lifecycle

- Automatic TTL on temporary data
- Compressed storage for historical metrics
- Tiered storage for long-term analytics

## Monitoring Strategy

### 1. Carbon Metrics

Primary metrics tracked:
- **Carbon Intensity**: Real-time grid carbon per region
- **Carbon Emissions**: Actual gCO2eq per workload
- **Carbon Saved**: Compared to baseline execution
- **Renewable Percentage**: Clean energy usage

### 2. Operational Metrics

- **Workload Queue Depth**: Pending executions
- **Execution Latency**: Time from schedule to completion
- **Success Rate**: Successful vs. failed executions
- **Cost Savings**: From optimization strategies

### 3. Dashboards

Automated CloudWatch dashboard includes:
- Regional carbon intensity heatmap
- Workload execution timeline
- Carbon savings accumulator
- Cost optimization tracker

## Integration Patterns

### 1. Event-Driven Integration

```ruby
# Trigger carbon-aware execution from S3 upload
s3_trigger = aws_s3_bucket_notification(bucket, {
  lambda_function_arn: carbon_compute.executor_function.arn,
  events: ["s3:ObjectCreated:*"],
  filter_prefix: "input/"
})
```

### 2. API Gateway Integration

```ruby
# REST API for workload submission
api = aws_api_gateway_rest_api(:carbon_api, {
  name: "carbon-aware-workload-api"
})

aws_api_gateway_integration(api, {
  integration_type: "AWS_PROXY",
  uri: carbon_compute.scheduler_function.invoke_arn
})
```

### 3. Step Functions Integration

```ruby
# Complex workflows with carbon awareness
workflow = aws_stepfunctions_state_machine(:carbon_workflow, {
  definition: {
    StartAt: "CheckCarbon",
    States: {
      CheckCarbon: {
        Type: "Task",
        Resource: carbon_compute.monitor_function.arn,
        Next: "DecideExecution"
      },
      DecideExecution: {
        Type: "Choice",
        Choices: [{
          Variable: "$.carbonIntensity",
          NumericLessThan: 150,
          Next: "ExecuteNow"
        }],
        Default: "ScheduleLater"
      }
    }
  }
})
```

## Future Enhancements

### 1. Machine Learning Integration

- Predict future carbon intensity patterns
- Optimize scheduling based on historical data
- Anomaly detection for unusual grid conditions

### 2. Multicloud Support

- Extend to Azure and GCP regions
- Unified carbon tracking across clouds
- Workload migration between cloud providers

### 3. Carbon Credit Integration

- Automatic carbon offset purchasing
- Renewable energy certificate tracking
- Sustainability reporting automation

### 4. Enhanced Data Sources

- Direct utility API integration
- Real-time renewable energy data
- Weather-based predictions

## Performance Characteristics

### 1. Latency

- Scheduling decision: < 100ms
- Carbon data fetch: < 500ms (cached)
- Workload startup: 1-5 seconds (cold start)

### 2. Throughput

- Scheduler: 1000+ workloads/second
- Executor: Limited by Lambda concurrency
- Monitor: Updates all regions in < 30 seconds

### 3. Reliability

- 99.9% uptime (Lambda SLA)
- Automatic retry with exponential backoff
- Dead letter queues for failed workloads

## Deployment Considerations

### 1. Regional Deployment

Deploy in regions with:
- Low baseline carbon intensity
- Good renewable energy availability
- Low latency to workload data

### 2. Compliance

Consider:
- Data residency requirements
- Workload sensitivity to delays
- Audit trail requirements

### 3. Migration Strategy

1. Start with non-critical batch workloads
2. Monitor carbon savings and performance
3. Gradually expand to more workload types
4. Implement organization-wide standards

## Conclusion

The Carbon Aware Compute component demonstrates that sustainability and performance are not mutually exclusive. By intelligently scheduling workloads based on grid carbon intensity, organizations can significantly reduce their environmental impact while often reducing costs. The serverless architecture ensures the solution itself maintains minimal carbon footprint, creating a truly sustainable approach to cloud computing.