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

# Example: Multi-Environment Deployment
# This example demonstrates environment-aware infrastructure that automatically
# adapts based on the deployment namespace (development, staging, production).
# It showcases Pangea's powerful namespace system for managing infrastructure
# across different environments with appropriate sizing, security, and features.

# Template 1: Environment-Aware Web Application
template :web_application do
  provider :aws do
    region ENV['AWS_REGION'] || "us-east-1"
    
    default_tags do
      tags do
        ManagedBy "Pangea"
        Environment namespace
        Project "MultiEnvApp"
        Template "web_application"
        CostCenter environment_cost_center
        Owner environment_owner
      end
    end
  end
  
  # Environment-specific configuration
  env_config = case namespace
  when 'production'
    {
      vpc_cidr: "10.0.0.0/16",
      instance_type: ENV['PROD_INSTANCE_TYPE'] || "t3.medium",
      min_instances: 3,
      max_instances: 20,
      desired_instances: 5,
      database_instance_class: "db.r5.large",
      database_multi_az: true,
      database_backup_retention: 30,
      enable_cloudfront: true,
      enable_waf: true,
      enable_monitoring: true,
      log_retention_days: 90,
      ssl_certificate_required: true,
      high_availability: true
    }
  when 'staging'
    {
      vpc_cidr: "10.1.0.0/16",
      instance_type: ENV['STAGING_INSTANCE_TYPE'] || "t3.small",
      min_instances: 2,
      max_instances: 6,
      desired_instances: 2,
      database_instance_class: "db.t3.medium",
      database_multi_az: false,
      database_backup_retention: 7,
      enable_cloudfront: false,
      enable_waf: false,
      enable_monitoring: true,
      log_retention_days: 30,
      ssl_certificate_required: false,
      high_availability: false
    }
  else # development
    {
      vpc_cidr: "10.2.0.0/16",
      instance_type: ENV['DEV_INSTANCE_TYPE'] || "t3.micro",
      min_instances: 1,
      max_instances: 3,
      desired_instances: 1,
      database_instance_class: "db.t3.micro",
      database_multi_az: false,
      database_backup_retention: 1,
      enable_cloudfront: false,
      enable_waf: false,
      enable_monitoring: false,
      log_retention_days: 7,
      ssl_certificate_required: false,
      high_availability: false
    }
  end
  
  # Environment-specific helper methods
  def environment_cost_center
    case namespace
    when 'production'
      "PROD-001"
    when 'staging'
      "STAGE-001"
    else
      "DEV-001"
    end
  end
  
  def environment_owner
    case namespace
    when 'production'
      "production-team@company.com"
    when 'staging'
      "qa-team@company.com"
    else
      "dev-team@company.com"
    end
  end
  
  def availability_zones
    case namespace
    when 'production'
      ["us-east-1a", "us-east-1b", "us-east-1c"]
    else
      ["us-east-1a", "us-east-1b"]
    end
  end
  
  # VPC with environment-specific CIDR
  vpc = resource :aws_vpc, :main do
    cidr_block env_config[:vpc_cidr]
    enable_dns_hostnames true
    enable_dns_support true
    
    tags do
      Name "MultiEnv-VPC-#{namespace}"
      Environment namespace
      Purpose "WebApplication"
    end
  end
  
  # Internet Gateway
  igw = resource :aws_internet_gateway, :main do
    vpc_id ref(:aws_vpc, :main, :id)
    
    tags do
      Name "MultiEnv-IGW-#{namespace}"
      Environment namespace
    end
  end
  
  # Subnets across availability zones
  availability_zones.each_with_index do |az, index|
    # Public subnets
    resource :"aws_subnet", :"public_#{index + 1}" do
      vpc_id ref(:aws_vpc, :main, :id)
      cidr_block "#{env_config[:vpc_cidr].split('.')[0]}.#{env_config[:vpc_cidr].split('.')[1]}.#{index + 1}.0/24"
      availability_zone az
      map_public_ip_on_launch true
      
      tags do
        Name "MultiEnv-Public-#{index + 1}-#{namespace}"
        Type "public"
        Environment namespace
        AZ az
      end
    end
    
    # Private subnets
    resource :"aws_subnet", :"private_#{index + 1}" do
      vpc_id ref(:aws_vpc, :main, :id)
      cidr_block "#{env_config[:vpc_cidr].split('.')[0]}.#{env_config[:vpc_cidr].split('.')[1]}.#{index + 10}.0/24"
      availability_zone az
      
      tags do
        Name "MultiEnv-Private-#{index + 1}-#{namespace}"
        Type "private"
        Purpose "application"
        Environment namespace
        AZ az
      end
    end
    
    # Database subnets
    resource :"aws_subnet", :"database_#{index + 1}" do
      vpc_id ref(:aws_vpc, :main, :id)
      cidr_block "#{env_config[:vpc_cidr].split('.')[0]}.#{env_config[:vpc_cidr].split('.')[1]}.#{index + 20}.0/24"
      availability_zone az
      
      tags do
        Name "MultiEnv-Database-#{index + 1}-#{namespace}"
        Type "private"
        Purpose "database"
        Environment namespace
        AZ az
      end
    end
  end
  
  # NAT Gateways (production gets multiple for HA, others get one)
  nat_gateway_count = env_config[:high_availability] ? availability_zones.length : 1
  
  nat_gateway_count.times do |index|
    # Elastic IP for NAT Gateway
    resource :"aws_eip", :"nat_#{index + 1}" do
      domain "vpc"
      
      tags do
        Name "MultiEnv-NAT-EIP-#{index + 1}-#{namespace}"
        Environment namespace
        AZ availability_zones[index] if env_config[:high_availability]
      end
    end
    
    # NAT Gateway
    resource :"aws_nat_gateway", :"main_#{index + 1}" do
      allocation_id ref(:"aws_eip", :"nat_#{index + 1}", :id)
      subnet_id ref(:"aws_subnet", :"public_#{index + 1}", :id)
      
      tags do
        Name "MultiEnv-NAT-#{index + 1}-#{namespace}"
        Environment namespace
        AZ availability_zones[index] if env_config[:high_availability]
      end
    end
  end
  
  # Route tables
  public_rt = resource :aws_route_table, :public do
    vpc_id ref(:aws_vpc, :main, :id)
    
    route do
      cidr_block "0.0.0.0/0"
      gateway_id ref(:aws_internet_gateway, :main, :id)
    end
    
    tags do
      Name "MultiEnv-Public-RT-#{namespace}"
      Environment namespace
    end
  end
  
  # Associate public subnets with public route table
  availability_zones.each_with_index do |az, index|
    resource :"aws_route_table_association", :"public_#{index + 1}" do
      subnet_id ref(:"aws_subnet", :"public_#{index + 1}", :id)
      route_table_id ref(:aws_route_table, :public, :id)
    end
  end
  
  # Private route tables - one per AZ for HA, shared for dev/staging
  if env_config[:high_availability]
    availability_zones.each_with_index do |az, index|
      resource :"aws_route_table", :"private_#{index + 1}" do
        vpc_id ref(:aws_vpc, :main, :id)
        
        route do
          cidr_block "0.0.0.0/0"
          nat_gateway_id ref(:"aws_nat_gateway", :"main_#{index + 1}", :id)
        end
        
        tags do
          Name "MultiEnv-Private-RT-#{index + 1}-#{namespace}"
          Environment namespace
          AZ az
        end
      end
      
      resource :"aws_route_table_association", :"private_#{index + 1}" do
        subnet_id ref(:"aws_subnet", :"private_#{index + 1}", :id)
        route_table_id ref(:"aws_route_table", :"private_#{index + 1}", :id)
      end
    end
  else
    # Shared private route table for non-production
    private_rt = resource :aws_route_table, :private do
      vpc_id ref(:aws_vpc, :main, :id)
      
      route do
        cidr_block "0.0.0.0/0"
        nat_gateway_id ref(:aws_nat_gateway, :main_1, :id)
      end
      
      tags do
        Name "MultiEnv-Private-RT-#{namespace}"
        Environment namespace
      end
    end
    
    availability_zones.each_with_index do |az, index|
      resource :"aws_route_table_association", :"private_#{index + 1}" do
        subnet_id ref(:"aws_subnet", :"private_#{index + 1}", :id)
        route_table_id ref(:aws_route_table, :private, :id)
      end
    end
  end
  
  # Security Groups
  alb_sg = resource :aws_security_group, :alb do
    name_prefix "multienv-alb-#{namespace}-"
    vpc_id ref(:aws_vpc, :main, :id)
    description "Application Load Balancer security group for #{namespace}"
    
    ingress do
      from_port 80
      to_port 80
      protocol "tcp"
      cidr_blocks ["0.0.0.0/0"]
      description "HTTP access"
    end
    
    if env_config[:ssl_certificate_required]
      ingress do
        from_port 443
        to_port 443
        protocol "tcp"
        cidr_blocks ["0.0.0.0/0"]
        description "HTTPS access"
      end
    end
    
    egress do
      from_port 8080
      to_port 8080
      protocol "tcp"
      security_groups [ref(:aws_security_group, :app, :id)]
      description "HTTP to application servers"
    end
    
    tags do
      Name "MultiEnv-ALB-SG-#{namespace}"
      Environment namespace
      Purpose "LoadBalancer"
    end
  end
  
  app_sg = resource :aws_security_group, :app do
    name_prefix "multienv-app-#{namespace}-"
    vpc_id ref(:aws_vpc, :main, :id)
    description "Application servers security group for #{namespace}"
    
    ingress do
      from_port 8080
      to_port 8080
      protocol "tcp"
      security_groups [ref(:aws_security_group, :alb, :id)]
      description "HTTP from load balancer"
    end
    
    # SSH access - restricted by environment
    ssh_source = case namespace
    when 'production'
      ["10.0.0.0/16"] # VPC only
    when 'staging'
      ["10.1.0.0/16", "203.0.113.0/24"] # VPC + office network
    else
      ["0.0.0.0/0"] # Open for development
    end
    
    ingress do
      from_port 22
      to_port 22
      protocol "tcp"
      cidr_blocks ssh_source
      description "SSH access - #{namespace} policy"
    end
    
    egress do
      from_port 0
      to_port 0
      protocol "-1"
      cidr_blocks ["0.0.0.0/0"]
      description "All outbound traffic"
    end
    
    tags do
      Name "MultiEnv-App-SG-#{namespace}"
      Environment namespace
      Purpose "Application"
    end
  end
  
  # Application Load Balancer
  alb = resource :aws_lb, :main do
    name_prefix "multienv-#{namespace.first(6)}-"
    load_balancer_type "application"
    scheme "internet-facing"
    
    subnets availability_zones.map.with_index { |az, idx| ref(:"aws_subnet", :"public_#{idx + 1}", :id) }
    security_groups [ref(:aws_security_group, :alb, :id)]
    
    enable_deletion_protection namespace == "production"
    
    # Environment-specific features
    if env_config[:enable_waf]
      enable_waf_fail_open false
      enable_cross_zone_load_balancing true
    end
    
    tags do
      Name "MultiEnv-ALB-#{namespace}"
      Environment namespace
      Purpose "LoadBalancing"
    end
  end
  
  # Target Group
  tg = resource :aws_lb_target_group, :app do
    name_prefix "multienv-app-#{namespace.first(3)}-"
    port 8080
    protocol "HTTP"
    vpc_id ref(:aws_vpc, :main, :id)
    target_type "instance"
    
    health_check do
      enabled true
      healthy_threshold 2
      unhealthy_threshold namespace == "production" ? 2 : 3
      timeout 5
      interval namespace == "production" ? 15 : 30
      path "/health"
      matcher "200"
      protocol "HTTP"
      port "traffic-port"
    end
    
    tags do
      Name "MultiEnv-App-TG-#{namespace}"
      Environment namespace
      Purpose "ApplicationTargeting"
    end
  end
  
  # ALB Listener (HTTP)
  http_listener = resource :aws_lb_listener, :http do
    load_balancer_arn ref(:aws_lb, :main, :arn)
    port "80"
    protocol "HTTP"
    
    default_action do
      type env_config[:ssl_certificate_required] ? "redirect" : "forward"
      
      if env_config[:ssl_certificate_required]
        redirect do
          port "443"
          protocol "HTTPS"
          status_code "HTTP_301"
        end
      else
        target_group_arn ref(:aws_lb_target_group, :app, :arn)
      end
    end
  end
  
  # HTTPS Listener (production only)
  if env_config[:ssl_certificate_required]
    # ACM Certificate
    certificate = resource :aws_acm_certificate, :main do
      domain_name "#{namespace}.example.com"
      validation_method "DNS"
      
      subject_alternative_names ["*.#{namespace}.example.com"]
      
      lifecycle do
        create_before_destroy true
      end
      
      tags do
        Name "MultiEnv-Certificate-#{namespace}"
        Environment namespace
        Purpose "SSL"
      end
    end
    
    https_listener = resource :aws_lb_listener, :https do
      load_balancer_arn ref(:aws_lb, :main, :arn)
      port "443"
      protocol "HTTPS"
      ssl_policy "ELBSecurityPolicy-TLS-1-2-2017-01"
      certificate_arn ref(:aws_acm_certificate, :main, :arn)
      
      default_action do
        type "forward"
        target_group_arn ref(:aws_lb_target_group, :app, :arn)
      end
    end
  end
  
  # Launch Template
  launch_template = resource :aws_launch_template, :app do
    name_prefix "multienv-#{namespace}-"
    description "Launch template for #{namespace} environment"
    
    image_id data(:aws_ami, :amazon_linux, :id)
    instance_type env_config[:instance_type]
    
    vpc_security_group_ids [ref(:aws_security_group, :app, :id)]
    
    monitoring do
      enabled env_config[:enable_monitoring]
    end
    
    # Environment-specific instance metadata
    metadata_options do
      http_endpoint "enabled"
      http_tokens "required" # IMDSv2 required
      http_put_response_hop_limit namespace == "production" ? 1 : 2
      instance_metadata_tags "enabled"
    end
    
    # User data with environment-specific configuration
    user_data base64encode(<<~USERDATA)
      #!/bin/bash
      yum update -y
      yum install -y docker
      systemctl start docker
      systemctl enable docker
      usermod -aG docker ec2-user
      
      # Environment-specific application configuration
      cat > /opt/app-config.json << 'EOF'
      {
        "environment": "#{namespace}",
        "debug": #{namespace != "production"},
        "log_level": "#{namespace == "production" ? "info" : "debug"}",
        "database_pool_size": #{namespace == "production" ? 20 : 5},
        "cache_ttl": #{namespace == "production" ? 300 : 60},
        "features": {
          "analytics": #{namespace == "production"},
          "debugging": #{namespace != "production"}
        }
      }
      EOF
      
      # Install CloudWatch agent for production monitoring
      #{env_config[:enable_monitoring] ? 
        'wget https://s3.amazonaws.com/amazoncloudwatch-agent/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm && rpm -U ./amazon-cloudwatch-agent.rpm' : 
        'echo "Monitoring disabled for #{namespace}"'}
      
      # Simple application server
      docker run -d -p 8080:8080 \\
        -v /opt/app-config.json:/app/config.json \\
        -e ENVIRONMENT=#{namespace} \\
        --name app-server \\
        nginx:alpine
    USERDATA
    
    tag_specifications do
      resource_type "instance"
      tags do
        Name "MultiEnv-App-Instance-#{namespace}"
        Environment namespace
        LaunchedBy "AutoScalingGroup"
        InstanceType env_config[:instance_type]
      end
    end
    
    tags do
      Name "MultiEnv-LaunchTemplate-#{namespace}"
      Environment namespace
      Purpose "ApplicationLaunching"
    end
  end
  
  # Data source for Amazon Linux AMI
  data :aws_ami, :amazon_linux do
    most_recent true
    owners ["amazon"]
    
    filter do
      name "name"
      values ["amzn2-ami-hvm-*-x86_64-gp2"]
    end
    
    filter do
      name "state"
      values ["available"]
    end
  end
  
  # Auto Scaling Group
  asg = resource :aws_autoscaling_group, :app do
    name "multienv-app-asg-#{namespace}"
    vpc_zone_identifier availability_zones.map.with_index { |az, idx| ref(:"aws_subnet", :"private_#{idx + 1}", :id) }
    
    target_group_arns [ref(:aws_lb_target_group, :app, :arn)]
    health_check_type "ELB"
    health_check_grace_period namespace == "production" ? 300 : 180
    
    min_size env_config[:min_instances]
    max_size env_config[:max_instances]
    desired_capacity env_config[:desired_instances]
    
    launch_template do
      id ref(:aws_launch_template, :app, :id)
      version "$Latest"
    end
    
    # Environment-specific scaling policies
    default_cooldown namespace == "production" ? 300 : 180
    
    # Instance refresh for zero-downtime deployments (production only)
    if namespace == "production"
      instance_refresh do
        strategy "Rolling"
        preferences do
          min_healthy_percentage 50
          instance_warmup 300
        end
      end
    end
    
    tag do
      key "Name"
      value "MultiEnv-App-ASG-#{namespace}"
      propagate_at_launch true
    end
    
    tag do
      key "Environment"
      value namespace
      propagate_at_launch true
    end
    
    tag do
      key "Purpose"
      value "ApplicationAutoScaling"
      propagate_at_launch true
    end
  end
  
  # Auto Scaling Policies - environment-specific thresholds
  scale_up_threshold = case namespace
  when 'production'
    70
  when 'staging'
    80
  else
    85
  end
  
  scale_down_threshold = case namespace
  when 'production'
    30
  when 'staging'
    20
  else
    10
  end
  
  scale_up_policy = resource :aws_autoscaling_policy, :scale_up do
    name "multienv-scale-up-#{namespace}"
    scaling_adjustment 1
    adjustment_type "ChangeInCapacity"
    cooldown namespace == "production" ? 300 : 180
    autoscaling_group_name ref(:aws_autoscaling_group, :app, :name)
  end
  
  scale_down_policy = resource :aws_autoscaling_policy, :scale_down do
    name "multienv-scale-down-#{namespace}"
    scaling_adjustment -1
    adjustment_type "ChangeInCapacity"
    cooldown namespace == "production" ? 300 : 180
    autoscaling_group_name ref(:aws_autoscaling_group, :app, :name)
  end
  
  # CloudWatch alarms with environment-specific thresholds
  cpu_high_alarm = resource :aws_cloudwatch_metric_alarm, :cpu_high do
    alarm_name "multienv-cpu-high-#{namespace}"
    alarm_description "Scale up when CPU > #{scale_up_threshold}%"
    comparison_operator "GreaterThanThreshold"
    evaluation_periods namespace == "production" ? 2 : 1
    metric_name "CPUUtilization"
    namespace "AWS/EC2"
    period 300
    statistic "Average"
    threshold scale_up_threshold
    alarm_actions [ref(:aws_autoscaling_policy, :scale_up, :arn)]
    
    dimensions do
      AutoScalingGroupName ref(:aws_autoscaling_group, :app, :name)
    end
    
    tags do
      Name "MultiEnv-CPU-High-#{namespace}"
      Environment namespace
      AlertType "ScaleUp"
    end
  end
  
  cpu_low_alarm = resource :aws_cloudwatch_metric_alarm, :cpu_low do
    alarm_name "multienv-cpu-low-#{namespace}"
    alarm_description "Scale down when CPU < #{scale_down_threshold}%"
    comparison_operator "LessThanThreshold"
    evaluation_periods namespace == "production" ? 3 : 2
    metric_name "CPUUtilization"
    namespace "AWS/EC2"
    period 300
    statistic "Average"
    threshold scale_down_threshold
    alarm_actions [ref(:aws_autoscaling_policy, :scale_down, :arn)]
    
    dimensions do
      AutoScalingGroupName ref(:aws_autoscaling_group, :app, :name)
    end
    
    tags do
      Name "MultiEnv-CPU-Low-#{namespace}"
      Environment namespace
      AlertType "ScaleDown"
    end
  end
  
  # CloudWatch Log Group with environment-specific retention
  app_log_group = resource :aws_cloudwatch_log_group, :app do
    name "/aws/ec2/multienv/#{namespace}"
    retention_in_days env_config[:log_retention_days]
    
    tags do
      Name "MultiEnv-App-Logs-#{namespace}"
      Environment namespace
      Purpose "ApplicationLogging"
    end
  end
  
  # CloudFront Distribution (production only)
  if env_config[:enable_cloudfront]
    cloudfront = resource :aws_cloudfront_distribution, :main do
      comment "CloudFront distribution for #{namespace} environment"
      default_root_object "index.html"
      enabled true
      is_ipv6_enabled true
      price_class "PriceClass_100"
      
      origin do
        domain_name ref(:aws_lb, :main, :dns_name)
        origin_id "ALB-#{ref(:aws_lb, :main, :name)}"
        
        custom_origin_config do
          http_port 80
          https_port 443
          origin_protocol_policy "https-only"
          origin_ssl_protocols ["TLSv1.2"]
        end
      end
      
      default_cache_behavior do
        allowed_methods ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
        cached_methods ["GET", "HEAD"]
        target_origin_id "ALB-#{ref(:aws_lb, :main, :name)}"
        
        forwarded_values do
          query_string false
          cookies do
            forward "none"
          end
        end
        
        viewer_protocol_policy "redirect-to-https"
        min_ttl 0
        default_ttl 3600
        max_ttl 86400
        compress true
      end
      
      restrictions do
        geo_restriction do
          restriction_type "none"
        end
      end
      
      viewer_certificate do
        cloudfront_default_certificate true
      end
      
      tags do
        Name "MultiEnv-CloudFront-#{namespace}"
        Environment namespace
        Purpose "ContentDelivery"
      end
    end
  end
  
  # Outputs
  output :vpc_id do
    value ref(:aws_vpc, :main, :id)
    description "VPC ID for #{namespace} environment"
  end
  
  output :load_balancer_dns do
    value ref(:aws_lb, :main, :dns_name)
    description "Application Load Balancer DNS name"
  end
  
  output :application_url do
    value env_config[:ssl_certificate_required] ? 
      "https://#{ref(:aws_lb, :main, :dns_name)}" : 
      "http://#{ref(:aws_lb, :main, :dns_name)}"
    description "Application URL for #{namespace} environment"
  end
  
  if env_config[:enable_cloudfront]
    output :cloudfront_distribution_id do
      value ref(:aws_cloudfront_distribution, :main, :id)
      description "CloudFront distribution ID"
    end
    
    output :cloudfront_domain_name do
      value ref(:aws_cloudfront_distribution, :main, :domain_name)
      description "CloudFront distribution domain name"
    end
  end
  
  output :auto_scaling_group_name do
    value ref(:aws_autoscaling_group, :app, :name)
    description "Auto Scaling Group name"
  end
  
  output :environment_config do
    value env_config
    description "Environment-specific configuration"
  end
end

# Template 2: Environment-Aware Database
template :database do
  provider :aws do
    region ENV['AWS_REGION'] || "us-east-1"
    
    default_tags do
      tags do
        ManagedBy "Pangea"
        Environment namespace
        Project "MultiEnvApp"
        Template "database"
      end
    end
  end
  
  # Environment-specific database configuration
  db_config = case namespace
  when 'production'
    {
      instance_class: ENV['PROD_DB_INSTANCE_CLASS'] || "db.r5.large",
      allocated_storage: 100,
      max_allocated_storage: 1000,
      multi_az: true,
      backup_retention_period: 30,
      backup_window: "03:00-04:00",
      maintenance_window: "sun:04:00-sun:05:00",
      deletion_protection: true,
      skip_final_snapshot: false,
      final_snapshot_identifier: "multienv-final-snapshot-#{namespace}",
      monitoring_interval: 60,
      performance_insights_enabled: true,
      performance_insights_retention_period: 7,
      enabled_cloudwatch_logs_exports: ["postgresql"],
      storage_encrypted: true,
      auto_minor_version_upgrade: false
    }
  when 'staging'
    {
      instance_class: ENV['STAGING_DB_INSTANCE_CLASS'] || "db.t3.medium",
      allocated_storage: 50,
      max_allocated_storage: 200,
      multi_az: false,
      backup_retention_period: 7,
      backup_window: "03:00-04:00",
      maintenance_window: "sun:04:00-sun:05:00",
      deletion_protection: false,
      skip_final_snapshot: true,
      monitoring_interval: 0,
      performance_insights_enabled: false,
      enabled_cloudwatch_logs_exports: [],
      storage_encrypted: true,
      auto_minor_version_upgrade: true
    }
  else # development
    {
      instance_class: ENV['DEV_DB_INSTANCE_CLASS'] || "db.t3.micro",
      allocated_storage: 20,
      max_allocated_storage: 100,
      multi_az: false,
      backup_retention_period: 1,
      backup_window: "03:00-04:00",
      maintenance_window: "sun:04:00-sun:05:00",
      deletion_protection: false,
      skip_final_snapshot: true,
      monitoring_interval: 0,
      performance_insights_enabled: false,
      enabled_cloudwatch_logs_exports: [],
      storage_encrypted: false,
      auto_minor_version_upgrade: true
    }
  end
  
  # Reference VPC from web application template
  data :aws_vpc, :main do
    filter do
      name "tag:Name"
      values ["MultiEnv-VPC-#{namespace}"]
    end
  end
  
  # Reference database subnets
  data :aws_subnets, :database do
    filter do
      name "vpc-id"
      values [data(:aws_vpc, :main, :id)]
    end
    
    filter do
      name "tag:Purpose"
      values ["database"]
    end
  end
  
  # Database subnet group
  db_subnet_group = resource :aws_db_subnet_group, :main do
    name_prefix "multienv-#{namespace}-"
    subnet_ids data(:aws_subnets, :database, :ids)
    description "Database subnet group for #{namespace} environment"
    
    tags do
      Name "MultiEnv-DB-SubnetGroup-#{namespace}"
      Environment namespace
      Purpose "DatabaseNetworking"
    end
  end
  
  # Database security group
  db_sg = resource :aws_security_group, :database do
    name_prefix "multienv-db-#{namespace}-"
    vpc_id data(:aws_vpc, :main, :id)
    description "Database security group for #{namespace} environment"
    
    ingress do
      from_port 5432
      to_port 5432
      protocol "tcp"
      cidr_blocks [data(:aws_vpc, :main, :cidr_block)]
      description "PostgreSQL access from VPC"
    end
    
    # Development allows broader access for debugging
    if namespace == "development"
      ingress do
        from_port 5432
        to_port 5432
        protocol "tcp"
        cidr_blocks ["203.0.113.0/24"] # Office network
        description "PostgreSQL access from office (dev only)"
      end
    end
    
    tags do
      Name "MultiEnv-DB-SG-#{namespace}"
      Environment namespace
      Purpose "DatabaseSecurity"
    end
  end
  
  # Database parameter group with environment-specific tuning
  db_parameter_group = resource :aws_db_parameter_group, :main do
    name_prefix "multienv-postgres-#{namespace}-"
    family "postgres15"
    description "PostgreSQL parameter group for #{namespace} environment"
    
    # Production gets performance tuning
    if namespace == "production"
      parameter do
        name "shared_preload_libraries"
        value "pg_stat_statements"
      end
      
      parameter do
        name "log_statement"
        value "none"
      end
      
      parameter do
        name "log_min_duration_statement"
        value "1000"
      end
      
      parameter do
        name "effective_cache_size"
        value "6GB"
      end
      
      parameter do
        name "maintenance_work_mem"
        value "512MB"
      end
    else
      # Development/staging gets debugging features
      parameter do
        name "log_statement"
        value "all"
      end
      
      parameter do
        name "log_min_duration_statement"
        value "100"
      end
      
      parameter do
        name "log_min_messages"
        value "info"
      end
    end
    
    tags do
      Name "MultiEnv-DB-ParamGroup-#{namespace}"
      Environment namespace
      Purpose "DatabaseTuning"
    end
  end
  
  # Random password for database
  db_password = resource :random_password, :db do
    length 32
    special true
    override_special "!#$%&*()-_=+[]{}<>:?"
  end
  
  # Secrets Manager for database credentials
  db_secret = resource :aws_secretsmanager_secret, :db do
    name_prefix "multienv-db-credentials-#{namespace}-"
    description "Database credentials for #{namespace} environment"
    
    tags do
      Name "MultiEnv-DB-Secret-#{namespace}"
      Environment namespace
      Purpose "DatabaseCredentials"
    end
  end
  
  db_secret_version = resource :aws_secretsmanager_secret_version, :db do
    secret_id ref(:aws_secretsmanager_secret, :db, :id)
    secret_string jsonencode({
      username: "appuser",
      password: ref(:random_password, :db, :result),
      engine: "postgres",
      host: ref(:aws_db_instance, :main, :endpoint),
      port: 5432,
      dbname: "appdb"
    })
  end
  
  # RDS instance with environment-specific configuration
  rds_instance = resource :aws_db_instance, :main do
    identifier_prefix "multienv-#{namespace}-"
    
    engine "postgres"
    engine_version "15.4"
    instance_class db_config[:instance_class]
    allocated_storage db_config[:allocated_storage]
    max_allocated_storage db_config[:max_allocated_storage]
    storage_type "gp3"
    storage_encrypted db_config[:storage_encrypted]
    
    db_name "appdb"
    username "appuser"
    password ref(:random_password, :db, :result)
    
    vpc_security_group_ids [ref(:aws_security_group, :database, :id)]
    db_subnet_group_name ref(:aws_db_subnet_group, :main, :name)
    parameter_group_name ref(:aws_db_parameter_group, :main, :name)
    
    backup_retention_period db_config[:backup_retention_period]
    backup_window db_config[:backup_window]
    maintenance_window db_config[:maintenance_window]
    
    multi_az db_config[:multi_az]
    deletion_protection db_config[:deletion_protection]
    skip_final_snapshot db_config[:skip_final_snapshot]
    final_snapshot_identifier db_config[:final_snapshot_identifier] if !db_config[:skip_final_snapshot]
    
    monitoring_interval db_config[:monitoring_interval]
    monitoring_role_arn db_config[:monitoring_interval] > 0 ? ref(:aws_iam_role, :rds_monitoring, :arn) : nil
    enabled_cloudwatch_logs_exports db_config[:enabled_cloudwatch_logs_exports]
    
    performance_insights_enabled db_config[:performance_insights_enabled]
    performance_insights_retention_period db_config[:performance_insights_retention_period] if db_config[:performance_insights_enabled]
    
    auto_minor_version_upgrade db_config[:auto_minor_version_upgrade]
    
    # Copy tags from application
    copy_tags_to_snapshot true
    
    tags do
      Name "MultiEnv-DB-#{namespace}"
      Environment namespace
      Purpose "ApplicationDatabase"
      InstanceClass db_config[:instance_class]
      MultiAZ db_config[:multi_az].to_s
    end
  end
  
  # RDS monitoring role (for enhanced monitoring)
  if db_config[:monitoring_interval] > 0
    rds_monitoring_role = resource :aws_iam_role, :rds_monitoring do
      name_prefix "MultiEnv-RDS-Monitoring-#{namespace}-"
      assume_role_policy jsonencode({
        Version: "2012-10-17",
        Statement: [
          {
            Action: "sts:AssumeRole",
            Effect: "Allow",
            Principal: {
              Service: "monitoring.rds.amazonaws.com"
            }
          }
        ]
      })
      
      tags do
        Name "MultiEnv-RDS-Monitoring-Role-#{namespace}"
        Environment namespace
        Purpose "DatabaseMonitoring"
      end
    end
    
    resource :aws_iam_role_policy_attachment, :rds_monitoring do
      role ref(:aws_iam_role, :rds_monitoring, :name)
      policy_arn "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
    end
  end
  
  # Read replica for production
  if namespace == "production"
    read_replica = resource :aws_db_instance, :read_replica do
      identifier_prefix "multienv-#{namespace}-replica-"
      replicate_source_db ref(:aws_db_instance, :main, :id)
      
      instance_class db_config[:instance_class]
      auto_minor_version_upgrade false
      
      monitoring_interval db_config[:monitoring_interval]
      monitoring_role_arn db_config[:monitoring_interval] > 0 ? ref(:aws_iam_role, :rds_monitoring, :arn) : nil
      
      performance_insights_enabled db_config[:performance_insights_enabled]
      performance_insights_retention_period db_config[:performance_insights_retention_period] if db_config[:performance_insights_enabled]
      
      tags do
        Name "MultiEnv-DB-ReadReplica-#{namespace}"
        Environment namespace
        Purpose "ReadReplica"
      end
    end
  end
  
  # CloudWatch alarms for database monitoring (production only)
  if namespace == "production"
    # CPU utilization alarm
    cpu_alarm = resource :aws_cloudwatch_metric_alarm, :db_cpu do
      alarm_name "multienv-db-cpu-#{namespace}"
      alarm_description "Database CPU utilization is too high"
      comparison_operator "GreaterThanThreshold"
      evaluation_periods 3
      metric_name "CPUUtilization"
      namespace "AWS/RDS"
      period 300
      statistic "Average"
      threshold 80
      treat_missing_data "notBreaching"
      
      dimensions do
        DBInstanceIdentifier ref(:aws_db_instance, :main, :id)
      end
      
      tags do
        Name "MultiEnv-DB-CPU-Alarm-#{namespace}"
        Environment namespace
        AlertType "DatabaseCPU"
      end
    end
    
    # Connection count alarm
    connection_alarm = resource :aws_cloudwatch_metric_alarm, :db_connections do
      alarm_name "multienv-db-connections-#{namespace}"
      alarm_description "Database connection count is too high"
      comparison_operator "GreaterThanThreshold"
      evaluation_periods 2
      metric_name "DatabaseConnections"
      namespace "AWS/RDS"
      period 300
      statistic "Average"
      threshold 80
      treat_missing_data "notBreaching"
      
      dimensions do
        DBInstanceIdentifier ref(:aws_db_instance, :main, :id)
      end
      
      tags do
        Name "MultiEnv-DB-Connections-Alarm-#{namespace}"
        Environment namespace
        AlertType "DatabaseConnections"
      end
    end
  end
  
  # Outputs
  output :database_endpoint do
    value ref(:aws_db_instance, :main, :endpoint)
    description "Database endpoint for #{namespace} environment"
  end
  
  output :database_port do
    value ref(:aws_db_instance, :main, :port)
    description "Database port"
  end
  
  output :database_secret_arn do
    value ref(:aws_secretsmanager_secret, :db, :arn)
    description "Secrets Manager ARN for database credentials"
  end
  
  if namespace == "production"
    output :read_replica_endpoint do
      value ref(:aws_db_instance, :read_replica, :endpoint)
      description "Read replica endpoint"
    end
  end
  
  output :database_config do
    value db_config
    description "Database configuration for #{namespace} environment"
  end
end

# This multi-environment deployment example demonstrates several key concepts:
#
# 1. **Environment-Aware Configuration**: Templates automatically adapt based on
#    the deployment namespace with appropriate sizing, security, and features.
#
# 2. **Progressive Feature Enablement**: Production gets advanced features like
#    CloudFront, WAF, enhanced monitoring, and SSL certificates, while development
#    environments focus on cost optimization and debugging capabilities.
#
# 3. **Security by Environment**: SSH access, database access, and monitoring
#    configurations adapt to security requirements per environment.
#
# 4. **Cost Optimization**: Resource sizing, backup retention, monitoring, and
#    high availability features scale appropriately with environment criticality.
#
# 5. **Operational Excellence**: Production environments get enhanced monitoring,
#    performance insights, read replicas, and stricter deployment controls.
#
# 6. **Template Consistency**: Same infrastructure code works across all
#    environments while providing environment-specific optimizations.
#
# Environment-specific deployment examples:
#
# Development (minimal resources, debugging enabled):
#   pangea apply examples/multi-environment-deployment.rb --namespace development
#
# Staging (production-like but cost-optimized):
#   pangea apply examples/multi-environment-deployment.rb --namespace staging
#
# Production (full features, high availability, monitoring):
#   export PROD_INSTANCE_TYPE=t3.large
#   export PROD_DB_INSTANCE_CLASS=db.r5.xlarge
#   pangea apply examples/multi-environment-deployment.rb --namespace production
#
# This example showcases how Pangea's namespace system enables sophisticated
# environment management with a single codebase that adapts intelligently
# to deployment context.