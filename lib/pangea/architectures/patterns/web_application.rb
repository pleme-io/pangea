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


require 'dry-struct'
require 'pangea/resources/types'
require 'pangea/architectures/base'

module Pangea
  module Architectures
    module Patterns
      # Web Application Architecture - Complete 3-tier web application
      module WebApplication
        include Base
        
        # Web application architecture attributes with validation
        class WebApplicationAttributes < Dry::Struct
          transform_keys(&:to_sym)
          
          # Core configuration
          attribute :domain, Types::String
          attribute :environment, Types::String.default('development').enum('development', 'staging', 'production')
          attribute :vpc_cidr, Types::String.default('10.0.0.0/16')
          attribute :availability_zones, Types::Array.of(Types::String).default(['us-east-1a', 'us-east-1b'].freeze)
          
          # Scaling and availability
          attribute :high_availability, Types::Bool.default(false)
          attribute :auto_scaling, Types::Hash.schema(
            min?: Types::Integer.default(1),
            max?: Types::Integer.default(5),
            desired?: Types::Integer.default(2)
          ).default({}.freeze)
          
          # Instance configuration
          attribute :instance_type, Types::String.default('t3.micro')
          attribute :ami_id, Types::String.default('ami-0c55b159cbfafe1f0')
          attribute? :key_pair, Types::String
          
          # Database configuration
          attribute :database_enabled, Types::Bool.default(true)
          attribute :database_engine, Types::String.default('postgres').enum('mysql', 'postgres')
          attribute :database_instance_class, Types::String.default('db.t3.micro')
          attribute :database_allocated_storage, Types::Integer.default(20)
          attribute :database_backup_retention, Types::Integer.default(7)
          
          # Storage configuration
          attribute :s3_bucket_enabled, Types::Bool.default(true)
          attribute :cloudfront_enabled, Types::Bool.default(false)
          
          # Security configuration
          attribute :waf_enabled, Types::Bool.default(false)
          attribute? :ssl_certificate_arn, Types::String
          
          # Monitoring configuration
          attribute :monitoring_enabled, Types::Bool.default(true)
          attribute :log_retention_days, Types::Integer.default(30)
          
          # Additional tags
          attribute :tags, Types::Hash.default({}.freeze)
          
          # Validate configuration compatibility
          def self.new(attributes)
            attrs = super
            
            # High availability requires multiple AZs
            if attrs.high_availability && attrs.availability_zones.count < 2
              raise Dry::Struct::Error, "High availability requires at least 2 availability zones"
            end
            
            # Auto scaling requires high availability in production
            if attrs.environment == 'production' && attrs.auto_scaling[:max] > 1 && !attrs.high_availability
              raise Dry::Struct::Error, "Auto scaling in production requires high_availability: true"
            end
            
            attrs
          end
          
          # Computed properties
          def is_production?
            environment == 'production'
          end
          
          def requires_https?
            is_production? || ssl_certificate_arn
          end
          
          def subnet_count
            availability_zones.count * 2  # Public + private per AZ
          end
        end
        
        # Create a complete web application architecture
        #
        # @param name [Symbol] Architecture name
        # @param attributes [Hash] Architecture configuration
        # @return [ArchitectureReference] Complete architecture reference
        def web_application_architecture(name, attributes = {})
          # Validate and set defaults
          arch_attrs = WebApplicationAttributes.new(attributes)
          arch_ref = create_architecture_reference('web_application', name, architecture_attributes: arch_attrs.to_h)
          
          # Generate base tags for all resources
          base_tags = architecture_tags(arch_ref, {
            Domain: arch_attrs.domain,
            Environment: arch_attrs.environment
          }.merge(arch_attrs.tags))
          
          # 1. Create network tier
          arch_ref.network = vpc_with_subnets(
            architecture_resource_name(name, :network),
            vpc_cidr: arch_attrs.vpc_cidr,
            availability_zones: arch_attrs.availability_zones,
            attributes: {
              vpc_tags: base_tags.merge(Tier: 'network'),
              public_subnet_tags: base_tags.merge(Tier: 'public'),
              private_subnet_tags: base_tags.merge(Tier: 'private')
            }
          )
          
          # 2. Create security tier
          security_resources = create_security_tier(name, arch_ref, arch_attrs, base_tags)
          arch_ref.security = security_resources
          
          # 3. Create storage tier (if enabled)
          if arch_attrs.s3_bucket_enabled
            storage_resources = create_storage_tier(name, arch_ref, arch_attrs, base_tags)
            arch_ref.storage = storage_resources
          end
          
          # 4. Create database tier (if enabled)
          if arch_attrs.database_enabled
            database_resources = create_database_tier(name, arch_ref, arch_attrs, base_tags)
            arch_ref.database = database_resources
          end
          
          # 5. Create compute tier
          compute_resources = create_compute_tier(name, arch_ref, arch_attrs, base_tags)
          arch_ref.compute = compute_resources
          
          # 6. Create load balancer tier
          load_balancer = create_load_balancer_tier(name, arch_ref, arch_attrs, base_tags)
          arch_ref.compute[:load_balancer] = load_balancer
          
          # 7. Create monitoring tier (if enabled)
          if arch_attrs.monitoring_enabled
            monitoring_resources = create_monitoring_tier(name, arch_ref, arch_attrs, base_tags)
            arch_ref.monitoring = monitoring_resources
          end
          
          arch_ref
        end
        
        private
        
        # Create security group and WAF resources
        def create_security_tier(name, arch_ref, arch_attrs, base_tags)
          security_resources = {}
          
          # Web security group
          security_resources[:web_sg] = aws_security_group(
            architecture_resource_name(name, :web_sg),
            name_prefix: "#{name}-web-sg",
            vpc_id: arch_ref.network.vpc.id,
            ingress_rules: [
              {
                from_port: 80,
                to_port: 80,
                protocol: 'tcp',
                cidr_blocks: ['0.0.0.0/0'],
                description: 'HTTP'
              },
              {
                from_port: 443,
                to_port: 443,
                protocol: 'tcp',
                cidr_blocks: ['0.0.0.0/0'],
                description: 'HTTPS'
              }
            ],
            egress_rules: [
              {
                from_port: 0,
                to_port: 0,
                protocol: '-1',
                cidr_blocks: ['0.0.0.0/0'],
                description: 'All outbound'
              }
            ],
            tags: base_tags.merge(Tier: 'security', Component: 'web-sg')
          )
          
          # Database security group (if database enabled)
          if arch_attrs.database_enabled
            security_resources[:db_sg] = aws_security_group(
              architecture_resource_name(name, :db_sg),
              name_prefix: "#{name}-db-sg",
              vpc_id: arch_ref.network.vpc.id,
              ingress_rules: [
                {
                  from_port: arch_attrs.database_engine == 'postgres' ? 5432 : 3306,
                  to_port: arch_attrs.database_engine == 'postgres' ? 5432 : 3306,
                  protocol: 'tcp',
                  security_groups: [security_resources[:web_sg].id],
                  description: "#{arch_attrs.database_engine.upcase} from web tier"
                }
              ],
              tags: base_tags.merge(Tier: 'security', Component: 'db-sg')
            )
          end
          
          security_resources
        end
        
        # Create S3 buckets and CloudFront distribution
        def create_storage_tier(name, arch_ref, arch_attrs, base_tags)
          storage_resources = {}
          
          # Application assets bucket
          storage_resources[:assets_bucket] = aws_s3_bucket(
            architecture_resource_name(name, :assets),
            bucket_name: "#{name.to_s.gsub('_', '-')}-#{arch_attrs.environment}-assets-#{Time.now.to_i}",
            versioning: arch_attrs.environment == 'production' ? 'Enabled' : 'Disabled',
            tags: base_tags.merge(Tier: 'storage', Component: 'assets')
          )
          
          # Application logs bucket
          storage_resources[:logs_bucket] = aws_s3_bucket(
            architecture_resource_name(name, :logs),
            bucket_name: "#{name.to_s.gsub('_', '-')}-#{arch_attrs.environment}-logs-#{Time.now.to_i}",
            lifecycle_rules: [
              {
                id: 'delete_old_logs',
                status: 'Enabled',
                expiration: { days: arch_attrs.log_retention_days }
              }
            ],
            tags: base_tags.merge(Tier: 'storage', Component: 'logs')
          )
          
          storage_resources
        end
        
        # Create RDS database instance or cluster
        def create_database_tier(name, arch_ref, arch_attrs, base_tags)
          database_resources = {}
          
          # Database subnet group
          database_resources[:subnet_group] = aws_db_subnet_group(
            architecture_resource_name(name, :db_subnet_group),
            name: "#{name}-db-subnet-group",
            subnet_ids: arch_ref.network.private_subnet_ids,
            tags: base_tags.merge(Tier: 'database', Component: 'subnet-group')
          )
          
          # Database instance
          database_resources[:instance] = aws_db_instance(
            architecture_resource_name(name, :database),
            identifier: "#{name}-#{arch_attrs.environment}-db",
            engine: arch_attrs.database_engine,
            engine_version: arch_attrs.database_engine == 'postgres' ? '14.9' : '8.0.35',
            instance_class: arch_attrs.database_instance_class,
            allocated_storage: arch_attrs.database_allocated_storage,
            storage_type: 'gp2',
            storage_encrypted: arch_attrs.environment == 'production',
            
            db_name: name.to_s.gsub(/[^a-zA-Z0-9]/, ''),
            username: 'admin',
            manage_master_user_password: true,
            
            vpc_security_group_ids: [arch_ref.security[:db_sg].id],
            db_subnet_group_name: database_resources[:subnet_group].id,
            
            backup_retention_period: arch_attrs.database_backup_retention,
            backup_window: '03:00-04:00',
            maintenance_window: 'sun:04:00-sun:05:00',
            
            deletion_protection: arch_attrs.environment == 'production',
            skip_final_snapshot: arch_attrs.environment != 'production',
            
            tags: base_tags.merge(Tier: 'database', Component: 'primary')
          )
          
          database_resources
        end
        
        # Create launch template and auto scaling group
        def create_compute_tier(name, arch_ref, arch_attrs, base_tags)
          compute_resources = {}
          
          # User data script
          require 'base64'
          user_data = Base64.encode64(generate_user_data(name, arch_ref, arch_attrs))
          
          # Launch template
          compute_resources[:launch_template] = aws_launch_template(
            architecture_resource_name(name, :launch_template),
            name_prefix: "#{name}-web-",
            image_id: arch_attrs.ami_id,
            instance_type: arch_attrs.instance_type,
            vpc_security_group_ids: [arch_ref.security[:web_sg].id],
            key_name: arch_attrs.key_pair,
            user_data: user_data,
            
            tag_specifications: [
              {
                resource_type: 'instance',
                tags: base_tags.merge(Tier: 'compute', Component: 'web-server')
              }
            ],
            
            tags: base_tags.merge(Tier: 'compute', Component: 'launch-template')
          )
          
          # Auto scaling group
          scaling_config = arch_attrs.auto_scaling.empty? ? 
            { min: 1, max: 1, desired: 1 } : 
            arch_attrs.auto_scaling.merge(desired: arch_attrs.auto_scaling[:desired] || arch_attrs.auto_scaling[:min])
          
          compute_resources[:auto_scaling_group] = aws_autoscaling_group(
            architecture_resource_name(name, :asg),
            name: "#{name}-web-asg",
            vpc_zone_identifier: arch_ref.network.private_subnet_ids,
            health_check_type: 'ELB',
            health_check_grace_period: 300,
            
            min_size: scaling_config[:min],
            max_size: scaling_config[:max],
            desired_capacity: scaling_config[:desired],
            
            launch_template: {
              id: compute_resources[:launch_template].id,
              version: '$Latest'
            },
            
            tags: [
              {
                key: 'Name',
                value: "#{name}-web-asg",
                propagate_at_launch: true
              }
            ] + base_tags.map do |key, value|
              {
                key: key.to_s,
                value: value.to_s,
                propagate_at_launch: true
              }
            end
          )
          
          compute_resources
        end
        
        # Create application load balancer
        def create_load_balancer_tier(name, arch_ref, arch_attrs, base_tags)
          # Application Load Balancer
          alb = aws_lb(
            architecture_resource_name(name, :alb),
            name: "#{name}-alb",
            load_balancer_type: 'application',
            subnets: arch_ref.network.public_subnet_ids,
            security_groups: [arch_ref.security[:web_sg].id],
            
            tags: base_tags.merge(Tier: 'load-balancer', Component: 'alb')
          )
          
          # Target group
          target_group = aws_lb_target_group(
            architecture_resource_name(name, :tg),
            name: "#{name}-tg",
            port: 80,
            protocol: 'HTTP',
            vpc_id: arch_ref.network.vpc.id,
            
            health_check: {
              enabled: true,
              healthy_threshold: 2,
              unhealthy_threshold: 2,
              timeout: 5,
              interval: 30,
              path: '/',
              matcher: '200'
            },
            
            tags: base_tags.merge(Tier: 'load-balancer', Component: 'target-group')
          )
          
          # ALB Listener
          listener = aws_lb_listener(
            architecture_resource_name(name, :listener),
            load_balancer_arn: alb.arn,
            port: '80',
            protocol: 'HTTP',
            
            default_action: {
              type: 'forward',
              target_group_arn: target_group.arn
            }
          )
          
          # Attach auto scaling group to target group
          attachment = aws_autoscaling_attachment(
            architecture_resource_name(name, :asg_attachment),
            autoscaling_group_name: arch_ref.compute[:auto_scaling_group].name,
            lb_target_group_arn: target_group.arn
          )
          
          {
            load_balancer: alb,
            target_group: target_group,
            listener: listener,
            asg_attachment: attachment
          }
        end
        
        # Create CloudWatch dashboard and alarms
        def create_monitoring_tier(name, arch_ref, arch_attrs, base_tags)
          monitoring_resources = {}
          
          # CloudWatch log group
          monitoring_resources[:log_group] = aws_cloudwatch_log_group(
            architecture_resource_name(name, :log_group),
            name: "/aws/application/#{name}",
            retention_in_days: arch_attrs.log_retention_days,
            
            tags: base_tags.merge(Tier: 'monitoring', Component: 'logs')
          )
          
          # CloudWatch dashboard
          monitoring_resources[:dashboard] = aws_cloudwatch_dashboard(
            architecture_resource_name(name, :dashboard),
            dashboard_name: "#{name.to_s.gsub('_', '-')}-Dashboard",
            
            dashboard_body: generate_dashboard_body(name, arch_ref, arch_attrs)
          )
          
          monitoring_resources
        end
        
        # Generate user data script for web servers
        def generate_user_data(name, arch_ref, arch_attrs)
          database_endpoint = arch_attrs.database_enabled ? arch_ref.database[:instance].endpoint : 'localhost'
          
          <<~USERDATA
            #!/bin/bash
            yum update -y
            yum install -y httpd
            systemctl start httpd
            systemctl enable httpd
            
            # Install CloudWatch agent
            yum install -y amazon-cloudwatch-agent
            
            # Create application directory
            mkdir -p /var/www/#{name}
            
            # Create index.html with architecture info
            cat > /var/www/html/index.html << 'EOF'
            <html>
            <head>
                <title>#{name.to_s.humanize} - #{arch_attrs.environment.capitalize}</title>
                <style>
                    body { font-family: Arial, sans-serif; margin: 40px; }
                    .header { color: #232F3E; }
                    .info { background: #f5f5f5; padding: 20px; margin: 20px 0; }
                    .status { color: #28a745; }
                </style>
            </head>
            <body>
                <h1 class="header">#{name.to_s.humanize}</h1>
                <p class="status">✅ Application is running successfully!</p>
                
                <div class="info">
                    <h3>Architecture Information</h3>
                    <ul>
                        <li><strong>Environment:</strong> #{arch_attrs.environment}</li>
                        <li><strong>Instance Type:</strong> #{arch_attrs.instance_type}</li>
                        <li><strong>Database:</strong> #{arch_attrs.database_enabled ? "#{arch_attrs.database_engine} (#{arch_attrs.database_instance_class})" : 'Disabled'}</li>
                        <li><strong>High Availability:</strong> #{arch_attrs.high_availability ? 'Yes' : 'No'}</li>
                        <li><strong>Availability Zones:</strong> #{arch_attrs.availability_zones.count}</li>
                    </ul>
                </div>
                
                <div class="info">
                    <h3>Infrastructure Details</h3>
                    <ul>
                        <li><strong>Domain:</strong> #{arch_attrs.domain}</li>
                        <li><strong>VPC CIDR:</strong> #{arch_attrs.vpc_cidr}</li>
                        <li><strong>Database Endpoint:</strong> #{database_endpoint}</li>
                        <li><strong>Deployment Time:</strong> #{Time.now}</li>
                    </ul>
                </div>
            </body>
            </html>
            EOF
            
            # Set environment variables for application
            echo "export DB_HOST=#{database_endpoint}" >> /etc/environment
            echo "export APP_ENV=#{arch_attrs.environment}" >> /etc/environment
            echo "export APP_NAME=#{name}" >> /etc/environment
          USERDATA
        end
        
        # Generate CloudWatch dashboard body
        def generate_dashboard_body(name, arch_ref, arch_attrs)
          require 'json'
          JSON.generate({
            widgets: [
              {
                type: 'metric',
                properties: {
                  metrics: [
                    ['AWS/ApplicationELB', 'RequestCount', 'LoadBalancer', arch_ref.compute[:load_balancer][:load_balancer].arn],
                    ['AWS/ApplicationELB', 'TargetResponseTime', 'LoadBalancer', arch_ref.compute[:load_balancer][:load_balancer].arn]
                  ],
                  period: 300,
                  stat: 'Average',
                  region: 'us-east-1',
                  title: 'Application Load Balancer Metrics'
                }
              },
              {
                type: 'metric',
                properties: {
                  metrics: [
                    ['AWS/AutoScaling', 'GroupDesiredCapacity', 'AutoScalingGroupName', arch_ref.compute[:auto_scaling_group].name],
                    ['AWS/AutoScaling', 'GroupInServiceInstances', 'AutoScalingGroupName', arch_ref.compute[:auto_scaling_group].name]
                  ],
                  period: 300,
                  stat: 'Average',
                  region: 'us-east-1',
                  title: 'Auto Scaling Group Metrics'
                }
              }
            ]
          })
        end
      end
    end
  end
end

# Auto-register when loaded
require 'pangea/architecture_registry'
Pangea::ArchitectureRegistry.register_architecture(Pangea::Architectures::Patterns::WebApplication)