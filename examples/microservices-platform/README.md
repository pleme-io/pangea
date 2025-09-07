# Microservices Platform Infrastructure

This example demonstrates a complete microservices platform using Pangea, showcasing how to build a scalable, event-driven architecture with container orchestration, service mesh, and unified API management.

## Overview

The microservices platform includes:

- **Container Orchestration**: ECS Fargate with automatic scaling and service discovery
- **Service Mesh**: AWS App Mesh for service-to-service communication and observability
- **Event-Driven Architecture**: SNS/SQS for asynchronous messaging between services
- **API Gateway**: Unified API management with rate limiting and monitoring
- **Multi-AZ Deployment**: High availability across multiple availability zones
- **Security**: VPC isolation, KMS encryption, and least-privilege IAM policies

## Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                           Internet                                   │
└────────────────────┬────────────────────────────────────────────────┘
                     │
                     ▼
           ┌─────────────────┐
           │  API Gateway    │
           │  (HTTP API)     │
           └────────┬────────┘
                    │ VPC Link
                    ▼
┌─────────────────────────────────────────────────────────────────────┐
│                           VPC (10.0.0.0/16)                         │
│                                                                      │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │                    Public Subnets (ALB)                       │  │
│  └─────────────────────────────────────────────────────────────┘  │
│                                                                      │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │                   Private Subnets (Services)                  │  │
│  │                                                               │  │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │  │
│  │  │ User Service │  │Order Service │  │Payment Svc   │      │  │
│  │  │  (ECS Task)  │  │  (ECS Task)  │  │  (ECS Task)  │      │  │
│  │  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘      │  │
│  │         │                  │                  │              │  │
│  │         └──────────────────┴──────────────────┘              │  │
│  │                            │                                  │  │
│  │                    ┌───────▼────────┐                        │  │
│  │                    │   App Mesh     │                        │  │
│  │                    │ Service Mesh   │                        │  │
│  │                    └───────┬────────┘                        │  │
│  │                            │                                  │  │
│  │         ┌──────────────────┴──────────────────┐              │  │
│  │         │                                      │              │  │
│  │  ┌──────▼───────┐                      ┌──────▼───────┐     │  │
│  │  │  SNS Topics  │                      │ EventBridge  │     │  │
│  │  │              │                      │              │     │  │
│  │  └──────┬───────┘                      └──────────────┘     │  │
│  │         │                                                    │  │
│  │  ┌──────▼───────┐                                           │  │
│  │  │  SQS Queues  │                                           │  │
│  │  │    + DLQ     │                                           │  │
│  │  └──────────────┘                                           │  │
│  └─────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────┘
```

## Templates

### 1. Platform Infrastructure (`platform_infrastructure`)

Core platform components:
- VPC with public and private subnets across 3 AZs
- NAT Gateways for outbound internet access
- ECS cluster with Fargate capacity providers
- Service discovery namespace
- AWS App Mesh for service mesh capabilities
- CloudWatch log groups and KMS encryption

### 2. Messaging Infrastructure (`messaging_infrastructure`)

Event-driven communication layer:
- SNS topics for event publishing (user, order, payment events)
- SQS queues with dead letter queues for each service
- Topic subscriptions with message filtering
- EventBridge custom bus for advanced routing
- Queue policies for secure message delivery

### 3. API Gateway (`api_gateway`)

Unified API management:
- HTTP API Gateway for better performance
- VPC Link for private integration
- Service-specific routes and integrations
- Rate limiting and throttling
- Access logging and monitoring
- Optional custom domain support

## Deployment

### Prerequisites

1. AWS CLI configured with appropriate credentials
2. S3 buckets for Terraform state (staging/production)
3. DynamoDB tables for state locking (staging/production)

### Development Environment

```bash
# Deploy all templates to development
pangea apply infrastructure.rb

# Deploy individual templates
pangea apply infrastructure.rb --template platform_infrastructure
pangea apply infrastructure.rb --template messaging_infrastructure
pangea apply infrastructure.rb --template api_gateway
```

### Staging Environment

```bash
# Deploy to staging namespace
pangea apply infrastructure.rb --namespace staging

# Plan before applying
pangea plan infrastructure.rb --namespace staging --template platform_infrastructure
```

### Production Environment

```bash
# Deploy to production with manual approval
pangea apply infrastructure.rb --namespace production --no-auto-approve

# Deploy specific template
pangea apply infrastructure.rb --namespace production --template api_gateway
```

### Custom Domain Setup

To use a custom domain for the API Gateway:

```bash
export API_DOMAIN=api.example.com
pangea apply infrastructure.rb --template api_gateway
```

## Service Integration

### Adding a New Microservice

1. Create the ECS task definition and service
2. Register with service discovery
3. Add to App Mesh as a virtual node
4. Create SNS topic and SQS queue if needed
5. Add API Gateway route and integration

### Example Service Communication

```python
# Publishing an event from User Service
import boto3
import json

sns = boto3.client('sns')

def publish_user_created(user_id, user_data):
    message = {
        'event_type': 'user_created',
        'user_id': user_id,
        'data': user_data
    }
    
    sns.publish(
        TopicArn=os.environ['USER_EVENTS_TOPIC_ARN'],
        Message=json.dumps(message),
        MessageAttributes={
            'event_type': {
                'DataType': 'String',
                'StringValue': 'user_created'
            }
        }
    )
```

### Service Discovery

Services can discover each other using the private DNS namespace:

```python
# HTTP call to another service
import requests

response = requests.get('http://order-service.microservices.local:8080/orders/123')
```

## Monitoring and Observability

### CloudWatch Dashboards

Create custom dashboards to monitor:
- API Gateway request rates and latencies
- ECS service metrics (CPU, memory)
- SQS queue depths and message age
- SNS topic delivery rates

### X-Ray Tracing

Enable X-Ray for distributed tracing:
- API Gateway to service calls
- Service-to-service communication
- Asynchronous message processing

### Log Aggregation

All logs are sent to CloudWatch Log Groups:
- `/aws/ecs/microservices/exec` - ECS execution logs
- `/aws/microservices/platform` - Platform logs
- `/aws/apigateway/microservices-{namespace}` - API Gateway logs

## Security Best Practices

1. **Network Isolation**: Services run in private subnets
2. **Encryption**: KMS encryption for logs and sensitive data
3. **IAM Roles**: Least-privilege roles for each service
4. **Secrets Management**: Use AWS Secrets Manager or Parameter Store
5. **API Security**: Rate limiting and authentication at API Gateway

## Cost Optimization

1. **Fargate Spot**: Uses mix of regular and spot instances
2. **NAT Gateway**: One per AZ for cost efficiency
3. **Log Retention**: 30-day retention for cost management
4. **Auto Scaling**: Scale services based on demand

## Troubleshooting

### Common Issues

1. **Service Discovery Failures**
   - Check security group rules
   - Verify service is registered with discovery
   - Check App Mesh configuration

2. **Message Processing Issues**
   - Monitor DLQ for failed messages
   - Check IAM permissions for SNS/SQS
   - Verify message format and attributes

3. **API Gateway Errors**
   - Check VPC Link health
   - Verify integration URIs
   - Review CloudWatch logs

## Clean Up

Remove infrastructure in reverse order:

```bash
# Destroy API Gateway first
pangea destroy infrastructure.rb --template api_gateway

# Then messaging infrastructure
pangea destroy infrastructure.rb --template messaging_infrastructure

# Finally platform infrastructure
pangea destroy infrastructure.rb --template platform_infrastructure
```

## Next Steps

1. Implement actual microservices with business logic
2. Add authentication with Cognito or custom authorizer
3. Implement circuit breakers and retries
4. Set up CI/CD pipelines for service deployments
5. Add monitoring dashboards and alerts