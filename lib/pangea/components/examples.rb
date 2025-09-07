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


require 'pangea/components'

module Pangea
  module Components
    # Example templates showing component composition and usage patterns
    module Examples
      # Example 1: Simple 3-tier web application
      def three_tier_web_application_example
        template :web_application do
          include Pangea::Resources::AWS
          include Pangea::Components
          
          # Network layer
          vpc = aws_vpc(:main, {
            cidr_block: "10.0.0.0/16",
            enable_dns_hostnames: true,
            enable_dns_support: true,
            tags: { Name: "main-vpc", Environment: "production" }
          })
          
          # Public subnets for load balancer
          public_subnet_1 = aws_subnet(:public_1, {
            vpc_id: vpc.id,
            cidr_block: "10.0.1.0/24",
            availability_zone: "us-east-1a",
            map_public_ip_on_launch: true,
            tags: { Name: "public-subnet-1", Type: "public" }
          })
          
          public_subnet_2 = aws_subnet(:public_2, {
            vpc_id: vpc.id,
            cidr_block: "10.0.2.0/24",
            availability_zone: "us-east-1b",
            map_public_ip_on_launch: true,
            tags: { Name: "public-subnet-2", Type: "public" }
          })
          
          # Private subnets for application servers
          private_subnet_1 = aws_subnet(:private_1, {
            vpc_id: vpc.id,
            cidr_block: "10.0.10.0/24",
            availability_zone: "us-east-1a",
            tags: { Name: "private-subnet-1", Type: "private" }
          })
          
          private_subnet_2 = aws_subnet(:private_2, {
            vpc_id: vpc.id,
            cidr_block: "10.0.11.0/24",
            availability_zone: "us-east-1b",
            tags: { Name: "private-subnet-2", Type: "private" }
          })
          
          # Database subnets
          db_subnet_1 = aws_subnet(:db_1, {
            vpc_id: vpc.id,
            cidr_block: "10.0.20.0/24",
            availability_zone: "us-east-1a",
            tags: { Name: "db-subnet-1", Type: "database" }
          })
          
          db_subnet_2 = aws_subnet(:db_2, {
            vpc_id: vpc.id,
            cidr_block: "10.0.21.0/24",
            availability_zone: "us-east-1b",
            tags: { Name: "db-subnet-2", Type: "database" }
          })
          
          # Security groups
          alb_sg = aws_security_group(:alb, {
            name: "alb-sg",
            description: "Security group for Application Load Balancer",
            vpc_id: vpc.id,
            ingress: [
              { from_port: 80, to_port: 80, protocol: "tcp", cidr_blocks: ["0.0.0.0/0"] },
              { from_port: 443, to_port: 443, protocol: "tcp", cidr_blocks: ["0.0.0.0/0"] }
            ],
            egress: [
              { from_port: 0, to_port: 65535, protocol: "tcp", cidr_blocks: ["10.0.0.0/16"] }
            ],
            tags: { Name: "alb-security-group" }
          })
          
          web_sg = aws_security_group(:web, {
            name: "web-servers-sg",
            description: "Security group for web servers",
            vpc_id: vpc.id,
            ingress: [
              { from_port: 80, to_port: 80, protocol: "tcp", security_groups: [alb_sg.id] },
              { from_port: 443, to_port: 443, protocol: "tcp", security_groups: [alb_sg.id] },
              { from_port: 22, to_port: 22, protocol: "tcp", cidr_blocks: ["10.0.0.0/16"] }
            ],
            tags: { Name: "web-servers-security-group" }
          })
          
          db_sg = aws_security_group(:database, {
            name: "database-sg",
            description: "Security group for database",
            vpc_id: vpc.id,
            ingress: [
              { from_port: 3306, to_port: 3306, protocol: "tcp", security_groups: [web_sg.id] }
            ],
            tags: { Name: "database-security-group" }
          })
          
          # Component 1: Application Load Balancer
          load_balancer = application_load_balancer(:web_alb, {
            vpc_ref: vpc,
            subnet_refs: [public_subnet_1, public_subnet_2],
            security_group_refs: [alb_sg],
            scheme: "internet-facing",
            enable_https: true,
            certificate_arn: "arn:aws:acm:us-east-1:123456789012:certificate/example",
            ssl_redirect: true,
            create_default_target_group: true,
            default_target_group_port: 80,
            enable_access_logs: true,
            tags: { Environment: "production", Component: "load-balancer" }
          })
          
          # Component 2: Auto Scaling Web Servers  
          web_servers = auto_scaling_web_servers(:web_servers, {
            vpc_ref: vpc,
            subnet_refs: [private_subnet_1, private_subnet_2],
            security_group_refs: [web_sg],
            ami_id: "ami-0abcdef1234567890",
            instance_type: "t3.small",
            key_name: "production-key",
            min_size: 2,
            max_size: 10,
            desired_capacity: 3,
            health_check_type: "ELB",
            target_group_refs: [load_balancer.resources[:target_groups][:default]],
            enable_cpu_scaling: true,
            cpu_target_value: 70.0,
            tags: { Environment: "production", Component: "web-servers" }
          })
          
          # Component 3: MySQL Database
          database = mysql_database(:app_database, {
            vpc_ref: vpc,
            subnet_refs: [db_subnet_1, db_subnet_2],
            security_group_refs: [db_sg],
            engine_version: "8.0.35",
            db_instance_class: "db.t3.small",
            allocated_storage: 100,
            max_allocated_storage: 500,
            storage_type: "gp3",
            db_name: "webapp",
            username: "admin",
            manage_master_user_password: true,
            storage_encrypted: true,
            multi_az: false,  # Single AZ for cost savings
            backup: {
              backup_retention_period: 7,
              backup_window: "03:00-04:00"
            },
            tags: { Environment: "production", Component: "database" }
          })
          
          # Component 4: Secure S3 Bucket for assets
          asset_bucket = secure_s3_bucket(:app_assets, {
            bucket_name: "webapp-assets-#{SecureRandom.hex(4)}",
            encryption: {
              sse_algorithm: "AES256",
              enforce_ssl: true
            },
            versioning: { status: "Enabled" },
            lifecycle_rules: [{
              id: "optimize-costs",
              status: "Enabled",
              transitions: [{
                days: 30,
                storage_class: "STANDARD_IA"
              }, {
                days: 90,
                storage_class: "GLACIER"
              }]
            }],
            tags: { Environment: "production", Component: "storage" }
          })
          
          # Template outputs
          output :load_balancer_dns do
            value load_balancer.outputs[:alb_dns_name]
            description "DNS name of the Application Load Balancer"
          end
          
          output :database_endpoint do
            value database.outputs[:db_instance_endpoint]
            description "RDS MySQL database endpoint"
          end
          
          output :asset_bucket_name do
            value asset_bucket.outputs[:bucket_name]
            description "S3 bucket name for application assets"
          end
          
          output :estimated_monthly_cost do
            total_cost = load_balancer.outputs[:estimated_monthly_cost] +
                        web_servers.outputs[:estimated_monthly_cost] +
                        database.outputs[:estimated_monthly_cost] +
                        asset_bucket.outputs[:estimated_monthly_cost]
            value total_cost
            description "Total estimated monthly cost for all components"
          end
        end
      end
      
      # Example 2: High-availability enterprise application
      def enterprise_application_example
        template :enterprise_app do
          include Pangea::Resources::AWS
          include Pangea::Components
          
          # Multi-AZ VPC setup (simplified)
          vpc = aws_vpc(:enterprise, { 
            cidr_block: "10.0.0.0/16",
            tags: { Environment: "production", Tier: "enterprise" }
          })
          
          # Create subnets across 3 AZs (simplified for example)
          public_subnets = ["a", "b", "c"].map.with_index do |az, i|
            aws_subnet("public_#{az}".to_sym, {
              vpc_id: vpc.id,
              cidr_block: "10.0.#{i+1}.0/24",
              availability_zone: "us-east-1#{az}",
              map_public_ip_on_launch: true,
              tags: { Name: "public-subnet-#{az}", Type: "public" }
            })
          end
          
          private_subnets = ["a", "b", "c"].map.with_index do |az, i|
            aws_subnet("private_#{az}".to_sym, {
              vpc_id: vpc.id,
              cidr_block: "10.0.#{i+10}.0/24",
              availability_zone: "us-east-1#{az}",
              tags: { Name: "private-subnet-#{az}", Type: "private" }
            })
          end
          
          db_subnets = ["a", "b", "c"].map.with_index do |az, i|
            aws_subnet("db_#{az}".to_sym, {
              vpc_id: vpc.id,
              cidr_block: "10.0.#{i+20}.0/24",
              availability_zone: "us-east-1#{az}",
              tags: { Name: "db-subnet-#{az}", Type: "database" }
            })
          end
          
          # Security groups (simplified)
          alb_sg = aws_security_group(:alb, {
            name: "enterprise-alb-sg",
            vpc_id: vpc.id,
            ingress: [
              { from_port: 443, to_port: 443, protocol: "tcp", cidr_blocks: ["0.0.0.0/0"] }
            ]
          })
          
          web_sg = aws_security_group(:web, {
            name: "enterprise-web-sg", 
            vpc_id: vpc.id,
            ingress: [
              { from_port: 80, to_port: 80, protocol: "tcp", security_groups: [alb_sg.id] }
            ]
          })
          
          db_sg = aws_security_group(:db, {
            name: "enterprise-db-sg",
            vpc_id: vpc.id,
            ingress: [
              { from_port: 3306, to_port: 3306, protocol: "tcp", security_groups: [web_sg.id] }
            ]
          })
          
          # Enterprise-grade Application Load Balancer
          enterprise_alb = application_load_balancer(:enterprise_alb, {
            vpc_ref: vpc,
            subnet_refs: public_subnets,
            security_group_refs: [alb_sg],
            scheme: "internet-facing",
            enable_deletion_protection: true,
            enable_cross_zone_load_balancing: true,
            enable_https: true,
            certificate_arn: "arn:aws:acm:us-east-1:123456789012:certificate/enterprise",
            ssl_redirect: true,
            idle_timeout: 300,
            target_groups: [{
              name: "api",
              port: 8080,
              protocol: "HTTP",
              health_check: {
                path: "/health",
                healthy_threshold: 2,
                unhealthy_threshold: 3,
                interval: 15
              }
            }, {
              name: "admin",
              port: 9000,
              protocol: "HTTP",
              stickiness_enabled: true,
              health_check: {
                path: "/admin/health",
                matcher: "200,202"
              }
            }],
            enable_access_logs: true,
            access_logs_bucket: "enterprise-alb-logs",
            tags: { Environment: "production", Criticality: "high" }
          })
          
          # High-performance Auto Scaling Group
          enterprise_asg = auto_scaling_web_servers(:enterprise_web, {
            vpc_ref: vpc,
            subnet_refs: private_subnets,
            security_group_refs: [web_sg],
            ami_id: "ami-0abcdef1234567890",
            instance_type: "c5.large",
            key_name: "enterprise-key",
            min_size: 3,
            max_size: 20,
            desired_capacity: 6,
            health_check_type: "ELB",
            health_check_grace_period: 600,
            target_group_refs: enterprise_alb.resources[:target_groups].values,
            
            # Multiple scaling policies
            enable_cpu_scaling: false,
            scaling_policies: [{
              policy_type: "TargetTrackingScaling",
              target_value: 60.0,
              metric_type: "ASGAverageCPUUtilization"
            }, {
              policy_type: "TargetTrackingScaling",
              target_value: 1000.0,
              metric_type: "ALBRequestCountPerTarget",
              target_group_arn: enterprise_alb.resources[:target_groups][:api].arn
            }],
            
            # Enhanced storage
            block_device_mappings: [{
              device_name: "/dev/xvda",
              volume_type: "gp3",
              volume_size: 50,
              iops: 3000,
              throughput: 250,
              encrypted: true
            }],
            
            # Enhanced monitoring
            monitoring: {
              enabled: true,
              granularity: "1Minute"
            },
            
            tags: { Environment: "production", Criticality: "high" }
          })
          
          # High-availability MySQL Database
          enterprise_db = mysql_database(:enterprise_db, {
            vpc_ref: vpc,
            subnet_refs: db_subnets,
            security_group_refs: [db_sg],
            engine_version: "8.0.35",
            db_instance_class: "db.r5.xlarge",
            allocated_storage: 500,
            max_allocated_storage: 2000,
            storage_type: "gp3",
            iops: 3000,
            
            # High availability
            multi_az: true,
            
            # Security
            storage_encrypted: true,
            kms_key_id: "alias/rds-enterprise-key",
            deletion_protection: true,
            
            # Database configuration
            db_name: "enterprise",
            username: "admin",
            manage_master_user_password: true,
            
            # Enterprise backup strategy
            backup: {
              backup_retention_period: 30,
              backup_window: "02:00-03:00",
              copy_tags_to_snapshot: true,
              skip_final_snapshot: false
            },
            
            # Performance monitoring
            monitoring: {
              monitoring_interval: 60,
              performance_insights_enabled: true,
              performance_insights_retention_period: 731
            },
            
            # Read replicas for scaling
            create_read_replica: true,
            read_replica_count: 2,
            read_replica_instance_class: "db.r5.large",
            
            tags: { Environment: "production", Criticality: "high" }
          })
          
          # Enterprise data storage buckets
          primary_data = secure_s3_bucket(:primary_data, {
            encryption: {
              sse_algorithm: "aws:kms",
              kms_key_id: "alias/s3-enterprise-key",
              enforce_ssl: true
            },
            versioning: { status: "Enabled" },
            object_lock_enabled: true,
            
            # Cross-region replication
            replication: {
              enabled: true,
              role_arn: "arn:aws:iam::123456789012:role/S3ReplicationRole",
              rules: [{
                id: "disaster-recovery",
                status: "Enabled",
                destination: {
                  bucket: "arn:aws:s3:::enterprise-data-dr",
                  storage_class: "STANDARD_IA"
                }
              }]
            },
            
            # Comprehensive lifecycle
            lifecycle_rules: [{
              id: "enterprise-lifecycle",
              status: "Enabled",
              transitions: [{
                days: 30,
                storage_class: "STANDARD_IA"
              }, {
                days: 90,
                storage_class: "GLACIER_IR"
              }, {
                days: 365,
                storage_class: "DEEP_ARCHIVE"
              }]
            }],
            
            # Compliance logging
            logging: {
              enabled: true,
              target_bucket: "enterprise-access-logs",
              target_prefix: "data-access/"
            },
            
            tags: { Environment: "production", Compliance: "SOX-HIPAA" }
          })
          
          # Template outputs showing component integration
          output :application_url do
            value "https://#{enterprise_alb.outputs[:alb_dns_name]}"
            description "Enterprise application HTTPS URL"
          end
          
          output :database_connection do
            value enterprise_db.outputs[:db_instance_endpoint]
            description "Primary database connection endpoint"
          end
          
          output :read_replicas do
            value enterprise_db.outputs[:read_replica_identifiers]
            description "Read replica database endpoints"
          end
          
          output :data_bucket do
            value primary_data.outputs[:bucket_name]
            description "Primary data storage bucket"
          end
          
          output :security_score do
            combined_features = enterprise_alb.outputs[:security_features] +
                              enterprise_asg.outputs[:security_features] +
                              enterprise_db.outputs[:security_features] +
                              primary_data.outputs[:security_features]
            value combined_features.uniq.count
            description "Total number of security features enabled"
          end
          
          output :estimated_monthly_cost do
            total = enterprise_alb.outputs[:estimated_monthly_cost] +
                   enterprise_asg.outputs[:estimated_monthly_cost] +
                   enterprise_db.outputs[:estimated_monthly_cost] +
                   primary_data.outputs[:estimated_monthly_cost]
            value total.round(2)
            description "Total estimated monthly cost (USD)"
          end
        end
      end
    end
  end
end