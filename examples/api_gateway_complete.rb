# Complete API Gateway Example with all resources

template :api_gateway_example do
  provider :aws do
    region "us-east-1"
  end

  # Create REST API
  api = aws_api_gateway_rest_api(:main_api, {
    name: "example-api",
    description: "Complete API Gateway example",
    endpoint_configuration: {
      types: ["REGIONAL"]
    },
    minimum_tls_version: "TLS_1_2",
    binary_media_types: ["image/*", "application/pdf"],
    tags: {
      Environment: "production",
      Service: "api-gateway"
    }
  })

  # Create resources (paths)
  # /users
  users_resource = aws_api_gateway_resource(:users, {
    rest_api_id: api.id,
    parent_id: api.root_resource_id,
    path_part: "users"
  })

  # /users/{userId}
  user_resource = aws_api_gateway_resource(:user, {
    rest_api_id: api.id,
    parent_id: users_resource.id,
    path_part: "{userId}"
  })

  # /health
  health_resource = aws_api_gateway_resource(:health, {
    rest_api_id: api.id,
    parent_id: api.root_resource_id,
    path_part: "health"
  })

  # Create methods
  # GET /users
  get_users_method = aws_api_gateway_method(:get_users, {
    rest_api_id: api.id,
    resource_id: users_resource.id,
    http_method: "GET",
    authorization: "AWS_IAM",
    request_parameters: {
      "method.request.querystring.page" => false,
      "method.request.querystring.limit" => false
    }
  })

  # POST /users
  create_user_method = aws_api_gateway_method(:create_user, {
    rest_api_id: api.id,
    resource_id: users_resource.id,
    http_method: "POST",
    authorization: "AWS_IAM",
    api_key_required: true,
    request_models: {
      "application/json" => "Empty"  # In real usage, reference a model
    }
  })

  # GET /users/{userId}
  get_user_method = aws_api_gateway_method(:get_user, {
    rest_api_id: api.id,
    resource_id: user_resource.id,
    http_method: "GET",
    authorization: "COGNITO_USER_POOLS",
    authorizer_id: "cognito-authorizer-id",  # In real usage, reference authorizer
    request_parameters: {
      "method.request.path.userId" => true
    }
  })

  # GET /health (public)
  health_method = aws_api_gateway_method(:health, {
    rest_api_id: api.id,
    resource_id: health_resource.id,
    http_method: "GET",
    authorization: "NONE"
  })

  # Create deployment
  deployment = aws_api_gateway_deployment(:initial_deployment, {
    rest_api_id: api.id,
    description: "Initial deployment of API",
    triggers: {
      # Redeploy when configuration changes
      redeployment: "${sha256(jsonencode([
        ${aws_api_gateway_rest_api.main_api.id},
        ${aws_api_gateway_resource.users.id},
        ${aws_api_gateway_method.get_users.id}
      ]))}"
    }
  })

  # Create stages
  # Development stage
  dev_stage = aws_api_gateway_stage(:dev_stage, {
    rest_api_id: api.id,
    deployment_id: deployment.id,
    stage_name: "dev",
    description: "Development stage",
    cache_cluster_enabled: false,
    xray_tracing_enabled: true,
    variables: {
      "lambdaAlias" => "dev",
      "logLevel" => "DEBUG",
      "environment" => "development"
    },
    method_settings: [
      {
        resource_path: "/*/*",
        http_method: "*",
        metrics_enabled: true,
        logging_level: "INFO",
        data_trace_enabled: true
      }
    ],
    tags: {
      Environment: "development"
    }
  })

  # Production stage with canary
  prod_stage = aws_api_gateway_stage(:prod_stage, {
    rest_api_id: api.id,
    deployment_id: deployment.id,
    stage_name: "prod",
    description: "Production stage with caching and throttling",
    cache_cluster_enabled: true,
    cache_cluster_size: "1.6",
    xray_tracing_enabled: true,
    throttle_rate_limit: 10000.0,
    throttle_burst_limit: 5000,
    variables: {
      "lambdaAlias" => "prod",
      "logLevel" => "ERROR",
      "environment" => "production"
    },
    access_log_settings: {
      destination_arn: "${aws_cloudwatch_log_group.api_logs.arn}",
      format: '$context.requestId $context.extendedRequestId $context.requestTime $context.httpMethod $context.path $context.status'
    },
    method_settings: [
      {
        resource_path: "/*/*",
        http_method: "*",
        metrics_enabled: true,
        logging_level: "ERROR",
        data_trace_enabled: false,
        caching_enabled: true,
        cache_ttl_in_seconds: 300,
        cache_data_encrypted: true
      },
      {
        resource_path: "/health/*",
        http_method: "GET",
        caching_enabled: false  # Don't cache health checks
      }
    ],
    canary_settings: {
      percent_traffic: 10.0,
      stage_variable_overrides: {
        "lambdaAlias" => "canary",
        "testFeature" => "enabled"
      }
    },
    tags: {
      Environment: "production"
    }
  })

  # Outputs
  output :api_id do
    value api.id
    description "REST API ID"
  end

  output :dev_invoke_url do
    value "https://#{api.id}.execute-api.us-east-1.amazonaws.com/dev"
    description "Development API invoke URL"
  end

  output :prod_invoke_url do
    value "https://#{api.id}.execute-api.us-east-1.amazonaws.com/prod"
    description "Production API invoke URL"
  end
end

# Example with microservice proxy pattern
template :microservice_gateway do
  provider :aws do
    region "us-east-1"
  end

  # API Gateway as microservice gateway
  gateway = aws_api_gateway_rest_api(:microservice_gateway, {
    name: "microservice-gateway",
    description: "Central gateway for microservices",
    endpoint_configuration: {
      types: ["EDGE"]  # Global distribution
    }
  })

  # /services/{service}/{proxy+}
  services_resource = aws_api_gateway_resource(:services, {
    rest_api_id: gateway.id,
    parent_id: gateway.root_resource_id,
    path_part: "services"
  })

  service_resource = aws_api_gateway_resource(:service, {
    rest_api_id: gateway.id,
    parent_id: services_resource.id,
    path_part: "{service}"
  })

  proxy_resource = aws_api_gateway_resource(:proxy, {
    rest_api_id: gateway.id,
    parent_id: service_resource.id,
    path_part: "{proxy+}"
  })

  # ANY method for proxy
  proxy_method = aws_api_gateway_method(:proxy_method, {
    rest_api_id: gateway.id,
    resource_id: proxy_resource.id,
    http_method: "ANY",
    authorization: "AWS_IAM",
    request_parameters: {
      "method.request.path.service" => true,
      "method.request.path.proxy" => true
    }
  })

  # Deploy with multiple stages
  deployment = aws_api_gateway_deployment(:microservice_deployment, {
    rest_api_id: gateway.id,
    description: "Microservice gateway deployment"
  })

  # Production stage
  prod = aws_api_gateway_stage(:prod, {
    rest_api_id: gateway.id,
    deployment_id: deployment.id,
    stage_name: "prod",
    variables: {
      "userServiceUrl" => "https://user-service.internal",
      "orderServiceUrl" => "https://order-service.internal",
      "inventoryServiceUrl" => "https://inventory-service.internal"
    }
  })
end