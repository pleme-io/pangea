# API Gateway Microservices Component

API Gateway with multiple microservice integrations, advanced routing, rate limiting, versioning, and enterprise features.

## Overview

The `api_gateway_microservices` component creates a comprehensive API Gateway setup that serves as a unified entry point for multiple microservices with:

- **Multi-Service Integration**: Route requests to different backend microservices
- **Advanced Routing**: Path-based, header-based, or query-based routing strategies
- **Rate Limiting**: Throttling and quota management per API key
- **API Versioning**: Support for multiple API versions with different strategies
- **Request/Response Transformation**: Modify requests and responses between clients and services
- **CORS Handling**: Automatic CORS configuration with preflight support
- **Security Features**: WAF integration, API keys, custom authorizers
- **Observability**: X-Ray tracing, CloudWatch logging, and detailed metrics

## Usage

### Basic Multi-Service API Gateway

```ruby
# Create an API Gateway for multiple microservices
api_gateway = api_gateway_microservices(:platform_api, {
  api_name: "platform-api",
  api_description: "Unified API for platform microservices",
  stage_name: "prod",
  
  service_endpoints: [
    {
      name: "users",
      base_path: "users",
      methods: [
        { path: "/", method: "GET" },
        { path: "/", method: "POST" },
        { path: "/{id}", method: "GET" },
        { path: "/{id}", method: "PUT" },
        { path: "/{id}", method: "DELETE" }
      ],
      integration: {
        type: "HTTP_PROXY",
        uri: "https://users.internal.example.com/{proxy}",
        connection_type: "INTERNET"
      }
    },
    {
      name: "orders",
      base_path: "orders",
      methods: [
        { path: "/", method: "GET" },
        { path: "/", method: "POST" },
        { path: "/{id}", method: "GET" },
        { path: "/{id}/items", method: "GET" }
      ],
      integration: {
        type: "HTTP_PROXY",
        uri: "https://orders.internal.example.com/{proxy}",
        connection_type: "INTERNET"
      }
    }
  ]
})
```

### API Gateway with VPC Link Integration

```ruby
# Create API Gateway with private VPC Link to internal services
internal_api = api_gateway_microservices(:internal_api, {
  api_name: "internal-services-api",
  endpoint_type: "REGIONAL",
  
  service_endpoints: [
    {
      name: "inventory",
      base_path: "inventory",
      methods: [
        { 
          path: "/items",
          method: "GET",
          request_parameters: {
            "method.request.querystring.category" => false,
            "method.request.querystring.limit" => false
          }
        },
        {
          path: "/items/{sku}",
          method: "GET",
          request_parameters: {
            "method.request.path.sku" => true
          }
        }
      ],
      integration: {
        type: "HTTP_PROXY",
        uri: "http://internal-nlb.local/{proxy}",
        connection_type: "VPC_LINK"
      },
      vpc_link_ref: vpc_link_ref,
      nlb_ref: nlb_ref
    }
  ],
  
  # Enable caching for better performance
  cache_cluster_enabled: true,
  cache_cluster_size: "0.5",
  cache_ttl: 300
})
```

### API Gateway with Advanced Features

```ruby
# Create a feature-rich API Gateway
advanced_api = api_gateway_microservices(:enterprise_api, {
  api_name: "enterprise-api",
  api_description: "Enterprise API Gateway with full features",
  
  service_endpoints: [
    {
      name: "products",
      base_path: "products",
      methods: [
        {
          path: "/search",
          method: "POST",
          request_models: {
            "application/json" => search_model_ref.id
          },
          request_validator: "BODY"
        }
      ],
      integration: {
        type: "AWS_PROXY",
        uri: "arn:aws:apigateway:${AWS::Region}:lambda:path/2015-03-31/functions/${ProductsLambda.Arn}/invocations"
      },
      transformation: {
        request_templates: {
          "application/json" => <<~TEMPLATE
            {
              "body": $input.json('$'),
              "headers": {
                #foreach($header in $input.params().header.keySet())
                "$header": "$util.escapeJavaScript($input.params().header.get($header))"#if($foreach.hasNext),#end
                #end
              },
              "queryStringParameters": {
                #foreach($queryParam in $input.params().querystring.keySet())
                "$queryParam": "$util.escapeJavaScript($input.params().querystring.get($queryParam))"#if($foreach.hasNext),#end
                #end
              }
            }
          TEMPLATE
        }
      }
    },
    {
      name: "analytics",
      base_path: "analytics",
      methods: [
        {
          path: "/events",
          method: "POST",
          api_key_required: true
        }
      ],
      integration: {
        type: "AWS",
        uri: "arn:aws:apigateway:${AWS::Region}:kinesis:action/PutRecord"
      },
      rate_limit_override: {
        enabled: true,
        burst_limit: 10000,
        rate_limit: 50000.0
      }
    }
  ],
  
  # API Versioning
  versioning: {
    strategy: "PATH",
    default_version: "v1",
    versions: ["v1", "v2"]
  },
  
  # Rate Limiting
  rate_limit: {
    enabled: true,
    burst_limit: 5000,
    rate_limit: 10000.0,
    quota_limit: 1000000,
    quota_period: "MONTH"
  },
  
  # CORS Configuration
  cors: {
    enabled: true,
    allow_origins: ["https://app.example.com", "https://admin.example.com"],
    allow_methods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
    allow_headers: ["Content-Type", "Authorization", "X-API-Key", "X-Trace-Id"],
    max_age: 86400,
    allow_credentials: true
  },
  
  # Security
  authorizer_ref: jwt_authorizer_ref,
  waf_acl_ref: waf_acl_ref,
  
  # Logging and Monitoring
  access_log_destination_arn: log_group_ref.arn,
  xray_tracing_enabled: true,
  metrics_enabled: true,
  data_trace_enabled: true,
  logging_level: "INFO"
})
```

### API Gateway with Request Transformation

```ruby
# Create API Gateway with complex request/response transformations
transform_api = api_gateway_microservices(:transform_api, {
  api_name: "transformation-api",
  
  service_endpoints: [
    {
      name: "legacy",
      base_path: "legacy",
      methods: [
        {
          path: "/convert",
          method: "POST"
        }
      ],
      integration: {
        type: "HTTP",
        uri: "https://legacy-system.example.com/api/v1/process",
        http_method: "POST"
      },
      transformation: {
        # Transform modern JSON to legacy XML
        request_templates: {
          "application/json" => <<~TEMPLATE
            <?xml version="1.0" encoding="UTF-8"?>
            <LegacyRequest>
              <CustomerId>$input.path('$.customer_id')</CustomerId>
              <OrderData>
                #foreach($item in $input.path('$.items'))
                <Item>
                  <SKU>$item.sku</SKU>
                  <Quantity>$item.quantity</Quantity>
                </Item>
                #end
              </OrderData>
              <Timestamp>$context.requestTime</Timestamp>
            </LegacyRequest>
          TEMPLATE
        },
        # Transform legacy XML response to modern JSON
        response_templates: {
          "application/xml" => <<~TEMPLATE
            {
              "order_id": "$input.path('//OrderId')",
              "status": "$input.path('//Status')",
              "total": $input.path('//TotalAmount'),
              "processed_at": "$context.requestTime"
            }
          TEMPLATE
        }
      }
    }
  ]
})
```

## Inputs

### Required Inputs

- `api_name`: Name for the REST API
- `service_endpoints`: Array of service endpoint configurations

### Service Endpoint Configuration

```ruby
{
  name: "service-name",
  base_path: "path",
  methods: [
    {
      path: "/resource",
      method: "GET",
      authorization: "NONE",
      api_key_required: false,
      request_parameters: {},
      request_models: {}
    }
  ],
  integration: {
    type: "HTTP_PROXY",
    uri: "https://backend.example.com/{proxy}",
    connection_type: "INTERNET",
    timeout_milliseconds: 29000
  },
  transformation: {
    request_templates: {},
    response_templates: {}
  }
}
```

### Optional Inputs

- `api_description`: Description of the API (default: "Microservices API Gateway")
- `stage_name`: Deployment stage name (default: "prod")
- `endpoint_type`: API endpoint type - EDGE, REGIONAL, or PRIVATE (default: "REGIONAL")
- `rate_limit`: Rate limiting configuration
- `versioning`: API versioning configuration
- `cors`: CORS configuration
- `authorizer_ref`: Reference to custom authorizer
- `cache_cluster_enabled`: Enable caching (default: false)
- `cache_cluster_size`: Cache size in GB (default: "0.5")
- `xray_tracing_enabled`: Enable X-Ray tracing (default: true)
- `waf_acl_ref`: Reference to WAF ACL for protection

## Outputs

The component returns a `ComponentReference` with:

- `api_id`: ID of the REST API
- `api_name`: Name of the REST API
- `api_endpoint`: Base URL of the API
- `stage_name`: Deployment stage name
- `service_endpoints`: List of configured service endpoints with URLs
- `features`: List of enabled features
- `api_key_id`: API key ID (if rate limiting enabled)
- `usage_plan_id`: Usage plan ID (if rate limiting enabled)
- `estimated_monthly_cost`: Estimated AWS costs

## Resources Created

- `aws_api_gateway_rest_api`: Main REST API
- `aws_api_gateway_resource`: API resources for each path
- `aws_api_gateway_method`: HTTP methods for each endpoint
- `aws_api_gateway_integration`: Backend integrations
- `aws_api_gateway_deployment`: API deployment
- `aws_api_gateway_stage`: Deployment stage with settings
- `aws_api_gateway_vpc_link`: VPC links for private integrations (optional)
- `aws_api_gateway_usage_plan`: Usage plan for rate limiting (optional)
- `aws_api_gateway_api_key`: API key for authentication (optional)
- `aws_cloudwatch_metric_alarm`: Monitoring alarms
- `aws_wafv2_web_acl_association`: WAF association (optional)

## Best Practices

1. **Service Integration**
   - Use VPC Links for private backend services
   - Configure appropriate timeouts for each service
   - Implement proper error handling in transformations
   - Use connection pooling for better performance

2. **Security**
   - Enable WAF for protection against common attacks
   - Use custom authorizers for authentication
   - Implement API keys for third-party access
   - Configure CORS restrictively for production

3. **Performance**
   - Enable caching for frequently accessed data
   - Use compression for large payloads
   - Optimize request/response transformations
   - Monitor and adjust rate limits based on usage

4. **API Design**
   - Follow RESTful conventions consistently
   - Version APIs from the start
   - Document all endpoints thoroughly
   - Use meaningful HTTP status codes

5. **Monitoring**
   - Enable X-Ray tracing for debugging
   - Set up CloudWatch alarms for errors
   - Monitor latency and throttling metrics
   - Track API usage patterns