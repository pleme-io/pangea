# Advanced Patterns: Mastering Complex Infrastructure with Pangea

This guide explores sophisticated infrastructure patterns using Pangea's component and architecture systems. Learn how to build enterprise-grade, scalable infrastructure solutions that leverage Pangea's unique capabilities for complex, real-world scenarios.

## Architecture System Overview

Pangea provides three levels of abstraction for building infrastructure:

1. **Resource Functions**: Type-safe individual resources (aws_instance, aws_vpc)
2. **Components**: Reusable infrastructure patterns (secure_vpc, web_application) 
3. **Architectures**: Complete application solutions (web_application_architecture, microservices_platform)

### The Abstraction Hierarchy

```
Architecture Functions    (Complete Solutions)
    ↓ composes
Component Functions      (Reusable Patterns)
    ↓ uses  
Resource Functions       (Individual Resources)
    ↓ generates
Terraform JSON          (Infrastructure as Code)
```

## Advanced Component Patterns

### 1. Composable Security Components

Build security-first components that can be composed together:

```ruby
# security-components.rb

# Base security component with comprehensive controls
def secure_vpc_component(name, config)
  validated_config = SecureVpcConfig.new(config)
  
  # VPC with security defaults
  vpc_ref = aws_vpc(name, {
    cidr_block: validated_config.cidr_block,
    enable_dns_hostnames: true,
    enable_dns_support: true,
    tags: {
      Name: "#{name}-VPC",
      SecurityLevel: validated_config.security_level,
      ComplianceFramework: validated_config.compliance_framework
    }
  })
  
  # VPC Flow Logs for security monitoring
  flow_logs_role = aws_iam_role(:"#{name}_flow_logs_role", {
    assume_role_policy: jsonencode({
      Version: "2012-10-17",
      Statement: [
        {
          Action: "sts:AssumeRole",
          Effect: "Allow",
          Principal: { Service: "vpc-flow-logs.amazonaws.com" }
        }
      ]
    })
  })
  
  aws_iam_role_policy_attachment(:"#{name}_flow_logs_policy", {
    role: flow_logs_role.name,
    policy_arn: "arn:aws:iam::aws:policy/service-role/VPCFlowLogsDeliveryRolePolicy"
  })
  
  flow_logs_ref = aws_flow_log(:"#{name}_flow_logs", {
    iam_role_arn: flow_logs_role.arn,
    log_destination_type: "cloud-watch-logs",
    log_group_name: "/aws/vpc/flowlogs/#{name}",
    resource_id: vpc_ref.id,
    resource_type: "VPC",
    traffic_type: "ALL",
    
    tags: {
      Name: "#{name}-FlowLogs",
      Purpose: "SecurityMonitoring"
    }
  })
  
  # Default security group with deny-all
  default_sg = aws_security_group(:"#{name}_default", {
    name_prefix: "#{name}-default-",
    vpc_id: vpc_ref.id,
    description: "Default security group - deny all traffic",
    
    # Explicit deny rules (override AWS default allow-all egress)
    egress_rules: [
      {
        from_port: 0,
        to_port: 65535,
        protocol: "-1",
        cidr_blocks: ["127.0.0.1/32"],  # Deny to localhost only
        description: "Deny all traffic - explicit rule"
      }
    ],
    
    tags: {
      Name: "#{name}-DefaultDenyAll",
      Purpose: "SecurityBaseline"
    }
  })
  
  # Network ACL with restrictive rules
  network_acl = aws_network_acl(:"#{name}_restrictive", {
    vpc_id: vpc_ref.id,
    
    # Explicit ingress rules
    ingress: [
      {
        protocol: "tcp",
        rule_no: 100,
        action: "allow",
        cidr_block: validated_config.cidr_block,
        from_port: 80,
        to_port: 80
      },
      {
        protocol: "tcp", 
        rule_no: 110,
        action: "allow",
        cidr_block: validated_config.cidr_block,
        from_port: 443,
        to_port: 443
      }
    ],
    
    tags: {
      Name: "#{name}-RestrictiveACL",
      SecurityLevel: validated_config.security_level
    }
  })
  
  ComponentReference.new(
    name: name,
    type: 'secure_vpc',
    resources: {
      vpc: vpc_ref,
      flow_logs: flow_logs_ref,
      default_security_group: default_sg,
      network_acl: network_acl
    },
    security_features: {
      flow_logs_enabled: true,
      default_deny_sg: true,
      restrictive_nacl: true,
      compliance_level: validated_config.compliance_framework
    }
  )
end

# Zero-trust network component
def zero_trust_network_component(name, config)
  validated_config = ZeroTrustConfig.new(config)
  
  # Build on secure VPC
  base_vpc = secure_vpc_component(:"#{name}_base", {
    cidr_block: validated_config.cidr_block,
    security_level: "high",
    compliance_framework: "SOC2"
  })
  
  # Microsegmented subnets with separate security groups
  trust_zones = validated_config.trust_zones
  subnet_components = {}
  
  trust_zones.each_with_index do |zone, index|
    # Create subnet for each trust zone
    subnet_ref = aws_subnet(:"#{name}_#{zone[:name]}", {
      vpc_id: base_vpc.resources[:vpc].id,
      cidr_block: "#{validated_config.cidr_block.split('/')[0].split('.')[0..2].join('.')}.#{index + 10}.0/24",
      availability_zone: zone[:availability_zone],
      
      tags: {
        Name: "#{name}-#{zone[:name]}-Subnet",
        TrustZone: zone[:trust_level],
        ComplianceRequired: zone[:compliance_required].to_s
      }
    })
    
    # Zone-specific security group
    zone_sg = aws_security_group(:"#{name}_#{zone[:name]}_sg", {
      name_prefix: "#{name}-#{zone[:name]}-",
      vpc_id: base_vpc.resources[:vpc].id,
      description: "Security group for #{zone[:name]} trust zone",
      
      ingress_rules: zone[:allowed_ingress].map do |rule|
        {
          from_port: rule[:port],
          to_port: rule[:port],
          protocol: rule[:protocol],
          source_security_group_id: rule[:source_zone] ? 
            "${aws_security_group.#{name}_#{rule[:source_zone]}_sg.id}" : nil,
          cidr_blocks: rule[:cidr_blocks] || nil
        }
      end,
      
      tags: {
        Name: "#{name}-#{zone[:name]}-SG",
        TrustZone: zone[:trust_level]
      }
    })
    
    subnet_components[zone[:name]] = {
      subnet: subnet_ref,
      security_group: zone_sg,
      trust_level: zone[:trust_level]
    }
  end
  
  # WAF for application-level protection
  waf_web_acl = aws_wafv2_web_acl(:"#{name}_waf", {
    name: "#{name}-WebACL",
    description: "WAF rules for zero-trust network",
    scope: "REGIONAL",
    
    default_action: {
      allow: {}
    },
    
    rule: [
      {
        name: "RateLimitRule",
        priority: 1,
        action: { block: {} },
        statement: {
          rate_based_statement: {
            limit: 2000,
            aggregate_key_type: "IP"
          }
        },
        visibility_config: {
          sampled_requests_enabled: true,
          cloudwatch_metrics_enabled: true,
          metric_name: "RateLimitRule"
        }
      }
    ],
    
    tags: {
      Name: "#{name}-WAF",
      Purpose: "ZeroTrustProtection"
    }
  })
  
  ComponentReference.new(
    name: name,
    type: 'zero_trust_network',
    base_components: { secure_vpc: base_vpc },
    resources: {
      subnets: subnet_components,
      waf: waf_web_acl
    },
    trust_zones: trust_zones.map { |z| z[:name] }
  )
end

class SecureVpcConfig < Dry::Struct
  attribute :cidr_block, Types::String.constrained(
    format: /^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\/\d{1,2}$/
  )
  attribute :security_level, Types::String.constrained(
    included_in: %w[standard high critical]
  )
  attribute :compliance_framework, Types::String.constrained(
    included_in: %w[SOC2 HIPAA PCI FedRAMP]
  )
end

class ZeroTrustConfig < Dry::Struct
  attribute :cidr_block, Types::String
  attribute :trust_zones, Types::Array.of(TrustZone)
end

class TrustZone < Dry::Struct
  attribute :name, Types::String
  attribute :trust_level, Types::String.constrained(
    included_in: %w[public restricted confidential]
  )
  attribute :availability_zone, Types::String
  attribute :compliance_required, Types::Bool
  attribute :allowed_ingress, Types::Array.of(IngressRule)
end

class IngressRule < Dry::Struct
  attribute :port, Types::Integer
  attribute :protocol, Types::String
  attribute :source_zone, Types::String.optional
  attribute :cidr_blocks, Types::Array.of(Types::String).optional
end
```

### 2. Multi-Cloud Component Abstraction

Create components that can deploy to multiple cloud providers:

```ruby
# multi-cloud-components.rb

def container_orchestration_component(name, config)
  validated_config = ContainerConfig.new(config)
  
  case validated_config.provider
  when 'aws'
    deploy_ecs_cluster(name, validated_config)
  when 'gcp'
    deploy_gke_cluster(name, validated_config)
  when 'azure'
    deploy_aks_cluster(name, validated_config)
  else
    raise ArgumentError, "Unsupported provider: #{validated_config.provider}"
  end
end

def deploy_ecs_cluster(name, config)
  # ECS implementation
  cluster_ref = aws_ecs_cluster(name, {
    name: "#{name}-cluster",
    capacity_providers: ["FARGATE", "FARGATE_SPOT"],
    
    default_capacity_provider_strategy: [
      {
        capacity_provider: "FARGATE",
        weight: config.fargate_weight,
        base: config.fargate_base
      },
      {
        capacity_provider: "FARGATE_SPOT", 
        weight: config.spot_weight
      }
    ],
    
    setting: [
      {
        name: "containerInsights",
        value: config.monitoring_enabled ? "enabled" : "disabled"
      }
    ],
    
    tags: {
      Name: "#{name}-ECS-Cluster",
      Provider: "AWS",
      OrchestrationEngine: "ECS"
    }
  })
  
  # Service discovery namespace
  service_discovery = aws_service_discovery_private_dns_namespace(:"#{name}_sd", {
    name: "#{config.domain_name}",
    vpc: config.vpc_id,
    
    tags: {
      Name: "#{name}-ServiceDiscovery"
    }
  })
  
  ComponentReference.new(
    name: name,
    type: 'container_orchestration',
    provider: 'aws',
    resources: {
      cluster: cluster_ref,
      service_discovery: service_discovery
    },
    capabilities: {
      auto_scaling: true,
      service_discovery: true,
      spot_instances: config.spot_weight > 0
    }
  )
end

class ContainerConfig < Dry::Struct
  attribute :provider, Types::String.constrained(
    included_in: %w[aws gcp azure]
  )
  attribute :domain_name, Types::String
  attribute :vpc_id, Types::String
  attribute :fargate_weight, Types::Integer.constrained(gteq: 0, lteq: 100).default(70)
  attribute :spot_weight, Types::Integer.constrained(gteq: 0, lteq: 100).default(30)
  attribute :fargate_base, Types::Integer.constrained(gteq: 0).default(2)
  attribute :monitoring_enabled, Types::Bool.default(true)
end
```

## Complete Architecture Patterns

### 1. Event-Driven Microservices Architecture

```ruby
# event-driven-architecture.rb

def event_driven_microservices_architecture(name, config)
  validated_config = EventDrivenConfig.new(config)
  
  # Foundation networking with zero-trust
  networking = zero_trust_network_component(:"#{name}_network", {
    cidr_block: validated_config.vpc_cidr,
    trust_zones: [
      {
        name: "public",
        trust_level: "public", 
        availability_zone: "us-east-1a",
        compliance_required: false,
        allowed_ingress: [
          { port: 80, protocol: "tcp", cidr_blocks: ["0.0.0.0/0"] },
          { port: 443, protocol: "tcp", cidr_blocks: ["0.0.0.0/0"] }
        ]
      },
      {
        name: "application",
        trust_level: "restricted",
        availability_zone: "us-east-1b", 
        compliance_required: true,
        allowed_ingress: [
          { port: 8080, protocol: "tcp", source_zone: "public" }
        ]
      },
      {
        name: "data",
        trust_level: "confidential",
        availability_zone: "us-east-1c",
        compliance_required: true, 
        allowed_ingress: [
          { port: 5432, protocol: "tcp", source_zone: "application" }
        ]
      }
    ]
  })
  
  # Container orchestration platform
  container_platform = container_orchestration_component(:"#{name}_containers", {
    provider: "aws",
    domain_name: "#{name}.internal",
    vpc_id: networking.resources[:subnets][:application][:subnet].id
  })
  
  # Event streaming infrastructure
  event_streaming = create_event_streaming_infrastructure(name, {
    vpc_id: networking.base_components[:secure_vpc].resources[:vpc].id,
    subnets: [
      networking.resources[:subnets][:application][:subnet].id,
      networking.resources[:subnets][:data][:subnet].id
    ]
  })
  
  # API Gateway for external access
  api_gateway = aws_api_gateway_rest_api(:"#{name}_api", {
    name: "#{name}-API",
    description: "API Gateway for event-driven microservices",
    endpoint_configuration: {
      types: ["REGIONAL"]
    },
    
    tags: {
      Name: "#{name}-APIGateway",
      Architecture: "EventDriven"
    }
  })
  
  # Service mesh for inter-service communication
  service_mesh = create_service_mesh(name, {
    container_cluster: container_platform.resources[:cluster],
    service_discovery: container_platform.resources[:service_discovery],
    trust_zones: networking.trust_zones
  })
  
  # Individual microservices
  microservices = validated_config.services.map do |service_config|
    create_microservice(
      "#{name}_#{service_config[:name]}",
      service_config.merge({
        cluster_arn: container_platform.resources[:cluster].arn,
        service_discovery_namespace: container_platform.resources[:service_discovery].id,
        event_stream_arns: event_streaming[:streams].map { |s| s.arn },
        service_mesh: service_mesh
      })
    )
  end
  
  # Monitoring and observability
  observability = create_observability_stack(name, {
    vpc: networking.base_components[:secure_vpc].resources[:vpc],
    services: microservices,
    event_streams: event_streaming[:streams],
    api_gateway: api_gateway
  })
  
  ArchitectureReference.new(
    name: name,
    type: 'event_driven_microservices',
    components: {
      networking: networking,
      container_platform: container_platform,
      api_gateway: api_gateway,
      service_mesh: service_mesh,
      microservices: microservices,
      observability: observability
    },
    architecture_attributes: {
      event_driven: true,
      microservices_count: microservices.length,
      zero_trust_networking: true,
      service_mesh_enabled: true,
      multi_az_deployment: true
    },
    estimated_monthly_cost: calculate_architecture_cost(microservices, event_streaming, observability),
    security_compliance_score: calculate_security_score(networking, service_mesh, observability)
  )
end

def create_event_streaming_infrastructure(name, config)
  # Kinesis streams for different event types
  streams = {
    user_events: aws_kinesis_stream(:"#{name}_user_events", {
      name: "#{name}-user-events",
      shard_count: 2,
      retention_period: 168, # 7 days
      encryption_type: "KMS",
      kms_key_id: "alias/aws/kinesis",
      
      tags: {
        Name: "#{name}-UserEvents",
        EventType: "UserInteractions"
      }
    }),
    
    system_events: aws_kinesis_stream(:"#{name}_system_events", {
      name: "#{name}-system-events", 
      shard_count: 1,
      retention_period: 24, # 1 day
      encryption_type: "KMS",
      
      tags: {
        Name: "#{name}-SystemEvents",
        EventType: "SystemMetrics"
      }
    }),
    
    business_events: aws_kinesis_stream(:"#{name}_business_events", {
      name: "#{name}-business-events",
      shard_count: 3,
      retention_period: 720, # 30 days 
      encryption_type: "KMS",
      
      tags: {
        Name: "#{name}-BusinessEvents",
        EventType: "BusinessCritical"
      }
    })
  }
  
  # Kinesis Analytics for real-time processing
  analytics_app = aws_kinesis_analytics_application(:"#{name}_analytics", {
    name: "#{name}-event-analytics",
    description: "Real-time event analytics",
    
    inputs: {
      name_prefix: "event_input",
      kinesis_stream: {
        resource_arn: streams[:user_events].arn,
        role_arn: aws_iam_role(:"#{name}_analytics_role", {
          assume_role_policy: jsonencode({
            Version: "2012-10-17",
            Statement: [{
              Action: "sts:AssumeRole",
              Effect: "Allow", 
              Principal: { Service: "kinesisanalytics.amazonaws.com" }
            }]
          })
        }).arn
      },
      
      schema: {
        record_columns: [
          { name: "user_id", sql_type: "VARCHAR(64)" },
          { name: "event_type", sql_type: "VARCHAR(32)" },
          { name: "timestamp", sql_type: "TIMESTAMP" },
          { name: "properties", sql_type: "VARCHAR(2048)" }
        ],
        record_format: {
          record_format_type: "JSON"
        }
      }
    },
    
    tags: {
      Name: "#{name}-EventAnalytics"
    }
  })
  
  { streams: streams.values, analytics: analytics_app }
end

def create_microservice(name, config)
  # ECS Task Definition
  task_definition = aws_ecs_task_definition(name, {
    family: name,
    network_mode: "awsvpc",
    requires_compatibilities: ["FARGATE"],
    cpu: config[:cpu] || "256",
    memory: config[:memory] || "512",
    execution_role_arn: config[:execution_role_arn],
    task_role_arn: config[:task_role_arn],
    
    container_definitions: jsonencode([
      {
        name: name,
        image: config[:image],
        portMappings: [
          {
            containerPort: config[:port] || 8080,
            protocol: "tcp"
          }
        ],
        environment: config[:environment_variables] || [],
        secrets: config[:secrets] || [],
        logConfiguration: {
          logDriver: "awslogs",
          options: {
            "awslogs-group": "/ecs/#{name}",
            "awslogs-region": "us-east-1",
            "awslogs-stream-prefix": "ecs"
          }
        },
        healthCheck: {
          command: ["CMD-SHELL", config[:health_check_command] || "curl -f http://localhost:8080/health || exit 1"],
          interval: 30,
          timeout: 5,
          retries: 3,
          startPeriod: 60
        }
      }
    ]),
    
    tags: {
      Name: name,
      ServiceType: config[:service_type] || "microservice"
    }
  })
  
  # ECS Service
  ecs_service = aws_ecs_service(:"#{name}_service", {
    name: "#{name}-service",
    cluster: config[:cluster_arn],
    task_definition: task_definition.arn,
    desired_count: config[:desired_count] || 2,
    launch_type: "FARGATE",
    
    network_configuration: {
      subnets: config[:subnets],
      security_groups: [config[:security_group_id]],
      assign_public_ip: false
    },
    
    service_registries: [
      {
        registry_arn: aws_service_discovery_service(:"#{name}_discovery", {
          name: name,
          dns_config: {
            namespace_id: config[:service_discovery_namespace],
            dns_records: [
              {
                ttl: 10,
                type: "A"
              }
            ]
          },
          health_check_grace_period_seconds: 60
        }).arn,
        port: config[:port] || 8080
      }
    ],
    
    deployment_configuration: {
      maximum_percent: 200,
      minimum_healthy_percent: 100,
      deployment_circuit_breaker: {
        enable: true,
        rollback: true
      }
    },
    
    tags: {
      Name: "#{name}-Service",
      MicroserviceType: config[:service_type]
    }
  })
  
  ComponentReference.new(
    name: name,
    type: 'microservice',
    resources: {
      task_definition: task_definition,
      service: ecs_service
    },
    service_config: config
  )
end

class EventDrivenConfig < Dry::Struct
  attribute :vpc_cidr, Types::String
  attribute :services, Types::Array.of(MicroserviceConfig)
  attribute :enable_service_mesh, Types::Bool.default(true)
  attribute :monitoring_level, Types::String.constrained(
    included_in: %w[basic standard comprehensive]
  ).default("standard")
end

class MicroserviceConfig < Dry::Struct
  attribute :name, Types::String
  attribute :image, Types::String
  attribute :port, Types::Integer.default(8080)
  attribute :cpu, Types::String.default("256")
  attribute :memory, Types::String.default("512")
  attribute :desired_count, Types::Integer.default(2)
  attribute :service_type, Types::String.default("api")
  attribute :environment_variables, Types::Array.of(EnvironmentVariable).default([])
  attribute :health_check_command, Types::String.optional
end

class EnvironmentVariable < Dry::Struct
  attribute :name, Types::String
  attribute :value, Types::String
end
```

### 2. ML/AI Platform Architecture

```ruby
# ml-platform-architecture.rb

def ml_platform_architecture(name, config)
  validated_config = MLPlatformConfig.new(config)
  
  # Data lake foundation
  data_lake = create_data_lake_infrastructure(name, {
    raw_data_retention_days: validated_config.data_retention.raw,
    processed_data_retention_days: validated_config.data_retention.processed,
    enable_data_catalog: true,
    enable_cross_region_replication: validated_config.disaster_recovery_enabled
  })
  
  # ML training infrastructure
  training_infrastructure = create_ml_training_infrastructure(name, {
    instance_types: validated_config.training_instance_types,
    max_parallel_jobs: validated_config.max_parallel_training_jobs,
    enable_spot_instances: validated_config.cost_optimization.use_spot_instances,
    training_data_sources: data_lake[:processed_buckets]
  })
  
  # Model serving infrastructure
  serving_infrastructure = create_model_serving_infrastructure(name, {
    auto_scaling_config: validated_config.serving_auto_scaling,
    endpoint_types: validated_config.endpoint_types,
    enable_multi_model_endpoints: validated_config.enable_multi_model_endpoints
  })
  
  # ML pipelines and orchestration
  ml_pipelines = create_ml_pipeline_infrastructure(name, {
    data_sources: data_lake,
    training_infrastructure: training_infrastructure,
    serving_infrastructure: serving_infrastructure,
    pipeline_schedule: validated_config.pipeline_schedule
  })
  
  # Feature store
  feature_store = create_feature_store(name, {
    online_storage_config: validated_config.feature_store.online_storage,
    offline_storage_config: validated_config.feature_store.offline_storage,
    data_lake_integration: data_lake
  })
  
  # ML monitoring and observability
  ml_monitoring = create_ml_monitoring_infrastructure(name, {
    model_endpoints: serving_infrastructure[:endpoints],
    training_jobs: training_infrastructure[:training_cluster],
    data_drift_detection: validated_config.monitoring.enable_data_drift_detection,
    model_performance_monitoring: validated_config.monitoring.enable_model_performance_monitoring
  })
  
  ArchitectureReference.new(
    name: name,
    type: 'ml_platform',
    components: {
      data_lake: data_lake,
      training: training_infrastructure,
      serving: serving_infrastructure,
      pipelines: ml_pipelines,
      feature_store: feature_store,
      monitoring: ml_monitoring
    },
    architecture_attributes: {
      supports_batch_training: true,
      supports_real_time_inference: true,
      auto_scaling_enabled: validated_config.serving_auto_scaling.enabled,
      multi_model_serving: validated_config.enable_multi_model_endpoints,
      feature_store_enabled: true,
      ml_ops_pipeline: true
    },
    estimated_monthly_cost: calculate_ml_platform_cost(
      training_infrastructure, 
      serving_infrastructure, 
      data_lake,
      validated_config
    )
  )
end

def create_feature_store(name, config)
  # DynamoDB for online features (low latency)
  online_feature_store = aws_dynamodb_table(:"#{name}_online_features", {
    name: "#{name}-online-features",
    billing_mode: config[:online_storage_config][:billing_mode] || "PAY_PER_REQUEST",
    
    attribute: [
      { name: "feature_group_name", type: "S" },
      { name: "record_identifier", type: "S" },
      { name: "event_time", type: "N" }
    ],
    
    hash_key: "feature_group_name",
    range_key: "record_identifier",
    
    global_secondary_index: [
      {
        name: "EventTimeIndex",
        hash_key: "feature_group_name",
        range_key: "event_time",
        projection_type: "ALL"
      }
    ],
    
    ttl: {
      attribute_name: "ttl",
      enabled: true
    },
    
    point_in_time_recovery: {
      enabled: true
    },
    
    stream_enabled: true,
    stream_view_type: "NEW_AND_OLD_IMAGES",
    
    tags: {
      Name: "#{name}-OnlineFeatureStore",
      Purpose: "MLFeatureServing"
    }
  })
  
  # S3 for offline features (batch processing)
  offline_feature_store = aws_s3_bucket(:"#{name}_offline_features", {
    bucket_prefix: "#{name}-offline-features-",
    
    versioning: {
      enabled: true
    },
    
    lifecycle_configuration: {
      rule: [
        {
          id: "feature_lifecycle",
          enabled: true,
          expiration: {
            days: config[:offline_storage_config][:retention_days] || 365
          },
          noncurrent_version_expiration: {
            days: 30
          },
          transition: [
            {
              days: 30,
              storage_class: "STANDARD_IA"
            },
            {
              days: 90,
              storage_class: "GLACIER"
            }
          ]
        }
      ]
    },
    
    server_side_encryption_configuration: {
      rule: {
        apply_server_side_encryption_by_default: {
          sse_algorithm: "AES256"
        }
      }
    },
    
    tags: {
      Name: "#{name}-OfflineFeatureStore",
      Purpose: "MLFeatureStorage"
    }
  })
  
  # SageMaker Feature Store feature groups
  feature_groups = config[:feature_groups]&.map do |fg_config|
    aws_sagemaker_feature_group(:"#{name}_#{fg_config[:name]}", {
      feature_group_name: "#{name}-#{fg_config[:name]}",
      record_identifier_feature_name: fg_config[:record_identifier] || "id",
      event_time_feature_name: fg_config[:event_time_feature] || "event_time",
      
      feature_definition: fg_config[:features].map do |feature|
        {
          feature_name: feature[:name],
          feature_type: feature[:type]
        }
      end,
      
      online_store_config: {
        enable_online_store: true
      },
      
      offline_store_config: {
        s3_storage_config: {
          s3_uri: "s3://#{offline_feature_store.id}/feature-groups/#{fg_config[:name]}/"
        },
        disable_glue_table_creation: false,
        data_catalog_config: {
          table_name: "#{name}_#{fg_config[:name]}_features",
          catalog: "AwsDataCatalog",
          database: "#{name}_feature_store_db"
        }
      },
      
      tags: {
        Name: "#{name}-#{fg_config[:name]}-FeatureGroup",
        FeatureGroupType: fg_config[:type] || "batch"
      }
    })
  end || []
  
  {
    online_store: online_feature_store,
    offline_store: offline_feature_store,
    feature_groups: feature_groups,
    capabilities: {
      real_time_features: true,
      batch_features: true,
      feature_versioning: true,
      point_in_time_lookup: true
    }
  }
end

class MLPlatformConfig < Dry::Struct
  attribute :data_retention, DataRetentionConfig
  attribute :training_instance_types, Types::Array.of(Types::String).default(["ml.m5.large"])
  attribute :max_parallel_training_jobs, Types::Integer.default(5)
  attribute :cost_optimization, CostOptimizationConfig
  attribute :serving_auto_scaling, AutoScalingConfig
  attribute :endpoint_types, Types::Array.of(Types::String).default(["real_time"])
  attribute :enable_multi_model_endpoints, Types::Bool.default(false)
  attribute :pipeline_schedule, Types::String.default("daily")
  attribute :feature_store, FeatureStoreConfig
  attribute :monitoring, MLMonitoringConfig
  attribute :disaster_recovery_enabled, Types::Bool.default(false)
end

class DataRetentionConfig < Dry::Struct
  attribute :raw, Types::Integer.default(90)
  attribute :processed, Types::Integer.default(365)
end

class CostOptimizationConfig < Dry::Struct
  attribute :use_spot_instances, Types::Bool.default(true)
  attribute :enable_auto_shutdown, Types::Bool.default(true)
  attribute :reserved_instance_percentage, Types::Integer.default(50)
end

class AutoScalingConfig < Dry::Struct
  attribute :enabled, Types::Bool.default(true)
  attribute :min_instances, Types::Integer.default(1)
  attribute :max_instances, Types::Integer.default(10)
  attribute :target_cpu_utilization, Types::Integer.default(70)
end

class FeatureStoreConfig < Dry::Struct
  attribute :online_storage, OnlineStorageConfig
  attribute :offline_storage, OfflineStorageConfig
  attribute :feature_groups, Types::Array.of(FeatureGroupConfig).default([])
end

class OnlineStorageConfig < Dry::Struct
  attribute :billing_mode, Types::String.default("PAY_PER_REQUEST")
  attribute :enable_ttl, Types::Bool.default(true)
end

class OfflineStorageConfig < Dry::Struct
  attribute :retention_days, Types::Integer.default(365)
  attribute :storage_class_transition, Types::Bool.default(true)
end

class FeatureGroupConfig < Dry::Struct
  attribute :name, Types::String
  attribute :type, Types::String.default("batch")
  attribute :record_identifier, Types::String.default("id")
  attribute :event_time_feature, Types::String.default("event_time")
  attribute :features, Types::Array.of(FeatureDefinition)
end

class FeatureDefinition < Dry::Struct
  attribute :name, Types::String
  attribute :type, Types::String.constrained(
    included_in: %w[Integral Fractional String]
  )
end

class MLMonitoringConfig < Dry::Struct
  attribute :enable_data_drift_detection, Types::Bool.default(true)
  attribute :enable_model_performance_monitoring, Types::Bool.default(true)
  attribute :alert_thresholds, AlertThresholdsConfig
end

class AlertThresholdsConfig < Dry::Struct
  attribute :accuracy_degradation_threshold, Types::Float.default(0.05)
  attribute :data_drift_threshold, Types::Float.default(0.1)
  attribute :latency_threshold_ms, Types::Integer.default(500)
end
```

## Usage Examples

### Deploying Event-Driven Architecture

```ruby
template :complete_event_platform do
  # Deploy comprehensive event-driven microservices platform
  platform = event_driven_microservices_architecture(:ecommerce_platform, {
    vpc_cidr: "10.0.0.0/16",
    services: [
      {
        name: "user_service",
        image: "myregistry/user-service:latest",
        port: 8080,
        service_type: "api",
        desired_count: 3,
        environment_variables: [
          { name: "DB_HOST", value: "users.db.internal" },
          { name: "LOG_LEVEL", value: "info" }
        ]
      },
      {
        name: "order_service", 
        image: "myregistry/order-service:latest",
        port: 8080,
        service_type: "api",
        desired_count: 5,
        cpu: "512",
        memory: "1024"
      },
      {
        name: "inventory_service",
        image: "myregistry/inventory-service:latest",
        port: 8080,
        service_type: "api",
        desired_count: 2
      },
      {
        name: "notification_service",
        image: "myregistry/notification-service:latest",
        port: 8080,
        service_type: "worker",
        desired_count: 2
      }
    ],
    enable_service_mesh: true,
    monitoring_level: "comprehensive"
  })
  
  # Output key architecture endpoints
  output :api_gateway_url do
    value platform.components[:api_gateway].invoke_url
    description "Main API Gateway endpoint"
  end
  
  output :service_discovery_namespace do
    value platform.components[:container_platform].resources[:service_discovery].name
    description "Internal service discovery namespace"
  end
  
  output :estimated_monthly_cost do
    value platform.estimated_monthly_cost
    description "Estimated monthly AWS cost in USD"
  end
end
```

### Deploying ML Platform

```ruby
template :ml_research_platform do
  # Deploy comprehensive ML platform for research and production
  ml_platform = ml_platform_architecture(:research_platform, {
    data_retention: {
      raw: 180,      # 6 months for raw data
      processed: 730  # 2 years for processed data
    },
    training_instance_types: ["ml.p3.2xlarge", "ml.m5.4xlarge"],
    max_parallel_training_jobs: 10,
    cost_optimization: {
      use_spot_instances: true,
      enable_auto_shutdown: true,
      reserved_instance_percentage: 30
    },
    serving_auto_scaling: {
      enabled: true,
      min_instances: 2,
      max_instances: 20,
      target_cpu_utilization: 60
    },
    endpoint_types: ["real_time", "batch_transform"],
    enable_multi_model_endpoints: true,
    pipeline_schedule: "hourly",
    feature_store: {
      online_storage: {
        billing_mode: "PROVISIONED",
        enable_ttl: true
      },
      offline_storage: {
        retention_days: 730,
        storage_class_transition: true
      },
      feature_groups: [
        {
          name: "user_features",
          type: "real_time",
          features: [
            { name: "user_id", type: "String" },
            { name: "age", type: "Integral" },
            { name: "spending_score", type: "Fractional" },
            { name: "last_purchase_days", type: "Integral" }
          ]
        },
        {
          name: "product_features",
          type: "batch",
          features: [
            { name: "product_id", type: "String" },
            { name: "category", type: "String" },
            { name: "price", type: "Fractional" },
            { name: "popularity_score", type: "Fractional" }
          ]
        }
      ]
    },
    monitoring: {
      enable_data_drift_detection: true,
      enable_model_performance_monitoring: true,
      alert_thresholds: {
        accuracy_degradation_threshold: 0.03,
        data_drift_threshold: 0.08,
        latency_threshold_ms: 200
      }
    },
    disaster_recovery_enabled: true
  })
  
  # Output ML platform endpoints and information
  output :feature_store_online_endpoint do
    value ml_platform.components[:feature_store][:online_store].name
    description "Online feature store endpoint"
  end
  
  output :data_lake_buckets do
    value ml_platform.components[:data_lake][:buckets].map { |b| b.id }
    description "Data lake S3 bucket names"
  end
  
  output :training_cluster_arn do
    value ml_platform.components[:training][:training_cluster].arn
    description "SageMaker training cluster ARN"
  end
end
```

## Summary

Pangea's advanced patterns enable:

1. **Component Composition**: Build complex infrastructure from reusable components
2. **Architecture Abstractions**: Deploy complete application platforms with single functions
3. **Multi-Cloud Support**: Abstract infrastructure patterns across cloud providers
4. **Security-First Design**: Zero-trust networking and compliance-ready components
5. **Enterprise Scalability**: ML platforms, event-driven architectures, and microservices

These patterns demonstrate how Pangea scales from simple resource management to enterprise-grade infrastructure platforms while maintaining type safety, modularity, and automation-first design.

<function_calls>
<invoke name="TodoWrite">
<parameter name="todos">[{"id": "1", "content": "Create guides directory structure", "status": "completed", "priority": "high"}, {"id": "2", "content": "Write getting started guide", "status": "completed", "priority": "high"}, {"id": "3", "content": "Write template isolation guide", "status": "completed", "priority": "high"}, {"id": "4", "content": "Write multi-environment management guide", "status": "completed", "priority": "high"}, {"id": "5", "content": "Write type-safe infrastructure guide", "status": "completed", "priority": "medium"}, {"id": "6", "content": "Write migration from Terraform guide", "status": "completed", "priority": "medium"}, {"id": "7", "content": "Write CI/CD integration guide", "status": "completed", "priority": "medium"}, {"id": "8", "content": "Write advanced patterns guide", "status": "completed", "priority": "low"}, {"id": "9", "content": "Create guides README index", "status": "in_progress", "priority": "low"}]