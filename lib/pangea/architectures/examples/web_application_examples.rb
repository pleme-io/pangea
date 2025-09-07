# frozen_string_literal: true

require 'pangea'

# Web Application Architecture Examples
# Demonstrates various configurations and usage patterns

# Example 1: Basic Web Application
template :basic_web_application do
  include Pangea::Architectures
  
  web_app = web_application_architecture(:basic_app, {
    domain_name: "basic-app.com",
    environment: "production",
    
    # Simple configuration with defaults
    auto_scaling: { min: 2, max: 5, desired: 2 },
    instance_type: "t3.small",
    database_engine: "mysql"
  })
  
  # Template outputs
  output :application_url do
    value web_app.application_url
    description "Primary application URL"
  end
  
  output :estimated_cost do
    value web_app.estimated_monthly_cost
    description "Estimated monthly AWS cost"
  end
end

# Example 2: High-Performance E-commerce Platform
template :ecommerce_platform do
  include Pangea::Architectures
  
  ecommerce = web_application_architecture(:ecommerce, {
    domain_name: "store.example.com",
    environment: "production",
    
    # High-performance compute configuration
    instance_type: "c5.large",
    auto_scaling: { min: 3, max: 20, desired: 5 },
    
    # Optimized database
    database_engine: "aurora-mysql",
    database_instance_class: "db.r5.xlarge",
    database_allocated_storage: 500,
    
    # Performance features
    enable_caching: true,
    enable_cdn: true,
    
    # Security for e-commerce
    security: {
      encryption_at_rest: true,
      encryption_in_transit: true,
      enable_waf: true,
      enable_ddos_protection: true,
      compliance_standards: ["PCI-DSS"]
    },
    
    # Comprehensive monitoring
    monitoring: {
      detailed_monitoring: true,
      enable_logging: true,
      log_retention_days: 90,
      enable_alerting: true,
      enable_tracing: true
    },
    
    # Production backup strategy
    backup: {
      backup_schedule: "daily",
      retention_days: 30,
      cross_region_backup: true,
      point_in_time_recovery: true
    },
    
    tags: {
      Application: "ECommerce",
      CostCenter: "Retail",
      Compliance: "PCI-DSS"
    }
  })
  
  # Extend with additional e-commerce specific components
  ecommerce.extend_with({
    # Search engine for product catalog
    elasticsearch: aws_elasticsearch_domain(:ecommerce_search, {
      domain_name: "ecommerce-search",
      elasticsearch_version: "7.10",
      instance_type: "t3.small.elasticsearch",
      instance_count: 2,
      ebs_options: {
        ebs_enabled: true,
        volume_size: 20
      }
    }),
    
    # SQS for order processing
    order_queue: aws_sqs_queue(:order_processing, {
      name: "ecommerce-orders",
      visibility_timeout_seconds: 300,
      message_retention_seconds: 1209600
    }),
    
    # S3 for product images
    images_bucket: aws_s3_bucket(:product_images, {
      bucket: "ecommerce-product-images-#{SecureRandom.hex(8)}",
      versioning: {
        enabled: true
      },
      server_side_encryption_configuration: {
        rule: {
          apply_server_side_encryption_by_default: {
            sse_algorithm: "AES256"
          }
        }
      }
    })
  })
  
  # Outputs
  output :store_url do
    value ecommerce.application_url
    description "E-commerce store URL"
  end
  
  output :cdn_domain do
    value ecommerce.cdn_domain
    description "CloudFront distribution for static assets"
  end
  
  output :search_endpoint do
    value ecommerce.elasticsearch.domain_endpoint
    description "Elasticsearch domain for product search"
  end
  
  output :total_monthly_cost do
    value ecommerce.estimated_monthly_cost + 45.0  # Additional components cost
    description "Total estimated monthly cost including extensions"
  end
end

# Example 3: Multi-Environment Deployment
template :multi_environment_saas do
  include Pangea::Architectures
  
  environments = [
    {
      name: "development",
      domain: "dev.saas-app.com",
      config: {
        instance_type: "t3.micro",
        auto_scaling: { min: 1, max: 2 },
        database_instance_class: "db.t3.micro",
        enable_caching: false,
        enable_cdn: false
      }
    },
    {
      name: "staging", 
      domain: "staging.saas-app.com",
      config: {
        instance_type: "t3.small",
        auto_scaling: { min: 1, max: 4 },
        database_instance_class: "db.t3.small",
        enable_caching: true,
        enable_cdn: false
      }
    },
    {
      name: "production",
      domain: "saas-app.com", 
      config: {
        instance_type: "t3.medium",
        auto_scaling: { min: 2, max: 15 },
        database_instance_class: "db.r5.large",
        enable_caching: true,
        enable_cdn: true
      }
    }
  ]
  
  environments.each do |env|
    app = web_application_architecture(:"saas_#{env[:name]}", {
      domain_name: env[:domain],
      environment: env[:name],
      
      # Environment-specific configuration
      **env[:config],
      
      # Common configuration
      database_engine: "postgresql",
      security: {
        encryption_at_rest: true,
        encryption_in_transit: true,
        enable_waf: env[:name] == "production",
        enable_ddos_protection: env[:name] == "production"
      },
      
      tags: {
        Application: "SaaSApp",
        Environment: env[:name].capitalize,
        Project: "MultiTenant"
      }
    })
    
    # Environment-specific outputs
    output :"#{env[:name]}_url" do
      value app.application_url
      description "#{env[:name].capitalize} environment URL"
    end
    
    output :"#{env[:name]}_cost" do
      value app.estimated_monthly_cost
      description "#{env[:name].capitalize} estimated monthly cost"
    end
  end
end

# Example 4: Custom Database Override
template :custom_database_web_app do
  include Pangea::Architectures
  
  web_app = web_application_architecture(:custom_db_app, {
    domain_name: "custom-app.com",
    environment: "production",
    database_enabled: true  # Will be overridden
  })
  
  # Override database with Aurora Serverless
  web_app.override(:database) do |arch_ref|
    aws_rds_cluster(:custom_aurora, {
      cluster_identifier: "#{arch_ref.name}-aurora-cluster",
      engine: "aurora-postgresql",
      engine_mode: "serverless",
      master_username: "postgres",
      manage_master_user_password: true,
      
      scaling_configuration: {
        auto_pause: true,
        max_capacity: 16,
        min_capacity: 2,
        seconds_until_auto_pause: 300
      },
      
      backup_retention_period: 7,
      preferred_backup_window: "07:00-09:00",
      preferred_maintenance_window: "sun:05:00-sun:06:00",
      
      storage_encrypted: true,
      
      db_subnet_group_name: aws_db_subnet_group(:aurora_subnet_group, {
        name: "#{arch_ref.name}-aurora-subnet-group",
        subnet_ids: arch_ref.network.private_subnets.map(&:id),
        description: "Aurora subnet group for #{arch_ref.name}"
      }).name,
      
      vpc_security_group_ids: [
        aws_security_group(:aurora_sg, {
          name: "#{arch_ref.name}-aurora-sg",
          description: "Aurora PostgreSQL security group",
          vpc_id: arch_ref.network.vpc.id,
          
          ingress: [{
            from_port: 5432,
            to_port: 5432,
            protocol: "tcp",
            security_groups: [arch_ref.security_groups.web_sg.id]
          }],
          
          egress: [{
            from_port: 0,
            to_port: 0,
            protocol: "-1",
            cidr_blocks: ["0.0.0.0/0"]
          }]
        }).id
      ],
      
      tags: {
        Name: "#{arch_ref.name}-aurora-cluster",
        Environment: "production",
        Engine: "Aurora PostgreSQL Serverless"
      }
    })
  end
  
  output :application_url do
    value web_app.application_url
  end
  
  output :aurora_endpoint do
    value web_app.database.endpoint
    description "Aurora Serverless cluster endpoint"
  end
end

# Example 5: Microservices Backend Architecture
template :microservices_web_backend do
  include Pangea::Architectures
  
  # Main web application frontend
  frontend = web_application_architecture(:frontend, {
    domain_name: "app.microservices.com",
    environment: "production",
    
    # Frontend-optimized configuration
    instance_type: "t3.medium", 
    auto_scaling: { min: 2, max: 8 },
    database_enabled: false,  # No database for frontend
    enable_cdn: true,  # Serve static assets via CDN
    
    tags: {
      Service: "Frontend",
      Architecture: "Microservices"
    }
  })
  
  # Individual microservices
  services = [
    {
      name: "user-service",
      subdomain: "users.api.microservices.com",
      database: "postgresql"
    },
    {
      name: "order-service", 
      subdomain: "orders.api.microservices.com",
      database: "mysql"
    },
    {
      name: "notification-service",
      subdomain: "notifications.api.microservices.com", 
      database: false
    }
  ]
  
  services.each do |service|
    service_app = web_application_architecture(service[:name].tr('-', '_').to_sym, {
      domain_name: service[:subdomain],
      environment: "production",
      
      # Microservice configuration
      instance_type: "t3.small",
      auto_scaling: { min: 2, max: 6 },
      
      # Database configuration
      database_enabled: !!service[:database],
      database_engine: service[:database] || "mysql",
      database_instance_class: "db.t3.small",
      
      # API-focused configuration
      enable_caching: true,
      enable_cdn: false,  # APIs don't need CDN
      
      # Share network with frontend
      vpc_cidr: "10.0.0.0/16",  # Same as frontend
      
      tags: {
        Service: service[:name],
        Architecture: "Microservices",
        Type: "Backend"
      }
    })
    
    # Service-specific outputs
    output :"#{service[:name].tr('-', '_')}_url" do
      value service_app.application_url
      description "#{service[:name]} API endpoint"
    end
  end
  
  # API Gateway for microservices routing
  api_gateway = aws_api_gateway_rest_api(:microservices_gateway, {
    name: "microservices-gateway",
    description: "API Gateway for microservices",
    endpoint_configuration: {
      types: ["REGIONAL"]
    }
  })
  
  # Shared resources
  shared_cache = aws_elasticache_replication_group(:shared_cache, {
    description: "Shared Redis cache for microservices",
    replication_group_id: "microservices-cache",
    port: 6379,
    parameter_group_name: "default.redis7",
    node_type: "cache.t3.micro",
    num_cache_clusters: 2,
    automatic_failover_enabled: true,
    multi_az_enabled: true,
    
    subnet_group_name: aws_elasticache_subnet_group(:cache_subnet_group, {
      name: "microservices-cache-subnet-group",
      subnet_ids: frontend.network.private_subnets.map(&:id)
    }).name,
    
    security_group_ids: [
      aws_security_group(:cache_sg, {
        name: "microservices-cache-sg",
        description: "Redis cache security group",
        vpc_id: frontend.network.vpc.id,
        
        ingress: [{
          from_port: 6379,
          to_port: 6379,
          protocol: "tcp",
          security_groups: services.map { |s| "#{s[:name].tr('-', '_')}_sg_id" }
        }]
      }).id
    ]
  })
  
  # Main outputs
  output :frontend_url do
    value frontend.application_url
    description "Frontend application URL"
  end
  
  output :api_gateway_url do
    value "https://#{api_gateway.id}.execute-api.us-east-1.amazonaws.com/prod"
    description "API Gateway endpoint for microservices"
  end
  
  output :shared_cache_endpoint do
    value shared_cache.primary_endpoint_address
    description "Shared Redis cache endpoint"
  end
  
  output :total_architecture_cost do
    service_costs = services.sum { |service| 
      # Estimated cost per microservice
      case service[:database]
      when "postgresql", "mysql" 
        85.0  # Instance + database
      when false
        50.0  # Instance only
      end
    }
    
    total_cost = frontend.estimated_monthly_cost + service_costs + 25.0  # API Gateway + Cache
    
    value total_cost
    description "Total estimated monthly cost for microservices architecture"
  end
end

# Example 6: Architecture Composition with Data Pipeline
template :web_app_with_analytics do
  include Pangea::Architectures
  
  # Main web application
  web_app = web_application_architecture(:analytics_app, {
    domain_name: "analytics-app.com", 
    environment: "production",
    
    instance_type: "t3.medium",
    auto_scaling: { min: 2, max: 8 },
    database_engine: "postgresql",
    enable_caching: true
  })
  
  # Compose with data analytics pipeline
  web_app.compose_with do |arch_ref|
    # Add data lake for analytics
    if defined?(Pangea::Architectures) && respond_to?(:data_lake_architecture)
      arch_ref.analytics = data_lake_architecture(:"#{arch_ref.name}_analytics", {
        vpc_ref: arch_ref.network.vpc,
        source_database_ref: arch_ref.database,
        processing_schedule: "daily",
        retention_days: 365,
        
        data_sources: [
          {
            name: "application_logs",
            type: "cloudwatch_logs",
            log_group: "/aws/elasticbeanstalk/#{arch_ref.name}/var/log/eb-engine.log"
          },
          {
            name: "database_exports", 
            type: "rds_snapshot",
            database_ref: arch_ref.database
          }
        ],
        
        analytics_tools: [
          "athena",
          "quicksight",
          "redshift_serverless"
        ]
      })
    end
    
    # Add real-time streaming for user behavior
    arch_ref.streaming = {
      kinesis_stream: aws_kinesis_stream(:user_events, {
        name: "#{arch_ref.name}-user-events",
        shard_count: 2,
        retention_period: 24,
        
        shard_level_metrics: [
          "IncomingRecords",
          "OutgoingRecords"
        ]
      }),
      
      kinesis_analytics: aws_kinesis_analytics_application(:behavior_analytics, {
        name: "#{arch_ref.name}-behavior-analytics",
        
        inputs: [{
          name_prefix: "user_behavior_stream",
          kinesis_stream: {
            resource_arn: aws_kinesis_stream(:user_events).arn,
            role_arn: aws_iam_role(:kinesis_analytics_role).arn
          },
          
          schema: {
            record_columns: [
              {
                name: "user_id",
                sql_type: "VARCHAR(32)",
                mapping: "$.user_id"
              },
              {
                name: "event_type",
                sql_type: "VARCHAR(64)",
                mapping: "$.event_type"  
              },
              {
                name: "timestamp",
                sql_type: "TIMESTAMP",
                mapping: "$.timestamp"
              }
            ],
            record_format: {
              record_format_type: "JSON",
              mapping_parameters: {
                json_mapping_parameters: {
                  record_row_path: "$"
                }
              }
            }
          }
        }]
      })
    }
  end
  
  # Outputs
  output :web_application_url do
    value web_app.application_url
  end
  
  output :analytics_dashboard_url do
    value web_app.analytics&.dashboard_url
    description "Data analytics dashboard" 
  end
  
  output :streaming_analytics_endpoint do
    value web_app.streaming[:kinesis_analytics].name
    description "Real-time analytics application"
  end
  
  output :comprehensive_monthly_cost do
    base_cost = web_app.estimated_monthly_cost
    analytics_cost = 150.0  # Estimated data lake + streaming costs
    
    value base_cost + analytics_cost
    description "Total cost including web app and analytics pipeline"
  end
end