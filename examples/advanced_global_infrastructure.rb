# frozen_string_literal: true
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


require 'pangea'

# Advanced Global Infrastructure Example
# Demonstrates multi-region active-active deployment with DR and global service mesh
template :global_infrastructure do
  include Pangea::Components
  
  # Multi-Region Active-Active Infrastructure
  # Deploy application across three regions with automatic failover
  global_app = multi_region_active_active(:global_platform, {
    deployment_name: "global-ecommerce-platform",
    domain_name: "api.globalstore.com",
    
    regions: [
      {
        region: "us-east-1",
        vpc_cidr: "10.0.0.0/16",
        availability_zones: ["us-east-1a", "us-east-1b", "us-east-1c"],
        is_primary: true,
        database_priority: 100,
        write_weight: 100
      },
      {
        region: "eu-west-1",
        vpc_cidr: "10.1.0.0/16",
        availability_zones: ["eu-west-1a", "eu-west-1b", "eu-west-1c"],
        is_primary: false,
        database_priority: 90,
        write_weight: 80
      },
      {
        region: "ap-southeast-1",
        vpc_cidr: "10.2.0.0/16",
        availability_zones: ["ap-southeast-1a", "ap-southeast-1b"],
        is_primary: false,
        database_priority: 80,
        write_weight: 60
      }
    ],
    
    consistency: {
      consistency_model: "eventual",
      conflict_resolution: "timestamp",
      replication_lag_threshold_ms: 100,
      write_quorum_size: 2,
      read_quorum_size: 1
    },
    
    global_database: {
      engine: "aurora-postgresql",
      engine_version: "14.6",
      instance_class: "db.r6g.xlarge",
      backup_retention_days: 7,
      enable_global_write_forwarding: true,
      storage_encrypted: true
    },
    
    application: {
      name: "ecommerce-api",
      port: 443,
      protocol: "HTTPS",
      health_check_path: "/api/v1/health",
      container_image: "globalstore/api:latest",
      task_cpu: 1024,
      task_memory: 2048,
      desired_count: 3
    },
    
    traffic_routing: {
      routing_policy: "latency",
      health_check_enabled: true,
      cross_region_latency_threshold_ms: 100,
      sticky_sessions: true,
      session_affinity_ttl: 3600
    },
    
    monitoring: {
      enabled: true,
      detailed_metrics: true,
      cross_region_dashboard: true,
      synthetic_monitoring: true,
      distributed_tracing: true,
      anomaly_detection: true
    },
    
    cost_optimization: {
      use_regional_services: true,
      data_transfer_optimization: true,
      intelligent_tiering: true,
      reserved_capacity_planning: true
    },
    
    enable_global_accelerator: true,
    enable_circuit_breaker: true,
    enable_bulkhead_pattern: true,
    enable_chaos_engineering: true,
    
    tags: {
      Environment: "Production",
      Application: "GlobalStore",
      CostCenter: "Engineering"
    }
  })
  
  # Global Traffic Manager
  # Intelligent traffic distribution with multiple routing strategies
  traffic_manager = global_traffic_manager(:global_routing, {
    manager_name: "globalstore-traffic",
    domain_name: "www.globalstore.com",
    certificate_arn: ref(:aws_acm_certificate, :globalstore_cert, :arn),
    
    endpoints: [
      {
        region: "us-east-1",
        endpoint_id: global_app.outputs[:regional_endpoints][0][:endpoint],
        endpoint_type: "ALB",
        weight: 100,
        priority: 100,
        enabled: true,
        client_ip_preservation: true
      },
      {
        region: "eu-west-1",
        endpoint_id: global_app.outputs[:regional_endpoints][1][:endpoint],
        endpoint_type: "ALB",
        weight: 80,
        priority: 90,
        enabled: true
      },
      {
        region: "ap-southeast-1",
        endpoint_id: global_app.outputs[:regional_endpoints][2][:endpoint],
        endpoint_type: "ALB",
        weight: 60,
        priority: 80,
        enabled: true
      }
    ],
    
    default_policy: "latency",
    
    traffic_policies: [
      {
        policy_name: "primary",
        policy_type: "latency",
        health_check_interval: 30,
        health_check_path: "/api/v1/health",
        health_check_protocol: "HTTPS",
        unhealthy_threshold: 3,
        healthy_threshold: 2
      }
    ],
    
    geo_routing: {
      enabled: true,
      location_rules: [
        { location: "NA", endpoint_region: "us-east-1" },
        { location: "EU", endpoint_region: "eu-west-1" },
        { location: "AS", endpoint_region: "ap-southeast-1" },
        { location: "OC", endpoint_region: "ap-southeast-1" }
      ],
      bias_adjustments: {
        "us-east-1": 0,
        "eu-west-1": 25,
        "ap-southeast-1": -25
      }
    },
    
    performance: {
      tcp_optimization: true,
      flow_logs_enabled: true,
      flow_logs_s3_bucket: ref(:aws_s3_bucket, :logs_bucket, :id),
      connection_draining_timeout: 30,
      idle_timeout: 60
    },
    
    advanced_routing: {
      canary_deployment: {
        percentage: 10,
        endpoint: "canary.globalstore.com",
        stable_endpoint: "stable.globalstore.com"
      },
      traffic_dials: {
        "us-east-1": 100,
        "eu-west-1": 75,
        "ap-southeast-1": 50
      }
    },
    
    observability: {
      cloudwatch_enabled: true,
      detailed_metrics: true,
      synthetic_checks: [
        {
          type: "availability",
          schedule: "rate(5 minutes)",
          timeout: 60
        },
        {
          type: "performance",
          schedule: "rate(15 minutes)",
          timeout: 120
        }
      ],
      alerting_enabled: true
    },
    
    security: {
      ddos_protection: true,
      waf_enabled: true,
      blocked_countries: ["XX"],  # Placeholder for sanctioned countries
      rate_limiting: {
        limit: 2000,
        key_type: "IP"
      }
    },
    
    cloudfront: {
      enabled: true,
      price_class: "PriceClass_200",
      origin_shield_enabled: true,
      origin_shield_region: "us-east-1",
      cache_behaviors: [
        {
          path_pattern: "/api/*",
          viewer_protocol_policy: "https-only",
          allowed_methods: ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"],
          default_ttl: 0,
          max_ttl: 0
        },
        {
          path_pattern: "/static/*",
          viewer_protocol_policy: "redirect-to-https",
          default_ttl: 86400,
          max_ttl: 31536000
        }
      ]
    }
  })
  
  # Disaster Recovery Pilot Light
  # Cost-effective DR solution with automated testing
  dr_setup = disaster_recovery_pilot_light(:dr_solution, {
    dr_name: "globalstore-dr",
    dr_description: "Pilot light DR for GlobalStore platform",
    
    primary_region: {
      region: "us-east-1",
      vpc_ref: global_app.resources[:regional]["us-east-1".to_sym][:vpc],
      availability_zones: ["us-east-1a", "us-east-1b", "us-east-1c"],
      critical_resources: [
        {
          type: "database",
          id: global_app.outputs[:database_endpoints][:regional]["us-east-1".to_sym][:cluster_endpoint],
          engine: "aurora-postgresql"
        }
      ],
      backup_schedule: "cron(0 2 * * ? *)"
    },
    
    dr_region: {
      region: "us-west-2",
      vpc_cidr: "10.3.0.0/16",
      availability_zones: ["us-west-2a", "us-west-2b"],
      standby_resources: {
        compute_capacity: "minimal",
        database_capacity: "single-instance"
      }
    },
    
    critical_data: {
      databases: [
        {
          identifier: global_app.outputs[:database_endpoints][:global_cluster],
          engine: "aurora-postgresql",
          engine_version: "14.6"
        }
      ],
      s3_buckets: ["globalstore-assets", "globalstore-backups"],
      backup_retention_days: 7,
      cross_region_backup: true,
      point_in_time_recovery: true
    },
    
    pilot_light: {
      minimal_compute: true,
      database_replicas: true,
      data_sync_interval: 300,
      standby_instance_type: "t3.small",
      auto_scaling_min: 3,
      auto_scaling_max: 30
    },
    
    activation: {
      activation_method: "semi-automated",
      health_check_threshold: 3,
      activation_timeout: 900,
      pre_activation_checks: [
        { name: "ValidatePrimaryDown", type: "health_check" },
        { name: "CheckDataSync", type: "replication_status" },
        { name: "VerifyBackups", type: "backup_validation" }
      ],
      post_activation_validation: [
        { name: "ApplicationHealth", type: "endpoint_check" },
        { name: "DatabaseConnectivity", type: "connection_test" },
        { name: "DataIntegrity", type: "data_validation" }
      ]
    },
    
    testing: {
      test_schedule: "cron(0 10 ? * SUN *)",
      test_scenarios: ["failover", "data_recovery", "partial_activation", "network_partition"],
      automated_testing: true,
      test_notification_enabled: true,
      rollback_after_test: true
    },
    
    monitoring: {
      primary_region_monitoring: true,
      dr_region_monitoring: true,
      replication_lag_threshold_seconds: 300,
      backup_monitoring: true,
      synthetic_monitoring: true,
      dashboard_enabled: true,
      alerting_enabled: true
    },
    
    compliance: {
      rto_hours: 4,
      rpo_hours: 1,
      data_residency_requirements: ["US"],
      encryption_required: true,
      audit_logging: true,
      compliance_standards: ["SOC2", "PCI-DSS"]
    }
  })
  
  # Global Service Mesh
  # Zero-trust microservices communication across regions
  service_mesh = global_service_mesh(:microservices_mesh, {
    mesh_name: "globalstore-mesh",
    mesh_description: "Service mesh for GlobalStore microservices",
    
    services: [
      {
        name: "user-service",
        namespace: "production",
        port: 8080,
        protocol: "HTTP2",
        region: "us-east-1",
        cluster_ref: ref(:aws_ecs_cluster, :us_east_1_cluster),
        health_check_path: "/api/v1/health",
        timeout_seconds: 30,
        retry_attempts: 3,
        weight: 100
      },
      {
        name: "catalog-service",
        namespace: "production",
        port: 8080,
        protocol: "GRPC",
        region: "us-east-1",
        cluster_ref: ref(:aws_ecs_cluster, :us_east_1_cluster),
        health_check_path: "/grpc.health.v1.Health/Check",
        timeout_seconds: 15,
        weight: 100
      },
      {
        name: "order-service",
        namespace: "production",
        port: 8080,
        protocol: "HTTP",
        region: "eu-west-1",
        cluster_ref: ref(:aws_ecs_cluster, :eu_west_1_cluster),
        health_check_path: "/health",
        timeout_seconds: 20,
        weight: 100
      },
      {
        name: "payment-service",
        namespace: "production",
        port: 8443,
        protocol: "HTTP2",
        region: "ap-southeast-1",
        cluster_ref: ref(:aws_ecs_cluster, :ap_southeast_1_cluster),
        health_check_path: "/status",
        timeout_seconds: 25,
        weight: 100
      }
    ],
    
    regions: ["us-east-1", "eu-west-1", "ap-southeast-1"],
    
    virtual_node_config: {
      service_discovery_type: "CLOUD_MAP",
      health_check_interval_millis: 30000,
      health_check_timeout_millis: 5000,
      healthy_threshold: 2,
      unhealthy_threshold: 3,
      backends: ["catalog-service", "order-service", "payment-service"]
    },
    
    traffic_management: {
      load_balancing_algorithm: "LEAST_REQUEST",
      circuit_breaker_enabled: true,
      circuit_breaker_threshold: 5,
      outlier_detection_enabled: true,
      outlier_ejection_duration_seconds: 30,
      max_ejection_percent: 50,
      canary_deployments_enabled: true
    },
    
    cross_region: {
      peering_enabled: true,
      transit_gateway_enabled: true,
      inter_region_tls_enabled: true,
      latency_routing_enabled: true,
      health_based_routing: true
    },
    
    security: {
      mtls_enabled: true,
      tls_mode: "STRICT",
      service_auth_enabled: true,
      rbac_enabled: true,
      encryption_in_transit: true,
      secrets_manager_integration: true
    },
    
    observability: {
      xray_enabled: true,
      cloudwatch_metrics_enabled: true,
      access_logging_enabled: true,
      envoy_stats_enabled: true,
      custom_metrics_enabled: true,
      distributed_tracing_sampling_rate: 0.1,
      log_retention_days: 30
    },
    
    service_discovery: {
      namespace_name: "globalstore.local",
      namespace_description: "GlobalStore service mesh namespace",
      dns_ttl: 60,
      health_check_custom_config_enabled: true,
      routing_policy: "MULTIVALUE",
      cross_region_discovery: true
    },
    
    resilience: {
      retry_policy_enabled: true,
      max_retries: 3,
      retry_timeout_seconds: 5,
      bulkhead_enabled: true,
      max_connections: 100,
      max_pending_requests: 100,
      timeout_enabled: true,
      request_timeout_seconds: 15,
      chaos_testing_enabled: true
    },
    
    gateway: {
      ingress_gateway_enabled: true,
      egress_gateway_enabled: true,
      gateway_port: 443,
      gateway_protocol: "HTTPS",
      custom_domain_enabled: true,
      waf_enabled: true,
      rate_limiting_enabled: true
    },
    
    enable_global_load_balancing: true,
    enable_multi_cluster_routing: true,
    enable_service_migration: true,
    enable_progressive_delivery: true
  })
  
  # Outputs
  output :global_app_domain do
    value global_app.outputs[:domain_name]
    description "Primary application domain"
  end
  
  output :global_accelerator_ips do
    value traffic_manager.outputs[:global_accelerator_ips]
    description "Anycast IP addresses for global access"
  end
  
  output :cloudfront_distribution do
    value traffic_manager.outputs[:cloudfront_domain_name]
    description "CloudFront distribution for static content"
  end
  
  output :dr_readiness_score do
    value dr_setup.outputs[:readiness_score]
    description "Disaster recovery readiness percentage"
  end
  
  output :service_mesh_endpoints do
    value service_mesh.outputs[:services]
    description "Service mesh endpoints"
  end
  
  output :total_monthly_cost do
    value [
      global_app.outputs[:estimated_monthly_cost],
      traffic_manager.outputs[:estimated_monthly_cost],
      dr_setup.outputs[:estimated_monthly_cost],
      service_mesh.outputs[:estimated_monthly_cost]
    ].sum
    description "Total estimated monthly AWS cost"
  end
  
  output :architecture_features do
    value {
      multi_region: global_app.outputs[:regions],
      traffic_routing: traffic_manager.outputs[:routing_strategies],
      dr_capability: {
        rto_hours: dr_setup.outputs[:rto_hours],
        rpo_hours: dr_setup.outputs[:rpo_hours]
      },
      service_mesh: {
        security: service_mesh.outputs[:security_features],
        resilience: service_mesh.outputs[:resilience_features]
      }
    }
    description "Architecture capabilities summary"
  end
end