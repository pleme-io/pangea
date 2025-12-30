# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

module Pangea
  module Components
    module MicroservicesExamples
      # Complete microservices platform example
      module Platform
        def microservices_platform_example
          vpc = secure_vpc(:platform_vpc, { cidr_block: '10.0.0.0/16', availability_zones: %w[us-east-1a us-east-1b us-east-1c], enable_nat_gateway: true, single_nat_gateway: false })
          subnets = public_private_subnets(:platform_subnets, { vpc_ref: vpc.vpc, availability_zones: %w[us-east-1a us-east-1b us-east-1c],
                                                                 public_cidrs: %w[10.0.1.0/24 10.0.2.0/24 10.0.3.0/24], private_cidrs: %w[10.0.10.0/24 10.0.20.0/24 10.0.30.0/24] })
          cluster_ref = aws_ecs_cluster(:platform_cluster, { name: 'microservices-platform', setting: [{ name: 'containerInsights', value: 'enabled' }] })
          service_sg = create_service_security_group(vpc)
          user_service = create_user_service(cluster_ref, vpc, subnets, service_sg)
          order_service = create_order_service(cluster_ref, vpc, subnets, service_sg)
          api_gateway = create_api_gateway(user_service, order_service)
          observability = create_observability(cluster_ref, user_service, order_service)
          { network: { vpc: vpc, subnets: subnets }, compute: { cluster: cluster_ref }, services: { user_service: user_service, order_service: order_service }, api: api_gateway, observability: observability }
        end

        private

        def create_service_security_group(vpc)
          aws_security_group(:service_sg, { name: 'microservices-sg', description: 'Security group for microservices', vpc_id: vpc.vpc.id,
                                            ingress: [{ from_port: 0, to_port: 65_535, protocol: 'tcp', self: true }],
                                            egress: [{ from_port: 0, to_port: 0, protocol: '-1', cidr_blocks: ['0.0.0.0/0'] }] })
        end

        def create_user_service(cluster_ref, vpc, subnets, service_sg)
          microservice_deployment(:user_service, {
            cluster_ref: cluster_ref, task_definition_family: 'user-service', task_cpu: '512', task_memory: '1024',
            container_definitions: [{ name: 'user-api', image: 'myapp/user-service:latest', cpu: 512, memory: 1024,
                                       port_mappings: [{ containerPort: 8080, protocol: 'tcp' }],
                                       environment: [{ name: 'SERVICE_NAME', value: 'user-service' }, { name: 'LOG_LEVEL', value: 'info' }],
                                       health_check: { command: ['CMD-SHELL', 'curl -f http://localhost:8080/health || exit 1'], interval: 30, timeout: 5, retries: 3 } }],
            vpc_ref: vpc.vpc, subnet_refs: subnets.resources[:private_subnets].values, security_group_refs: [service_sg],
            service_discovery: { namespace_id: '${ServiceDiscoveryNamespace.Id}', service_name: 'user-service' },
            auto_scaling: { enabled: true, min_tasks: 2, max_tasks: 10, target_cpu: 70.0 },
            tracing: { enabled: true, x_ray: true, sampling_rate: 0.1 }
          })
        end

        def create_order_service(cluster_ref, vpc, subnets, service_sg)
          event_driven_microservice(:order_service, {
            service_name: 'order-service',
            event_sources: [{ type: 'EventBridge', event_pattern: { source: ['ecommerce.orders'], 'detail-type': ['Order Placed', 'Payment Confirmed'] } },
                            { type: 'SQS', source_ref: aws_sqs_queue(:order_queue, { name: 'order-processing-queue' }) }],
            command_handler: { runtime: 'nodejs18.x', handler: 'handlers/commands.handler', timeout: 60, memory_size: 1024,
                               environment_variables: { USER_SERVICE_ENDPOINT: 'user-service.local:8080', INVENTORY_SERVICE_ENDPOINT: 'inventory-service.local:8080' } },
            query_handler: { runtime: 'nodejs18.x', handler: 'handlers/queries.handler', timeout: 30, memory_size: 512 },
            event_store: { table_name: 'order-events', stream_enabled: true, encryption_type: 'KMS' },
            cqrs: { enabled: true, command_table_name: 'order-commands', query_table_name: 'order-projections' },
            vpc_ref: vpc.vpc, subnet_refs: subnets.resources[:private_subnets].values, security_group_refs: [service_sg]
          })
        end

        def create_api_gateway(user_service, order_service)
          api_gateway_microservices(:platform_api, {
            api_name: 'microservices-platform-api', api_description: 'Unified API for microservices platform',
            service_endpoints: build_service_endpoints(user_service, order_service),
            versioning: { strategy: 'PATH', default_version: 'v1', versions: %w[v1 v2] },
            rate_limit: { enabled: true, burst_limit: 5000, rate_limit: 10_000.0 },
            cors: { enabled: true, allow_origins: ['https://app.example.com'], allow_credentials: true },
            xray_tracing_enabled: true, cache_cluster_enabled: true
          })
        end

        def build_service_endpoints(user_service, order_service)
          [{ name: 'users', base_path: 'users', methods: [{ path: '/', method: 'GET' }, { path: '/', method: 'POST' }, { path: '/{id}', method: 'GET' }, { path: '/{id}', method: 'PUT' }],
             integration: { type: 'HTTP_PROXY', uri: "http://#{user_service.outputs[:service_discovery_endpoint]}/{proxy}", connection_type: 'VPC_LINK' } },
           { name: 'orders', base_path: 'orders', methods: [{ path: '/', method: 'POST', api_key_required: true }, { path: '/{id}', method: 'GET' }, { path: '/{id}/status', method: 'GET' }],
             integration: { type: 'AWS_PROXY', uri: order_service.outputs[:command_handler_arn] } }]
        end

        def create_observability(cluster_ref, user_service, order_service)
          service_mesh_observability(:platform_observability, {
            mesh_name: 'microservices-platform',
            services: [{ name: 'user-service', cluster_ref: cluster_ref, task_definition_ref: user_service.resources[:task_definition], port: 8080 },
                       { name: 'order-service', cluster_ref: cluster_ref, deployment_ref: order_service.resources[:command_handler], port: 80, protocol: 'HTTP' }],
            tracing: { enabled: true, sampling_rate: 0.1 }, metrics: { enabled: true, detailed_metrics: true, prometheus_enabled: true },
            alerting: { enabled: true, latency_threshold_ms: 500, error_rate_threshold: 0.01, notification_channel_ref: aws_sns_topic(:alerts, { name: 'platform-alerts' }) },
            log_aggregation: { enabled: true, retention_days: 30, insights_queries: [{ name: 'API Errors', query: 'fields @timestamp, service, error | filter error IS NOT NULL | stats count() by service' },
                                                                                       { name: 'Slow Requests', query: 'fields @timestamp, service, duration | filter duration > 1000 | sort @timestamp desc' }] }
          })
        end
      end
    end
  end
end
