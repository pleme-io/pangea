# Microservice Deployment Component

Production-ready ECS microservice deployment with service discovery, circuit breakers, and distributed tracing.

## Overview

The `microservice_deployment` component creates a complete microservice deployment on AWS ECS with enterprise-grade features including:

- **ECS Fargate Service**: Serverless container execution with automatic scaling
- **Service Discovery**: AWS Cloud Map integration for service-to-service communication
- **Circuit Breakers**: Deployment circuit breakers for automatic rollback on failures
- **Distributed Tracing**: X-Ray, Jaeger, or Zipkin integration for observability
- **Auto-scaling**: CPU and memory-based automatic scaling policies
- **Health Checks**: Comprehensive health monitoring with CloudWatch alarms
- **Blue-Green Deployments**: Support for zero-downtime deployments

## Usage

### Basic Microservice

```ruby
# Create a simple microservice deployment
service = microservice_deployment(:user_service, {
  cluster_ref: ecs_cluster_ref,
  task_definition_family: "user-service",
  container_definitions: [{
    name: "user-api",
    image: "myapp/user-service:latest",
    cpu: 512,
    memory: 1024,
    port_mappings: [{
      containerPort: 8080,
      protocol: "tcp"
    }],
    environment: [
      { name: "NODE_ENV", value: "production" },
      { name: "PORT", value: "8080" }
    ]
  }],
  vpc_ref: vpc_ref,
  subnet_refs: [private_subnet_a_ref, private_subnet_b_ref],
  security_group_refs: [service_sg_ref],
  target_group_refs: [user_service_tg_ref]
})
```

### Microservice with Service Discovery

```ruby
# Create a microservice with service discovery for internal communication
order_service = microservice_deployment(:order_service, {
  cluster_ref: ecs_cluster_ref,
  task_definition_family: "order-service",
  container_definitions: [{
    name: "order-api",
    image: "myapp/order-service:latest",
    cpu: 1024,
    memory: 2048,
    port_mappings: [{
      containerPort: 3000,
      protocol: "tcp"
    }],
    environment: [
      { name: "USER_SERVICE_ENDPOINT", value: "user-service.local:8080" }
    ],
    health_check: {
      command: ["CMD-SHELL", "curl -f http://localhost:3000/health || exit 1"],
      interval: 30,
      timeout: 5,
      retries: 3,
      startPeriod: 60
    }
  }],
  vpc_ref: vpc_ref,
  subnet_refs: [private_subnet_a_ref, private_subnet_b_ref],
  security_group_refs: [service_sg_ref],
  
  # Service discovery configuration
  service_discovery: {
    namespace_id: service_discovery_namespace_ref.id,
    service_name: "order-service",
    dns_config: {
      routing_policy: "MULTIVALUE",
      dns_records: [{
        type: "A",
        ttl: 60
      }]
    }
  },
  
  # Enable auto-scaling
  auto_scaling: {
    enabled: true,
    min_tasks: 2,
    max_tasks: 10,
    target_cpu: 70.0,
    target_memory: 80.0
  }
})
```

### Event-Driven Microservice with Tracing

```ruby
# Create an event-driven microservice with distributed tracing
payment_service = microservice_deployment(:payment_service, {
  cluster_ref: ecs_cluster_ref,
  task_definition_family: "payment-service",
  task_cpu: "1024",
  task_memory: "2048",
  
  container_definitions: [{
    name: "payment-processor",
    image: "myapp/payment-service:latest",
    cpu: 896,  # Leave room for X-Ray sidecar
    memory: 1792,
    port_mappings: [{
      containerPort: 8000,
      protocol: "tcp"
    }],
    environment: [
      { name: "STRIPE_WEBHOOK_ENDPOINT", value: "/webhooks/stripe" },
      { name: "SQS_QUEUE_URL", value: payment_queue_ref.id }
    ],
    secrets: [
      { name: "STRIPE_API_KEY", valueFrom: stripe_secret_ref.arn },
      { name: "DATABASE_URL", valueFrom: db_url_secret_ref.arn }
    ]
  }],
  
  vpc_ref: vpc_ref,
  subnet_refs: [private_subnet_a_ref, private_subnet_b_ref],
  security_group_refs: [service_sg_ref],
  target_group_refs: [payment_service_tg_ref],
  
  # Enable distributed tracing
  tracing: {
    enabled: true,
    sampling_rate: 0.1,  # Sample 10% of requests
    x_ray: true
  },
  
  # Circuit breaker configuration
  circuit_breaker: {
    enabled: true,
    threshold: 5,
    timeout: 60,
    rollback: true
  },
  
  # Health check configuration
  health_check: {
    path: "/health",
    interval: 30,
    timeout: 5,
    healthy_threshold: 2,
    unhealthy_threshold: 3,
    matcher: "200"
  }
})
```

### Multi-Container Microservice

```ruby
# Create a microservice with multiple containers (main app + sidecar)
analytics_service = microservice_deployment(:analytics_service, {
  cluster_ref: ecs_cluster_ref,
  task_definition_family: "analytics-service",
  task_cpu: "2048",
  task_memory: "4096",
  
  container_definitions: [
    {
      name: "analytics-api",
      image: "myapp/analytics-api:latest",
      cpu: 1536,
      memory: 3072,
      essential: true,
      port_mappings: [{
        containerPort: 5000,
        protocol: "tcp"
      }],
      depends_on: [{
        containerName: "envoy-proxy",
        condition: "HEALTHY"
      }]
    },
    {
      name: "envoy-proxy",
      image: "envoyproxy/envoy:latest",
      cpu: 512,
      memory: 1024,
      essential: true,
      port_mappings: [
        { containerPort: 9901, protocol: "tcp" },  # Admin
        { containerPort: 15000, protocol: "tcp" }  # Ingress
      ],
      health_check: {
        command: ["CMD-SHELL", "curl -f http://localhost:9901/clusters || exit 1"],
        interval: 30,
        timeout: 5,
        retries: 3
      }
    }
  ],
  
  vpc_ref: vpc_ref,
  subnet_refs: [private_subnet_a_ref, private_subnet_b_ref],
  security_group_refs: [service_sg_ref],
  container_name: "envoy-proxy",  # Route traffic through Envoy
  container_port: 15000,
  target_group_refs: [analytics_service_tg_ref],
  
  # Enable blue-green deployment
  enable_blue_green: true,
  deployment_minimum_healthy_percent: 100,
  deployment_maximum_percent: 200
})
```

## Inputs

### Required Inputs

- `cluster_ref`: Reference to the ECS cluster for deployment
- `task_definition_family`: Name for the task definition family
- `container_definitions`: Array of container configurations
- `vpc_ref`: Reference to the VPC
- `subnet_refs`: Array of subnet references (minimum 2 for HA)

### Optional Inputs

- `security_group_refs`: Security groups for the service (default: [])
- `assign_public_ip`: Assign public IPs to tasks (default: false)
- `desired_count`: Number of tasks to run (default: 2)
- `launch_type`: ECS launch type - FARGATE or EC2 (default: "FARGATE")
- `task_cpu`: Task CPU units (default: "256")
- `task_memory`: Task memory in MB (default: "512")
- `target_group_refs`: Target groups for load balancing (default: [])
- `service_discovery`: Service discovery configuration (optional)
- `circuit_breaker`: Circuit breaker configuration
- `auto_scaling`: Auto-scaling configuration
- `tracing`: Distributed tracing configuration
- `health_check`: Health check configuration
- `enable_blue_green`: Enable blue-green deployments (default: false)
- `log_retention_days`: CloudWatch log retention (default: 7)

### Container Definition Structure

```ruby
{
  name: "container-name",
  image: "docker-image:tag",
  cpu: 256,                    # CPU units
  memory: 512,                 # Memory in MB
  essential: true,             # Is this container essential?
  port_mappings: [...],        # Port mappings
  environment: [...],          # Environment variables
  secrets: [...],              # Secrets from Parameter Store/Secrets Manager
  health_check: {...},         # Container health check
  depends_on: [...],           # Container dependencies
  log_configuration: {...}     # Custom logging config (optional)
}
```

## Outputs

The component returns a `ComponentReference` with:

- `service_name`: Name of the ECS service
- `service_arn`: ARN of the ECS service
- `task_definition_arn`: ARN of the task definition
- `cluster_name`: Name of the ECS cluster
- `service_discovery_endpoint`: Service discovery endpoint (if configured)
- `resilience_features`: List of enabled resilience features
- `monitoring_features`: List of enabled monitoring features
- `estimated_monthly_cost`: Estimated AWS costs

## Resources Created

- `aws_cloudwatch_log_group`: CloudWatch log group for container logs
- `aws_cloudwatch_log_stream`: Log streams for each container
- `aws_ecs_task_definition`: Task definition with containers
- `aws_ecs_service`: ECS service with deployment configuration
- `aws_service_discovery_service`: Service discovery registration (optional)
- `aws_appautoscaling_target`: Auto-scaling target (optional)
- `aws_appautoscaling_policy`: CPU and memory scaling policies (optional)
- `aws_cloudwatch_metric_alarm`: Monitoring alarms
- `aws_xray_sampling_rule`: X-Ray sampling configuration (optional)

## Best Practices

1. **Container Configuration**
   - Use specific image tags, not `latest`
   - Set appropriate CPU and memory limits
   - Define health checks for all containers
   - Use secrets for sensitive configuration

2. **Networking**
   - Deploy across multiple availability zones
   - Use private subnets for services
   - Configure security groups with least privilege

3. **Resilience**
   - Enable circuit breakers for automatic rollback
   - Configure appropriate health check grace periods
   - Set deployment percentages for rolling updates
   - Use auto-scaling for dynamic workloads

4. **Observability**
   - Enable distributed tracing for debugging
   - Set appropriate log retention periods
   - Configure CloudWatch alarms for key metrics
   - Use structured logging in containers

5. **Cost Optimization**
   - Right-size CPU and memory allocations
   - Use Fargate Spot for non-critical workloads
   - Configure auto-scaling to match demand
   - Review and adjust log retention policies