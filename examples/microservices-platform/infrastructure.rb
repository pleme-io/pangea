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

# Example: Microservices Platform
# This example demonstrates a complete microservices platform using:
# - Container orchestration with ECS Fargate
# - Service mesh with App Mesh
# - API Gateway for unified API management
# - Event-driven architecture with SQS/SNS
# - Service discovery and load balancing
# - Centralized logging and monitoring

# Template 1: Platform Infrastructure
template :platform_infrastructure do
  provider :aws do
    region "us-east-1"
    
    default_tags do
      tags do
        ManagedBy "Pangea"
        Environment namespace
        Project "MicroservicesPlatform"
        Template "platform_infrastructure"
      end
    end
  end
  
  # VPC for microservices platform
  vpc = resource :aws_vpc, :main do
    cidr_block "10.0.0.0/16"
    enable_dns_hostnames true
    enable_dns_support true
    
    tags do
      Name "Microservices-VPC-#{namespace}"
      Purpose "MicroservicesPlatform"
    end
  end
  
  # Internet Gateway
  igw = resource :aws_internet_gateway, :main do
    vpc_id ref(:aws_vpc, :main, :id)
    
    tags do
      Name "Microservices-IGW-#{namespace}"
    end
  end
  
  # Availability zones for high availability
  availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]
  
  # Public subnets for load balancers
  availability_zones.each_with_index do |az, index|
    resource :"aws_subnet", :"public_#{index + 1}" do
      vpc_id ref(:aws_vpc, :main, :id)
      cidr_block "10.0.#{index + 1}.0/24"
      availability_zone az
      map_public_ip_on_launch true
      
      tags do
        Name "Microservices-Public-#{index + 1}-#{namespace}"
        Type "public"
        AZ az
      end
    end
  end
  
  # Private subnets for microservices
  availability_zones.each_with_index do |az, index|
    resource :"aws_subnet", :"private_#{index + 1}" do
      vpc_id ref(:aws_vpc, :main, :id)
      cidr_block "10.0.#{index + 10}.0/24"
      availability_zone az
      
      tags do
        Name "Microservices-Private-#{index + 1}-#{namespace}"
        Type "private"
        Purpose "microservices"
        AZ az
      end
    end
  end
  
  # NAT Gateways for outbound internet access
  availability_zones.each_with_index do |az, index|
    # Elastic IP for NAT Gateway
    resource :"aws_eip", :"nat_#{index + 1}" do
      domain "vpc"
      
      tags do
        Name "Microservices-NAT-EIP-#{index + 1}-#{namespace}"
        AZ az
      end
    end
    
    # NAT Gateway
    resource :"aws_nat_gateway", :"main_#{index + 1}" do
      allocation_id ref(:"aws_eip", :"nat_#{index + 1}", :id)
      subnet_id ref(:"aws_subnet", :"public_#{index + 1}", :id)
      
      tags do
        Name "Microservices-NAT-#{index + 1}-#{namespace}"
        AZ az
      end
    end
  end
  
  # Route table for public subnets
  public_rt = resource :aws_route_table, :public do
    vpc_id ref(:aws_vpc, :main, :id)
    
    route do
      cidr_block "0.0.0.0/0"
      gateway_id ref(:aws_internet_gateway, :main, :id)
    end
    
    tags do
      Name "Microservices-Public-RT-#{namespace}"
    end
  end
  
  # Associate public subnets with public route table
  availability_zones.each_with_index do |az, index|
    resource :"aws_route_table_association", :"public_#{index + 1}" do
      subnet_id ref(:"aws_subnet", :"public_#{index + 1}", :id)
      route_table_id ref(:aws_route_table, :public, :id)
    end
  end
  
  # Route tables for private subnets (one per AZ)
  availability_zones.each_with_index do |az, index|
    resource :"aws_route_table", :"private_#{index + 1}" do
      vpc_id ref(:aws_vpc, :main, :id)
      
      route do
        cidr_block "0.0.0.0/0"
        nat_gateway_id ref(:"aws_nat_gateway", :"main_#{index + 1}", :id)
      end
      
      tags do
        Name "Microservices-Private-RT-#{index + 1}-#{namespace}"
        AZ az
      end
    end
    
    # Associate private subnets with private route tables
    resource :"aws_route_table_association", :"private_#{index + 1}" do
      subnet_id ref(:"aws_subnet", :"private_#{index + 1}", :id)
      route_table_id ref(:"aws_route_table", :"private_#{index + 1}", :id)
    end
  end
  
  # ECS Cluster for microservices
  ecs_cluster = resource :aws_ecs_cluster, :main do
    name "microservices-cluster-#{namespace}"
    
    configuration do
      execute_command_configuration do
        kms_key_id ref(:aws_kms_key, :ecs_execution, :arn)
        logging "OVERRIDE"
        
        log_configuration do
          cloud_watch_encryption_enabled true
          cloud_watch_log_group_name ref(:aws_cloudwatch_log_group, :ecs_exec, :name)
        end
      end
    end
    
    service_connect_defaults do
      namespace ref(:aws_service_discovery_private_dns_namespace, :main, :arn)
    end
    
    tags do
      Name "Microservices-ECS-Cluster-#{namespace}"
      Purpose "ContainerOrchestration"
    end
  end
  
  # ECS Cluster Capacity Providers
  resource :aws_ecs_cluster_capacity_providers, :main do
    cluster_name ref(:aws_ecs_cluster, :main, :name)
    capacity_providers ["FARGATE", "FARGATE_SPOT"]
    
    default_capacity_provider_strategy do
      capacity_provider "FARGATE"
      weight 1
      base 1
    end
    
    default_capacity_provider_strategy do
      capacity_provider "FARGATE_SPOT"
      weight 4
    end
  end
  
  # Service Discovery namespace
  service_discovery = resource :aws_service_discovery_private_dns_namespace, :main do
    name "microservices.local"
    vpc ref(:aws_vpc, :main, :id)
    description "Service discovery for microservices platform"
    
    tags do
      Name "Microservices-ServiceDiscovery-#{namespace}"
      Purpose "ServiceMesh"
    end
  end
  
  # App Mesh for service mesh
  app_mesh = resource :aws_appmesh_mesh, :main do
    name "microservices-mesh-#{namespace}"
    
    spec do
      egress_filter do
        type "ALLOW_ALL"
      end
    end
    
    tags do
      Name "Microservices-AppMesh-#{namespace}"
      Purpose "ServiceMesh"
    end
  end
  
  # CloudWatch Log Groups
  resource :aws_cloudwatch_log_group, :ecs_exec do
    name "/aws/ecs/microservices/exec"
    retention_in_days 30
    
    tags do
      Name "Microservices-ECS-Exec-Logs-#{namespace}"
      Purpose "ContainerExecution"
    end
  end
  
  resource :aws_cloudwatch_log_group, :platform do
    name "/aws/microservices/platform"
    retention_in_days 30
    
    tags do
      Name "Microservices-Platform-Logs-#{namespace}"
      Purpose "PlatformLogging"
    end
  end
  
  # KMS key for ECS execution encryption
  kms_key = resource :aws_kms_key, :ecs_execution do
    description "KMS key for ECS execution encryption"
    deletion_window_in_days 7
    
    policy jsonencode({
      Version: "2012-10-17",
      Statement: [
        {
          Effect: "Allow",
          Principal: { AWS: "arn:aws:iam::#{data(:aws_caller_identity, :current, :account_id)}:root" },
          Action: "kms:*",
          Resource: "*"
        },
        {
          Effect: "Allow",
          Principal: { Service: "ecs-tasks.amazonaws.com" },
          Action: [
            "kms:Decrypt",
            "kms:DescribeKey"
          ],
          Resource: "*"
        }
      ]
    })
    
    tags do
      Name "Microservices-ECS-Execution-Key-#{namespace}"
      Purpose "ContainerEncryption"
    end
  end
  
  resource :aws_kms_alias, :ecs_execution do
    name "alias/microservices-ecs-execution-#{namespace}"
    target_key_id ref(:aws_kms_key, :ecs_execution, :key_id)
  end
  
  # Get current AWS account ID
  data :aws_caller_identity, :current do
  end
  
  # Outputs for other templates
  output :vpc_id do
    value ref(:aws_vpc, :main, :id)
    description "VPC ID for microservices platform"
  end
  
  output :public_subnet_ids do
    value [
      ref(:aws_subnet, :public_1, :id),
      ref(:aws_subnet, :public_2, :id),
      ref(:aws_subnet, :public_3, :id)
    ]
    description "Public subnet IDs for load balancers"
  end
  
  output :private_subnet_ids do
    value [
      ref(:aws_subnet, :private_1, :id),
      ref(:aws_subnet, :private_2, :id),
      ref(:aws_subnet, :private_3, :id)
    ]
    description "Private subnet IDs for microservices"
  end
  
  output :ecs_cluster_name do
    value ref(:aws_ecs_cluster, :main, :name)
    description "ECS cluster name for microservices"
  end
  
  output :ecs_cluster_arn do
    value ref(:aws_ecs_cluster, :main, :arn)
    description "ECS cluster ARN"
  end
  
  output :service_discovery_namespace_id do
    value ref(:aws_service_discovery_private_dns_namespace, :main, :id)
    description "Service discovery namespace ID"
  end
  
  output :app_mesh_name do
    value ref(:aws_appmesh_mesh, :main, :name)
    description "App Mesh name"
  end
end

# Template 2: Messaging Infrastructure
template :messaging_infrastructure do
  provider :aws do
    region "us-east-1"
    
    default_tags do
      tags do
        ManagedBy "Pangea"
        Environment namespace
        Project "MicroservicesPlatform"
        Template "messaging_infrastructure"
      end
    end
  end
  
  # Reference the VPC from platform infrastructure
  data :aws_vpc, :main do
    filter do
      name "tag:Name"
      values ["Microservices-VPC-#{namespace}"]
    end
  end
  
  # SNS Topics for event publishing
  user_events = resource :aws_sns_topic, :user_events do
    name "microservices-user-events-#{namespace}"
    display_name "User Events Topic"
    
    tags do
      Name "Microservices-UserEvents-#{namespace}"
      Purpose "EventDriven"
      Category "UserManagement"
    end
  end
  
  order_events = resource :aws_sns_topic, :order_events do
    name "microservices-order-events-#{namespace}"
    display_name "Order Events Topic"
    
    tags do
      Name "Microservices-OrderEvents-#{namespace}"
      Purpose "EventDriven"
      Category "OrderManagement"
    end
  end
  
  payment_events = resource :aws_sns_topic, :payment_events do
    name "microservices-payment-events-#{namespace}"
    display_name "Payment Events Topic"
    
    tags do
      Name "Microservices-PaymentEvents-#{namespace}"
      Purpose "EventDriven"
      Category "PaymentProcessing"
    end
  end
  
  # SQS Queues for service communication
  user_service_queue = resource :aws_sqs_queue, :user_service do
    name "microservices-user-service-#{namespace}"
    visibility_timeout_seconds 30
    message_retention_seconds 1209600 # 14 days
    max_message_size 262144
    delay_seconds 0
    receive_wait_time_seconds 0
    
    redrive_policy jsonencode({
      deadLetterTargetArn: ref(:aws_sqs_queue, :user_service_dlq, :arn),
      maxReceiveCount: 3
    })
    
    tags do
      Name "Microservices-UserService-Queue-#{namespace}"
      Service "UserService"
      Purpose "ServiceCommunication"
    end
  end
  
  resource :aws_sqs_queue, :user_service_dlq do
    name "microservices-user-service-dlq-#{namespace}"
    message_retention_seconds 1209600 # 14 days
    
    tags do
      Name "Microservices-UserService-DLQ-#{namespace}"
      Service "UserService"
      Purpose "DeadLetterQueue"
    end
  end
  
  order_service_queue = resource :aws_sqs_queue, :order_service do
    name "microservices-order-service-#{namespace}"
    visibility_timeout_seconds 30
    message_retention_seconds 1209600
    
    redrive_policy jsonencode({
      deadLetterTargetArn: ref(:aws_sqs_queue, :order_service_dlq, :arn),
      maxReceiveCount: 3
    })
    
    tags do
      Name "Microservices-OrderService-Queue-#{namespace}"
      Service "OrderService"
      Purpose "ServiceCommunication"
    end
  end
  
  resource :aws_sqs_queue, :order_service_dlq do
    name "microservices-order-service-dlq-#{namespace}"
    message_retention_seconds 1209600
    
    tags do
      Name "Microservices-OrderService-DLQ-#{namespace}"
      Service "OrderService"
      Purpose "DeadLetterQueue"
    end
  end
  
  payment_service_queue = resource :aws_sqs_queue, :payment_service do
    name "microservices-payment-service-#{namespace}"
    visibility_timeout_seconds 60 # Longer timeout for payment processing
    message_retention_seconds 1209600
    
    redrive_policy jsonencode({
      deadLetterTargetArn: ref(:aws_sqs_queue, :payment_service_dlq, :arn),
      maxReceiveCount: 2  # Fewer retries for payments
    })
    
    tags do
      Name "Microservices-PaymentService-Queue-#{namespace}"
      Service "PaymentService"
      Purpose "ServiceCommunication"
    end
  end
  
  resource :aws_sqs_queue, :payment_service_dlq do
    name "microservices-payment-service-dlq-#{namespace}"
    message_retention_seconds 1209600
    
    tags do
      Name "Microservices-PaymentService-DLQ-#{namespace}"
      Service "PaymentService"
      Purpose "DeadLetterQueue"
    end
  end
  
  # SNS Topic subscriptions to SQS queues
  resource :aws_sns_topic_subscription, :user_events_to_order_service do
    topic_arn ref(:aws_sns_topic, :user_events, :arn)
    protocol "sqs"
    endpoint ref(:aws_sqs_queue, :order_service, :arn)
    
    filter_policy jsonencode({
      event_type: ["user_created", "user_updated"]
    })
  end
  
  resource :aws_sns_topic_subscription, :order_events_to_payment_service do
    topic_arn ref(:aws_sns_topic, :order_events, :arn)
    protocol "sqs"
    endpoint ref(:aws_sqs_queue, :payment_service, :arn)
    
    filter_policy jsonencode({
      event_type: ["order_created", "order_cancelled"]
    })
  end
  
  resource :aws_sns_topic_subscription, :payment_events_to_order_service do
    topic_arn ref(:aws_sns_topic, :payment_events, :arn)
    protocol "sqs"
    endpoint ref(:aws_sqs_queue, :order_service, :arn)
    
    filter_policy jsonencode({
      event_type: ["payment_completed", "payment_failed"]
    })
  end
  
  # SQS Queue policies to allow SNS to send messages
  resource :aws_sqs_queue_policy, :user_service do
    queue_url ref(:aws_sqs_queue, :user_service, :id)
    policy jsonencode({
      Version: "2012-10-17",
      Statement: [
        {
          Effect: "Allow",
          Principal: { Service: "sns.amazonaws.com" },
          Action: "sqs:SendMessage",
          Resource: ref(:aws_sqs_queue, :user_service, :arn),
          Condition: {
            ArnEquals: {
              "aws:SourceArn": [
                ref(:aws_sns_topic, :user_events, :arn),
                ref(:aws_sns_topic, :order_events, :arn),
                ref(:aws_sns_topic, :payment_events, :arn)
              ]
            }
          }
        }
      ]
    })
  end
  
  resource :aws_sqs_queue_policy, :order_service do
    queue_url ref(:aws_sqs_queue, :order_service, :id)
    policy jsonencode({
      Version: "2012-10-17",
      Statement: [
        {
          Effect: "Allow",
          Principal: { Service: "sns.amazonaws.com" },
          Action: "sqs:SendMessage",
          Resource: ref(:aws_sqs_queue, :order_service, :arn),
          Condition: {
            ArnEquals: {
              "aws:SourceArn": [
                ref(:aws_sns_topic, :user_events, :arn),
                ref(:aws_sns_topic, :order_events, :arn),
                ref(:aws_sns_topic, :payment_events, :arn)
              ]
            }
          }
        }
      ]
    })
  end
  
  resource :aws_sqs_queue_policy, :payment_service do
    queue_url ref(:aws_sqs_queue, :payment_service, :id)
    policy jsonencode({
      Version: "2012-10-17",
      Statement: [
        {
          Effect: "Allow",
          Principal: { Service: "sns.amazonaws.com" },
          Action: "sqs:SendMessage",
          Resource: ref(:aws_sqs_queue, :payment_service, :arn),
          Condition: {
            ArnEquals: {
              "aws:SourceArn": [
                ref(:aws_sns_topic, :user_events, :arn),
                ref(:aws_sns_topic, :order_events, :arn),
                ref(:aws_sns_topic, :payment_events, :arn)
              ]
            }
          }
        }
      ]
    })
  end
  
  # EventBridge custom bus for advanced event routing
  event_bus = resource :aws_cloudwatch_event_bus, :microservices do
    name "microservices-event-bus-#{namespace}"
    
    tags do
      Name "Microservices-EventBus-#{namespace}"
      Purpose "EventRouting"
    end
  end
  
  # EventBridge rules for cross-service communication
  resource :aws_cloudwatch_event_rule, :user_service_events do
    name "microservices-user-service-events-#{namespace}"
    description "Route user service events to interested consumers"
    event_bus_name ref(:aws_cloudwatch_event_bus, :microservices, :name)
    
    event_pattern jsonencode({
      source: ["user.service"],
      detail_type: ["User Created", "User Updated", "User Deleted"]
    })
    
    tags do
      Name "Microservices-UserService-EventRule-#{namespace}"
      Service "UserService"
    end
  end
  
  # Outputs
  output :sns_topics do
    value {
      user_events: ref(:aws_sns_topic, :user_events, :arn),
      order_events: ref(:aws_sns_topic, :order_events, :arn),
      payment_events: ref(:aws_sns_topic, :payment_events, :arn)
    }
    description "SNS topic ARNs for event publishing"
  end
  
  output :sqs_queues do
    value {
      user_service: ref(:aws_sqs_queue, :user_service, :arn),
      order_service: ref(:aws_sqs_queue, :order_service, :arn),
      payment_service: ref(:aws_sqs_queue, :payment_service, :arn)
    }
    description "SQS queue ARNs for service communication"
  end
  
  output :event_bus_name do
    value ref(:aws_cloudwatch_event_bus, :microservices, :name)
    description "EventBridge custom bus name"
  end
end

# Template 3: API Gateway
template :api_gateway do
  provider :aws do
    region "us-east-1"
    
    default_tags do
      tags do
        ManagedBy "Pangea"
        Environment namespace
        Project "MicroservicesPlatform"
        Template "api_gateway"
      end
    end
  end
  
  # Reference platform infrastructure
  data :aws_vpc, :main do
    filter do
      name "tag:Name"
      values ["Microservices-VPC-#{namespace}"]
    end
  end
  
  data :aws_subnets, :private do
    filter do
      name "vpc-id"
      values [data(:aws_vpc, :main, :id)]
    end
    
    filter do
      name "tag:Purpose"
      values ["microservices"]
    end
  end
  
  # API Gateway v2 (HTTP API) for better performance and lower cost
  api = resource :aws_apigatewayv2_api, :main do
    name "microservices-api-#{namespace}"
    protocol_type "HTTP"
    description "Main API Gateway for microservices platform"
    
    cors_configuration do
      allow_credentials false
      allow_headers ["content-type", "x-amz-date", "authorization", "x-api-key", "x-amz-security-token", "x-amz-user-agent"]
      allow_methods ["*"]
      allow_origins ["*"]
      expose_headers ["date", "keep-alive"]
      max_age 86400
    end
    
    tags do
      Name "Microservices-APIGateway-#{namespace}"
      Purpose "UnifiedAPI"
    end
  end
  
  # VPC Link for private integration with microservices
  vpc_link = resource :aws_apigatewayv2_vpc_link, :main do
    name "microservices-vpc-link-#{namespace}"
    security_group_ids [ref(:aws_security_group, :vpc_link, :id)]
    subnet_ids data(:aws_subnets, :private, :ids)
    
    tags do
      Name "Microservices-VPCLink-#{namespace}"
      Purpose "PrivateIntegration"
    end
  end
  
  # Security group for VPC Link
  resource :aws_security_group, :vpc_link do
    name_prefix "microservices-vpc-link-"
    vpc_id data(:aws_vpc, :main, :id)
    description "Security group for API Gateway VPC Link"
    
    ingress do
      from_port 80
      to_port 80
      protocol "tcp"
      cidr_blocks ["10.0.0.0/16"]
      description "HTTP from VPC"
    end
    
    ingress do
      from_port 443
      to_port 443
      protocol "tcp"
      cidr_blocks ["10.0.0.0/16"]
      description "HTTPS from VPC"
    end
    
    egress do
      from_port 0
      to_port 0
      protocol "-1"
      cidr_blocks ["10.0.0.0/16"]
      description "All traffic to VPC"
    end
    
    tags do
      Name "Microservices-VPCLink-SG-#{namespace}"
      Purpose "APIGatewayVPCLink"
    end
  end
  
  # API Gateway stages
  deployment = resource :aws_apigatewayv2_deployment, :main do
    api_id ref(:aws_apigatewayv2_api, :main, :id)
    description "Deployment for microservices API"
    
    # Triggers redeployment when routes change
    lifecycle do
      create_before_destroy true
    end
    
    depends_on [
      ref(:aws_apigatewayv2_route, :user_service_get),
      ref(:aws_apigatewayv2_route, :user_service_post),
      ref(:aws_apigatewayv2_route, :order_service_get),
      ref(:aws_apigatewayv2_route, :order_service_post),
      ref(:aws_apigatewayv2_route, :payment_service_post)
    ]
  end
  
  # API stages for different environments
  api_stage = resource :aws_apigatewayv2_stage, :main do
    api_id ref(:aws_apigatewayv2_api, :main, :id)
    deployment_id ref(:aws_apigatewayv2_deployment, :main, :id)
    name namespace
    description "#{namespace.capitalize} stage for microservices API"
    
    access_log_settings do
      destination_arn ref(:aws_cloudwatch_log_group, :api_gateway, :arn)
      format jsonencode({
        requestId: "$context.requestId",
        ip: "$context.identity.sourceIp",
        requestTime: "$context.requestTime",
        httpMethod: "$context.httpMethod",
        resourcePath: "$context.resourcePath",
        status: "$context.status",
        protocol: "$context.protocol",
        responseLength: "$context.responseLength",
        responseTime: "$context.responseTime"
      })
    end
    
    default_route_settings do
      detailed_metrics_enabled true
      logging_level "INFO"
      data_trace_enabled namespace != "production"
      throttling_burst_limit 5000
      throttling_rate_limit 2000
    end
    
    tags do
      Name "Microservices-API-Stage-#{namespace}"
      Stage namespace
    end
  end
  
  # CloudWatch Log Group for API Gateway logs
  resource :aws_cloudwatch_log_group, :api_gateway do
    name "/aws/apigateway/microservices-#{namespace}"
    retention_in_days 30
    
    tags do
      Name "Microservices-APIGateway-Logs-#{namespace}"
      Purpose "APILogging"
    end
  end
  
  # Example integrations for microservices (these would reference actual ECS services)
  
  # User Service Integration
  user_service_integration = resource :aws_apigatewayv2_integration, :user_service do
    api_id ref(:aws_apigatewayv2_api, :main, :id)
    integration_type "HTTP_PROXY"
    integration_method "ANY"
    integration_uri "http://user-service.microservices.local:8080/{proxy}"
    connection_type "VPC_LINK"
    connection_id ref(:aws_apigatewayv2_vpc_link, :main, :id)
    
    timeout_milliseconds 30000
    
    request_parameters do
      "overwrite:path" = "/{proxy}"
    end
  end
  
  resource :aws_apigatewayv2_route, :user_service_get do
    api_id ref(:aws_apigatewayv2_api, :main, :id)
    route_key "GET /users/{proxy+}"
    target "integrations/#{ref(:aws_apigatewayv2_integration, :user_service, :id)}"
  end
  
  resource :aws_apigatewayv2_route, :user_service_post do
    api_id ref(:aws_apigatewayv2_api, :main, :id)
    route_key "POST /users/{proxy+}"
    target "integrations/#{ref(:aws_apigatewayv2_integration, :user_service, :id)}"
  end
  
  # Order Service Integration
  order_service_integration = resource :aws_apigatewayv2_integration, :order_service do
    api_id ref(:aws_apigatewayv2_api, :main, :id)
    integration_type "HTTP_PROXY"
    integration_method "ANY"
    integration_uri "http://order-service.microservices.local:8080/{proxy}"
    connection_type "VPC_LINK"
    connection_id ref(:aws_apigatewayv2_vpc_link, :main, :id)
    
    timeout_milliseconds 30000
  end
  
  resource :aws_apigatewayv2_route, :order_service_get do
    api_id ref(:aws_apigatewayv2_api, :main, :id)
    route_key "GET /orders/{proxy+}"
    target "integrations/#{ref(:aws_apigatewayv2_integration, :order_service, :id)}"
  end
  
  resource :aws_apigatewayv2_route, :order_service_post do
    api_id ref(:aws_apigatewayv2_api, :main, :id)
    route_key "POST /orders/{proxy+}"
    target "integrations/#{ref(:aws_apigatewayv2_integration, :order_service, :id)}"
  end
  
  # Payment Service Integration
  payment_service_integration = resource :aws_apigatewayv2_integration, :payment_service do
    api_id ref(:aws_apigatewayv2_api, :main, :id)
    integration_type "HTTP_PROXY"
    integration_method "ANY"
    integration_uri "http://payment-service.microservices.local:8080/{proxy}"
    connection_type "VPC_LINK"
    connection_id ref(:aws_apigatewayv2_vpc_link, :main, :id)
    
    timeout_milliseconds 45000 # Longer timeout for payments
  end
  
  resource :aws_apigatewayv2_route, :payment_service_post do
    api_id ref(:aws_apigatewayv2_api, :main, :id)
    route_key "POST /payments/{proxy+}"
    target "integrations/#{ref(:aws_apigatewayv2_integration, :payment_service, :id)}"
  end
  
  # Rate limiting and throttling
  resource :aws_apigatewayv2_route, :health_check do
    api_id ref(:aws_apigatewayv2_api, :main, :id)
    route_key "GET /health"
    
    # Mock integration for health check
    target "integrations/#{ref(:aws_apigatewayv2_integration, :health_check, :id)}"
  end
  
  resource :aws_apigatewayv2_integration, :health_check do
    api_id ref(:aws_apigatewayv2_api, :main, :id)
    integration_type "MOCK"
    
    template_selection_expression "200"
    
    response_parameters do
      "200" = {
        "application/json" => jsonencode({
          status: "healthy",
          timestamp: "$context.requestTime",
          environment: namespace
        })
      }
    end
  end
  
  # Custom domain (optional, requires certificate)
  if ENV['API_DOMAIN']
    # Certificate for custom domain
    certificate = resource :aws_acm_certificate, :api do
      domain_name ENV['API_DOMAIN']
      validation_method "DNS"
      
      tags do
        Name "Microservices-API-Certificate-#{namespace}"
        Purpose "CustomDomain"
      end
      
      lifecycle do
        create_before_destroy true
      end
    end
    
    # Custom domain name
    domain_name = resource :aws_apigatewayv2_domain_name, :api do
      domain_name ENV['API_DOMAIN']
      
      domain_name_configuration do
        certificate_arn ref(:aws_acm_certificate, :api, :arn)
        endpoint_type "REGIONAL"
        security_policy "TLS_1_2"
      end
      
      tags do
        Name "Microservices-API-Domain-#{namespace}"
        Purpose "CustomDomain"
      end
      
      depends_on [ref(:aws_acm_certificate_validation, :api)]
    end
    
    # Certificate validation
    resource :aws_acm_certificate_validation, :api do
      certificate_arn ref(:aws_acm_certificate, :api, :arn)
      timeouts do
        create "5m"
      end
    end
    
    # API mapping to custom domain
    resource :aws_apigatewayv2_api_mapping, :main do
      api_id ref(:aws_apigatewayv2_api, :main, :id)
      domain_name ref(:aws_apigatewayv2_domain_name, :api, :id)
      stage ref(:aws_apigatewayv2_stage, :main, :name)
    end
  end
  
  # Outputs
  output :api_gateway_url do
    value ref(:aws_apigatewayv2_stage, :main, :invoke_url)
    description "API Gateway invocation URL"
  end
  
  output :api_gateway_id do
    value ref(:aws_apigatewayv2_api, :main, :id)
    description "API Gateway ID"
  end
  
  output :vpc_link_id do
    value ref(:aws_apigatewayv2_vpc_link, :main, :id)
    description "VPC Link ID for private integrations"
  end
  
  if ENV['API_DOMAIN']
    output :custom_domain_name do
      value ref(:aws_apigatewayv2_domain_name, :api, :domain_name)
      description "Custom domain name for API"
    end
  end
end

# This microservices platform example demonstrates several key Pangea concepts:
#
# 1. **Template Isolation for Platform Components**: Three separate templates for:
#    - Platform infrastructure (networking, ECS, service discovery)
#    - Messaging infrastructure (SNS/SQS, EventBridge)
#    - API Gateway (unified API management)
#
# 2. **Service Mesh Architecture**: Using AWS App Mesh for service-to-service
#    communication with observability and traffic management.
#
# 3. **Event-Driven Communication**: SNS topics for event publishing with SQS
#    queues for service-specific message consumption and dead letter queues.
#
# 4. **Container Orchestration**: ECS Fargate with service discovery for
#    stateless microservices with automatic scaling.
#
# 5. **API Gateway Integration**: HTTP API Gateway with VPC Link for private
#    integration with microservices, including routing and throttling.
#
# 6. **Production-Ready Features**:
#    - Service discovery with private DNS namespace
#    - Message queues with dead letter queue handling
#    - API Gateway with rate limiting and monitoring
#    - CloudWatch logging for all components
#    - KMS encryption for sensitive data
#    - Multi-AZ deployment for high availability
#
# Deployment order:
#   pangea apply examples/microservices-platform.rb --template platform_infrastructure
#   pangea apply examples/microservices-platform.rb --template messaging_infrastructure
#   pangea apply examples/microservices-platform.rb --template api_gateway
#
# Environment-specific deployment:
#   export API_DOMAIN=api.mycompany.com
#   pangea apply examples/microservices-platform.rb --namespace production
#
# This example showcases how Pangea's template isolation enables building
# complex microservices platforms with clear separation of concerns and
# independent deployment capabilities.