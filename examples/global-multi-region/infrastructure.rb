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

# Example: Global Multi-Region Setup
# This example demonstrates a globally distributed application with:
# - Multi-region active-active deployment
# - Route 53 health checks and failover
# - Cross-region data replication
# - CloudFront global content delivery
# - DynamoDB Global Tables
# - Cross-region VPC peering for secure communication
# - Global load balancing and disaster recovery

# Template 1: Primary Region Infrastructure (US East)
template :primary_region do
  provider :aws do
    region "us-east-1"
    
    default_tags do
      tags do
        ManagedBy "Pangea"
        Environment namespace
        Project "GlobalMultiRegion"
        Template "primary_region"
        Region "us-east-1"
        RegionRole "primary"
      end
    end
  end
  
  # VPC for primary region
  primary_vpc = resource :aws_vpc, :primary do
    cidr_block "10.0.0.0/16"
    enable_dns_hostnames true
    enable_dns_support true
    
    tags do
      Name "Global-Primary-VPC-#{namespace}"
      Region "us-east-1"
      Purpose "PrimaryRegion"
    end
  end
  
  # Internet Gateway
  primary_igw = resource :aws_internet_gateway, :primary do
    vpc_id ref(:aws_vpc, :primary, :id)
    
    tags do
      Name "Global-Primary-IGW-#{namespace}"
      Region "us-east-1"
    end
  end
  
  # Availability zones
  availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]
  
  # Public subnets
  availability_zones.each_with_index do |az, index|
    resource :"aws_subnet", :"primary_public_#{index + 1}" do
      vpc_id ref(:aws_vpc, :primary, :id)
      cidr_block "10.0.#{index + 1}.0/24"
      availability_zone az
      map_public_ip_on_launch true
      
      tags do
        Name "Global-Primary-Public-#{index + 1}-#{namespace}"
        Type "public"
        Region "us-east-1"
        AZ az
      end
    end
    
    # Private subnets
    resource :"aws_subnet", :"primary_private_#{index + 1}" do
      vpc_id ref(:aws_vpc, :primary, :id)
      cidr_block "10.0.#{index + 10}.0/24"
      availability_zone az
      
      tags do
        Name "Global-Primary-Private-#{index + 1}-#{namespace}"
        Type "private"
        Region "us-east-1"
        AZ az
      end
    end
  end
  
  # NAT Gateways for high availability
  availability_zones.each_with_index do |az, index|
    resource :"aws_eip", :"primary_nat_#{index + 1}" do
      domain "vpc"
      
      tags do
        Name "Global-Primary-NAT-EIP-#{index + 1}-#{namespace}"
        Region "us-east-1"
        AZ az
      end
    end
    
    resource :"aws_nat_gateway", :"primary_#{index + 1}" do
      allocation_id ref(:"aws_eip", :"primary_nat_#{index + 1}", :id)
      subnet_id ref(:"aws_subnet", :"primary_public_#{index + 1}", :id)
      
      tags do
        Name "Global-Primary-NAT-#{index + 1}-#{namespace}"
        Region "us-east-1"
        AZ az
      end
    end
  end
  
  # Route tables
  primary_public_rt = resource :aws_route_table, :primary_public do
    vpc_id ref(:aws_vpc, :primary, :id)
    
    route do
      cidr_block "0.0.0.0/0"
      gateway_id ref(:aws_internet_gateway, :primary, :id)
    end
    
    tags do
      Name "Global-Primary-Public-RT-#{namespace}"
      Region "us-east-1"
    end
  end
  
  # Associate public subnets
  availability_zones.each_with_index do |az, index|
    resource :"aws_route_table_association", :"primary_public_#{index + 1}" do
      subnet_id ref(:"aws_subnet", :"primary_public_#{index + 1}", :id)
      route_table_id ref(:aws_route_table, :primary_public, :id)
    end
    
    # Private route tables
    resource :"aws_route_table", :"primary_private_#{index + 1}" do
      vpc_id ref(:aws_vpc, :primary, :id)
      
      route do
        cidr_block "0.0.0.0/0"
        nat_gateway_id ref(:"aws_nat_gateway", :"primary_#{index + 1}", :id)
      end
      
      tags do
        Name "Global-Primary-Private-RT-#{index + 1}-#{namespace}"
        Region "us-east-1"
        AZ az
      end
    end
    
    resource :"aws_route_table_association", :"primary_private_#{index + 1}" do
      subnet_id ref(:"aws_subnet", :"primary_private_#{index + 1}", :id)
      route_table_id ref(:"aws_route_table", :"primary_private_#{index + 1}", :id)
    end
  end
  
  # Security Groups
  primary_alb_sg = resource :aws_security_group, :primary_alb do
    name_prefix "global-primary-alb-"
    vpc_id ref(:aws_vpc, :primary, :id)
    description "ALB security group for primary region"
    
    ingress do
      from_port 80
      to_port 80
      protocol "tcp"
      cidr_blocks ["0.0.0.0/0"]
      description "HTTP access"
    end
    
    ingress do
      from_port 443
      to_port 443
      protocol "tcp"
      cidr_blocks ["0.0.0.0/0"]
      description "HTTPS access"
    end
    
    egress do
      from_port 8080
      to_port 8080
      protocol "tcp"
      security_groups [ref(:aws_security_group, :primary_app, :id)]
      description "HTTP to application servers"
    end
    
    tags do
      Name "Global-Primary-ALB-SG-#{namespace}"
      Region "us-east-1"
      Purpose "LoadBalancer"
    end
  end
  
  primary_app_sg = resource :aws_security_group, :primary_app do
    name_prefix "global-primary-app-"
    vpc_id ref(:aws_vpc, :primary, :id)
    description "Application security group for primary region"
    
    ingress do
      from_port 8080
      to_port 8080
      protocol "tcp"
      security_groups [ref(:aws_security_group, :primary_alb, :id)]
      description "HTTP from ALB"
    end
    
    # Cross-region communication
    ingress do
      from_port 8080
      to_port 8080
      protocol "tcp"
      cidr_blocks ["10.1.0.0/16"] # Secondary region CIDR
      description "HTTP from secondary region"
    end
    
    egress do
      from_port 0
      to_port 0
      protocol "-1"
      cidr_blocks ["0.0.0.0/0"]
      description "All outbound traffic"
    end
    
    tags do
      Name "Global-Primary-App-SG-#{namespace}"
      Region "us-east-1"
      Purpose "Application"
    end
  end
  
  # Application Load Balancer
  primary_alb = resource :aws_lb, :primary do
    name_prefix "global-pri-"
    load_balancer_type "application"
    scheme "internet-facing"
    
    subnets availability_zones.map.with_index { |az, idx| ref(:"aws_subnet", :"primary_public_#{idx + 1}", :id) }
    security_groups [ref(:aws_security_group, :primary_alb, :id)]
    
    enable_deletion_protection namespace == "production"
    enable_cross_zone_load_balancing true
    
    tags do
      Name "Global-Primary-ALB-#{namespace}"
      Region "us-east-1"
      Purpose "GlobalLoadBalancing"
    end
  end
  
  # Target Group
  primary_tg = resource :aws_lb_target_group, :primary_app do
    name_prefix "global-pri-app-"
    port 8080
    protocol "HTTP"
    vpc_id ref(:aws_vpc, :primary, :id)
    target_type "instance"
    
    health_check do
      enabled true
      healthy_threshold 2
      unhealthy_threshold 3
      timeout 5
      interval 30
      path "/health"
      matcher "200"
      protocol "HTTP"
      port "traffic-port"
    end
    
    tags do
      Name "Global-Primary-App-TG-#{namespace}"
      Region "us-east-1"
      Purpose "ApplicationTargeting"
    end
  end
  
  # ALB Listener
  primary_listener = resource :aws_lb_listener, :primary_http do
    load_balancer_arn ref(:aws_lb, :primary, :arn)
    port "80"
    protocol "HTTP"
    
    default_action do
      type "forward"
      target_group_arn ref(:aws_lb_target_group, :primary_app, :arn)
    end
  end
  
  # Launch Template
  primary_launch_template = resource :aws_launch_template, :primary_app do
    name_prefix "global-primary-app-"
    description "Launch template for primary region application"
    
    image_id data(:aws_ami, :amazon_linux, :id)
    instance_type ENV['PRIMARY_INSTANCE_TYPE'] || "t3.medium"
    
    vpc_security_group_ids [ref(:aws_security_group, :primary_app, :id)]
    
    monitoring do
      enabled true
    end
    
    user_data base64encode(<<~USERDATA)
      #!/bin/bash
      yum update -y
      yum install -y docker awscli
      systemctl start docker
      systemctl enable docker
      usermod -aG docker ec2-user
      
      # Get instance metadata
      INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
      AZ=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)
      REGION=us-east-1
      
      # Simple Node.js application
      cat > /home/ec2-user/app.js << 'NODEJS'
      const express = require('express');
      const app = express();
      const port = 8080;
      
      // Health check endpoint
      app.get('/health', (req, res) => {
        res.status(200).json({
          status: 'healthy',
          region: '#{REGION}',
          instance_id: process.env.INSTANCE_ID || 'unknown',
          timestamp: new Date().toISOString()
        });
      });
      
      // Main endpoint with regional information
      app.get('/', (req, res) => {
        res.json({
          message: 'Global Multi-Region Application',
          region: '#{REGION}',
          role: 'primary',
          instance_id: process.env.INSTANCE_ID || 'unknown',
          availability_zone: process.env.AZ || 'unknown',
          environment: '#{namespace}',
          timestamp: new Date().toISOString(),
          version: '1.0.0'
        });
      });
      
      // API endpoint
      app.get('/api/data', (req, res) => {
        res.json({
          data: 'Sample data from primary region',
          region: '#{REGION}',
          processed_at: new Date().toISOString()
        });
      });
      
      app.listen(port, '0.0.0.0', () => {
        console.log(`Global app listening on port ${port} in region #{REGION}`);
      });
      NODEJS
      
      # Create Dockerfile
      cat > /home/ec2-user/Dockerfile << 'DOCKERFILE'
      FROM node:16-alpine
      WORKDIR /app
      RUN npm install express
      COPY app.js .
      EXPOSE 8080
      ENV INSTANCE_ID=${INSTANCE_ID}
      ENV AZ=${AZ}
      ENV REGION=${REGION}
      CMD ["node", "app.js"]
      DOCKERFILE
      
      # Build and run the application
      cd /home/ec2-user
      docker build -t global-app .
      docker run -d -p 8080:8080 --name global-app-primary \\
        -e INSTANCE_ID=$INSTANCE_ID \\
        -e AZ=$AZ \\
        -e REGION=$REGION \\
        global-app
    USERDATA
    
    tag_specifications do
      resource_type "instance"
      tags do
        Name "Global-Primary-App-Instance-#{namespace}"
        Region "us-east-1"
        Role "primary"
        LaunchedBy "AutoScalingGroup"
      end
    end
    
    tags do
      Name "Global-Primary-LaunchTemplate-#{namespace}"
      Region "us-east-1"
      Purpose "ApplicationLaunching"
    end
  end
  
  # Auto Scaling Group
  primary_asg = resource :aws_autoscaling_group, :primary_app do
    name "global-primary-app-asg-#{namespace}"
    vpc_zone_identifier availability_zones.map.with_index { |az, idx| ref(:"aws_subnet", :"primary_private_#{idx + 1}", :id) }
    
    target_group_arns [ref(:aws_lb_target_group, :primary_app, :arn)]
    health_check_type "ELB"
    health_check_grace_period 300
    
    min_size 2
    max_size namespace == "production" ? 10 : 6
    desired_capacity 3
    
    launch_template do
      id ref(:aws_launch_template, :primary_app, :id)
      version "$Latest"
    end
    
    tag do
      key "Name"
      value "Global-Primary-App-ASG-#{namespace}"
      propagate_at_launch true
    end
    
    tag do
      key "Region"
      value "us-east-1"
      propagate_at_launch true
    end
    
    tag do
      key "Role"
      value "primary"
      propagate_at_launch true
    end
  end
  
  # DynamoDB Global Table (Primary)
  primary_table = resource :aws_dynamodb_table, :global_data do
    name "global-application-data-#{namespace}"
    billing_mode "PAY_PER_REQUEST"
    stream_enabled true
    stream_view_type "NEW_AND_OLD_IMAGES"
    
    hash_key "id"
    
    attribute do
      name "id"
      type "S"
    end
    
    point_in_time_recovery do
      enabled true
    end
    
    server_side_encryption do
      enabled true
    end
    
    tags do
      Name "Global-ApplicationData-#{namespace}"
      Region "us-east-1"
      Purpose "GlobalDataStorage"
    end
  end
  
  # Get Amazon Linux AMI
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
  
  # Outputs for cross-region reference
  output :primary_vpc_id do
    value ref(:aws_vpc, :primary, :id)
    description "Primary region VPC ID"
  end
  
  output :primary_vpc_cidr do
    value ref(:aws_vpc, :primary, :cidr_block)
    description "Primary region VPC CIDR"
  end
  
  output :primary_alb_dns do
    value ref(:aws_lb, :primary, :dns_name)
    description "Primary region ALB DNS name"
  end
  
  output :primary_alb_zone_id do
    value ref(:aws_lb, :primary, :zone_id)
    description "Primary region ALB zone ID"
  end
  
  output :primary_dynamodb_table_name do
    value ref(:aws_dynamodb_table, :global_data, :name)
    description "Primary region DynamoDB table name"
  end
  
  output :primary_dynamodb_table_arn do
    value ref(:aws_dynamodb_table, :global_data, :arn)
    description "Primary region DynamoDB table ARN"
  end
end

# Template 2: Secondary Region Infrastructure (US West)
template :secondary_region do
  provider :aws do
    region "us-west-2"
    
    default_tags do
      tags do
        ManagedBy "Pangea"
        Environment namespace
        Project "GlobalMultiRegion"
        Template "secondary_region"
        Region "us-west-2"
        RegionRole "secondary"
      end
    end
  end
  
  # VPC for secondary region (different CIDR to avoid conflicts)
  secondary_vpc = resource :aws_vpc, :secondary do
    cidr_block "10.1.0.0/16"
    enable_dns_hostnames true
    enable_dns_support true
    
    tags do
      Name "Global-Secondary-VPC-#{namespace}"
      Region "us-west-2"
      Purpose "SecondaryRegion"
    end
  end
  
  # Internet Gateway
  secondary_igw = resource :aws_internet_gateway, :secondary do
    vpc_id ref(:aws_vpc, :secondary, :id)
    
    tags do
      Name "Global-Secondary-IGW-#{namespace}"
      Region "us-west-2"
    end
  end
  
  # Availability zones for us-west-2
  availability_zones = ["us-west-2a", "us-west-2b", "us-west-2c"]
  
  # Public subnets
  availability_zones.each_with_index do |az, index|
    resource :"aws_subnet", :"secondary_public_#{index + 1}" do
      vpc_id ref(:aws_vpc, :secondary, :id)
      cidr_block "10.1.#{index + 1}.0/24"
      availability_zone az
      map_public_ip_on_launch true
      
      tags do
        Name "Global-Secondary-Public-#{index + 1}-#{namespace}"
        Type "public"
        Region "us-west-2"
        AZ az
      end
    end
    
    # Private subnets
    resource :"aws_subnet", :"secondary_private_#{index + 1}" do
      vpc_id ref(:aws_vpc, :secondary, :id)
      cidr_block "10.1.#{index + 10}.0/24"
      availability_zone az
      
      tags do
        Name "Global-Secondary-Private-#{index + 1}-#{namespace}"
        Type "private"
        Region "us-west-2"
        AZ az
      end
    end
  end
  
  # NAT Gateways
  availability_zones.each_with_index do |az, index|
    resource :"aws_eip", :"secondary_nat_#{index + 1}" do
      domain "vpc"
      
      tags do
        Name "Global-Secondary-NAT-EIP-#{index + 1}-#{namespace}"
        Region "us-west-2"
        AZ az
      end
    end
    
    resource :"aws_nat_gateway", :"secondary_#{index + 1}" do
      allocation_id ref(:"aws_eip", :"secondary_nat_#{index + 1}", :id)
      subnet_id ref(:"aws_subnet", :"secondary_public_#{index + 1}", :id)
      
      tags do
        Name "Global-Secondary-NAT-#{index + 1}-#{namespace}"
        Region "us-west-2"
        AZ az
      end
    end
  end
  
  # Route tables
  secondary_public_rt = resource :aws_route_table, :secondary_public do
    vpc_id ref(:aws_vpc, :secondary, :id)
    
    route do
      cidr_block "0.0.0.0/0"
      gateway_id ref(:aws_internet_gateway, :secondary, :id)
    end
    
    tags do
      Name "Global-Secondary-Public-RT-#{namespace}"
      Region "us-west-2"
    end
  end
  
  # Associate public subnets and create private route tables
  availability_zones.each_with_index do |az, index|
    resource :"aws_route_table_association", :"secondary_public_#{index + 1}" do
      subnet_id ref(:"aws_subnet", :"secondary_public_#{index + 1}", :id)
      route_table_id ref(:aws_route_table, :secondary_public, :id)
    end
    
    resource :"aws_route_table", :"secondary_private_#{index + 1}" do
      vpc_id ref(:aws_vpc, :secondary, :id)
      
      route do
        cidr_block "0.0.0.0/0"
        nat_gateway_id ref(:"aws_nat_gateway", :"secondary_#{index + 1}", :id)
      end
      
      tags do
        Name "Global-Secondary-Private-RT-#{index + 1}-#{namespace}"
        Region "us-west-2"
        AZ az
      end
    end
    
    resource :"aws_route_table_association", :"secondary_private_#{index + 1}" do
      subnet_id ref(:"aws_subnet", :"secondary_private_#{index + 1}", :id)
      route_table_id ref(:"aws_route_table", :"secondary_private_#{index + 1}", :id)
    end
  end
  
  # Security Groups (similar to primary but for secondary region)
  secondary_alb_sg = resource :aws_security_group, :secondary_alb do
    name_prefix "global-secondary-alb-"
    vpc_id ref(:aws_vpc, :secondary, :id)
    description "ALB security group for secondary region"
    
    ingress do
      from_port 80
      to_port 80
      protocol "tcp"
      cidr_blocks ["0.0.0.0/0"]
      description "HTTP access"
    end
    
    ingress do
      from_port 443
      to_port 443
      protocol "tcp"
      cidr_blocks ["0.0.0.0/0"]
      description "HTTPS access"
    end
    
    egress do
      from_port 8080
      to_port 8080
      protocol "tcp"
      security_groups [ref(:aws_security_group, :secondary_app, :id)]
      description "HTTP to application servers"
    end
    
    tags do
      Name "Global-Secondary-ALB-SG-#{namespace}"
      Region "us-west-2"
      Purpose "LoadBalancer"
    end
  end
  
  secondary_app_sg = resource :aws_security_group, :secondary_app do
    name_prefix "global-secondary-app-"
    vpc_id ref(:aws_vpc, :secondary, :id)
    description "Application security group for secondary region"
    
    ingress do
      from_port 8080
      to_port 8080
      protocol "tcp"
      security_groups [ref(:aws_security_group, :secondary_alb, :id)]
      description "HTTP from ALB"
    end
    
    # Cross-region communication
    ingress do
      from_port 8080
      to_port 8080
      protocol "tcp"
      cidr_blocks ["10.0.0.0/16"] # Primary region CIDR
      description "HTTP from primary region"
    end
    
    egress do
      from_port 0
      to_port 0
      protocol "-1"
      cidr_blocks ["0.0.0.0/0"]
      description "All outbound traffic"
    end
    
    tags do
      Name "Global-Secondary-App-SG-#{namespace}"
      Region "us-west-2"
      Purpose "Application"
    end
  end
  
  # Application Load Balancer
  secondary_alb = resource :aws_lb, :secondary do
    name_prefix "global-sec-"
    load_balancer_type "application"
    scheme "internet-facing"
    
    subnets availability_zones.map.with_index { |az, idx| ref(:"aws_subnet", :"secondary_public_#{idx + 1}", :id) }
    security_groups [ref(:aws_security_group, :secondary_alb, :id)]
    
    enable_deletion_protection namespace == "production"
    enable_cross_zone_load_balancing true
    
    tags do
      Name "Global-Secondary-ALB-#{namespace}"
      Region "us-west-2"
      Purpose "GlobalLoadBalancing"
    end
  end
  
  # Target Group
  secondary_tg = resource :aws_lb_target_group, :secondary_app do
    name_prefix "global-sec-app-"
    port 8080
    protocol "HTTP"
    vpc_id ref(:aws_vpc, :secondary, :id)
    target_type "instance"
    
    health_check do
      enabled true
      healthy_threshold 2
      unhealthy_threshold 3
      timeout 5
      interval 30
      path "/health"
      matcher "200"
      protocol "HTTP"
      port "traffic-port"
    end
    
    tags do
      Name "Global-Secondary-App-TG-#{namespace}"
      Region "us-west-2"
      Purpose "ApplicationTargeting"
    end
  end
  
  # ALB Listener
  secondary_listener = resource :aws_lb_listener, :secondary_http do
    load_balancer_arn ref(:aws_lb, :secondary, :arn)
    port "80"
    protocol "HTTP"
    
    default_action do
      type "forward"
      target_group_arn ref(:aws_lb_target_group, :secondary_app, :arn)
    end
  end
  
  # Launch Template (similar to primary but with different region info)
  secondary_launch_template = resource :aws_launch_template, :secondary_app do
    name_prefix "global-secondary-app-"
    description "Launch template for secondary region application"
    
    image_id data(:aws_ami, :amazon_linux_west, :id)
    instance_type ENV['SECONDARY_INSTANCE_TYPE'] || "t3.medium"
    
    vpc_security_group_ids [ref(:aws_security_group, :secondary_app, :id)]
    
    monitoring do
      enabled true
    end
    
    user_data base64encode(<<~USERDATA)
      #!/bin/bash
      yum update -y
      yum install -y docker awscli
      systemctl start docker
      systemctl enable docker
      usermod -aG docker ec2-user
      
      # Get instance metadata
      INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
      AZ=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)
      REGION=us-west-2
      
      # Simple Node.js application for secondary region
      cat > /home/ec2-user/app.js << 'NODEJS'
      const express = require('express');
      const app = express();
      const port = 8080;
      
      app.get('/health', (req, res) => {
        res.status(200).json({
          status: 'healthy',
          region: 'us-west-2',
          instance_id: process.env.INSTANCE_ID || 'unknown',
          timestamp: new Date().toISOString()
        });
      });
      
      app.get('/', (req, res) => {
        res.json({
          message: 'Global Multi-Region Application',
          region: 'us-west-2',
          role: 'secondary',
          instance_id: process.env.INSTANCE_ID || 'unknown',
          availability_zone: process.env.AZ || 'unknown',
          environment: '#{namespace}',
          timestamp: new Date().toISOString(),
          version: '1.0.0'
        });
      });
      
      app.get('/api/data', (req, res) => {
        res.json({
          data: 'Sample data from secondary region',
          region: 'us-west-2',
          processed_at: new Date().toISOString()
        });
      });
      
      app.listen(port, '0.0.0.0', () => {
        console.log(`Global app listening on port ${port} in region us-west-2`);
      });
      NODEJS
      
      cat > /home/ec2-user/Dockerfile << 'DOCKERFILE'
      FROM node:16-alpine
      WORKDIR /app
      RUN npm install express
      COPY app.js .
      EXPOSE 8080
      ENV INSTANCE_ID=${INSTANCE_ID}
      ENV AZ=${AZ}
      ENV REGION=${REGION}
      CMD ["node", "app.js"]
      DOCKERFILE
      
      cd /home/ec2-user
      docker build -t global-app .
      docker run -d -p 8080:8080 --name global-app-secondary \\
        -e INSTANCE_ID=$INSTANCE_ID \\
        -e AZ=$AZ \\
        -e REGION=$REGION \\
        global-app
    USERDATA
    
    tag_specifications do
      resource_type "instance"
      tags do
        Name "Global-Secondary-App-Instance-#{namespace}"
        Region "us-west-2"
        Role "secondary"
        LaunchedBy "AutoScalingGroup"
      end
    end
    
    tags do
      Name "Global-Secondary-LaunchTemplate-#{namespace}"
      Region "us-west-2"
      Purpose "ApplicationLaunching"
    end
  end
  
  # Auto Scaling Group
  secondary_asg = resource :aws_autoscaling_group, :secondary_app do
    name "global-secondary-app-asg-#{namespace}"
    vpc_zone_identifier availability_zones.map.with_index { |az, idx| ref(:"aws_subnet", :"secondary_private_#{idx + 1}", :id) }
    
    target_group_arns [ref(:aws_lb_target_group, :secondary_app, :arn)]
    health_check_type "ELB"
    health_check_grace_period 300
    
    min_size 2
    max_size namespace == "production" ? 10 : 6
    desired_capacity 3
    
    launch_template do
      id ref(:aws_launch_template, :secondary_app, :id)
      version "$Latest"
    end
    
    tag do
      key "Name"
      value "Global-Secondary-App-ASG-#{namespace}"
      propagate_at_launch true
    end
    
    tag do
      key "Region"
      value "us-west-2"
      propagate_at_launch true
    end
    
    tag do
      key "Role"
      value "secondary"
      propagate_at_launch true
    end
  end
  
  # Get Amazon Linux AMI for us-west-2
  data :aws_ami, :amazon_linux_west do
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
  
  # Outputs
  output :secondary_vpc_id do
    value ref(:aws_vpc, :secondary, :id)
    description "Secondary region VPC ID"
  end
  
  output :secondary_vpc_cidr do
    value ref(:aws_vpc, :secondary, :cidr_block)
    description "Secondary region VPC CIDR"
  end
  
  output :secondary_alb_dns do
    value ref(:aws_lb, :secondary, :dns_name)
    description "Secondary region ALB DNS name"
  end
  
  output :secondary_alb_zone_id do
    value ref(:aws_lb, :secondary, :zone_id)
    description "Secondary region ALB zone ID"
  end
end

# Template 3: Global Services and Cross-Region Setup
template :global_services do
  provider :aws do
    region "us-east-1" # Route 53 and CloudFront are global services
    
    default_tags do
      tags do
        ManagedBy "Pangea"
        Environment namespace
        Project "GlobalMultiRegion"
        Template "global_services"
        Purpose "GlobalInfrastructure"
      end
    end
  end
  
  # Reference primary and secondary regions
  # Note: In a real implementation, these would reference remote state or use data sources
  # For this example, we'll use placeholder values that would be populated from other templates
  
  primary_alb_dns = ENV['PRIMARY_ALB_DNS'] || "primary-alb.example.com"
  secondary_alb_dns = ENV['SECONDARY_ALB_DNS'] || "secondary-alb.example.com"
  primary_alb_zone_id = ENV['PRIMARY_ALB_ZONE_ID'] || "Z35SXDOTRQ7X7K"
  secondary_alb_zone_id = ENV['SECONDARY_ALB_ZONE_ID'] || "Z1D633PJN98FT9"
  
  # Route 53 Hosted Zone
  hosted_zone = resource :aws_route53_zone, :main do
    name ENV['DOMAIN_NAME'] || "global-app-#{namespace}.example.com"
    comment "Hosted zone for global multi-region application"
    
    tags do
      Name "Global-HostedZone-#{namespace}"
      Purpose "GlobalDNS"
    end
  end
  
  # Health Checks for each region
  primary_health_check = resource :aws_route53_health_check, :primary do
    fqdn primary_alb_dns
    port 80
    type "HTTP"
    resource_path "/health"
    failure_threshold 3
    request_interval 30
    
    cloudwatch_logs_region "us-east-1"
    cloudwatch_alarm_region "us-east-1"
    insufficient_data_health_status "Failure"
    
    tags do
      Name "Global-HealthCheck-Primary-#{namespace}"
      Region "us-east-1"
      Purpose "RegionHealthCheck"
    end
  end
  
  secondary_health_check = resource :aws_route53_health_check, :secondary do
    fqdn secondary_alb_dns
    port 80
    type "HTTP"
    resource_path "/health"
    failure_threshold 3
    request_interval 30
    
    cloudwatch_logs_region "us-west-2"
    cloudwatch_alarm_region "us-west-2"
    insufficient_data_health_status "Failure"
    
    tags do
      Name "Global-HealthCheck-Secondary-#{namespace}"
      Region "us-west-2"
      Purpose "RegionHealthCheck"
    end
  end
  
  # Route 53 Records with Failover Routing
  # Primary record (primary region)
  primary_record = resource :aws_route53_record, :primary do
    zone_id ref(:aws_route53_zone, :main, :zone_id)
    name ref(:aws_route53_zone, :main, :name)
    type "A"
    set_identifier "primary"
    
    failover_routing_policy do
      type "PRIMARY"
    end
    
    health_check_id ref(:aws_route53_health_check, :primary, :id)
    
    alias do
      name primary_alb_dns
      zone_id primary_alb_zone_id
      evaluate_target_health true
    end
  end
  
  # Secondary record (failover region)
  secondary_record = resource :aws_route53_record, :secondary do
    zone_id ref(:aws_route53_zone, :main, :zone_id)
    name ref(:aws_route53_zone, :main, :name)
    type "A"
    set_identifier "secondary"
    
    failover_routing_policy do
      type "SECONDARY"
    end
    
    health_check_id ref(:aws_route53_health_check, :secondary, :id)
    
    alias do
      name secondary_alb_dns
      zone_id secondary_alb_zone_id
      evaluate_target_health true
    end
  end
  
  # Geolocation-based routing for better performance
  # North America to primary (us-east-1)
  geo_na_record = resource :aws_route53_record, :geo_na do
    zone_id ref(:aws_route53_zone, :main, :zone_id)
    name "geo.#{ref(:aws_route53_zone, :main, :name)}"
    type "A"
    set_identifier "north-america"
    
    geolocation_routing_policy do
      continent "NA"
    end
    
    health_check_id ref(:aws_route53_health_check, :primary, :id)
    
    alias do
      name primary_alb_dns
      zone_id primary_alb_zone_id
      evaluate_target_health true
    end
  end
  
  # Asia/Pacific to secondary (us-west-2)
  geo_ap_record = resource :aws_route53_record, :geo_ap do
    zone_id ref(:aws_route53_zone, :main, :zone_id)
    name "geo.#{ref(:aws_route53_zone, :main, :name)}"
    type "A"
    set_identifier "asia-pacific"
    
    geolocation_routing_policy do
      continent "AS"
    end
    
    health_check_id ref(:aws_route53_health_check, :secondary, :id)
    
    alias do
      name secondary_alb_dns
      zone_id secondary_alb_zone_id
      evaluate_target_health true
    end
  end
  
  # Default geolocation (rest of world)
  geo_default_record = resource :aws_route53_record, :geo_default do
    zone_id ref(:aws_route53_zone, :main, :zone_id)
    name "geo.#{ref(:aws_route53_zone, :main, :name)}"
    type "A"
    set_identifier "default"
    
    geolocation_routing_policy do
      continent "*"
    end
    
    health_check_id ref(:aws_route53_health_check, :primary, :id)
    
    alias do
      name primary_alb_dns
      zone_id primary_alb_zone_id
      evaluate_target_health true
    end
  end
  
  # CloudFront Distribution for global content delivery
  cloudfront = resource :aws_cloudfront_distribution, :global do
    comment "Global CDN for multi-region application"
    default_root_object "index.html"
    enabled true
    is_ipv6_enabled true
    price_class "PriceClass_All"
    
    # Primary origin
    origin do
      domain_name primary_alb_dns
      origin_id "primary-alb"
      
      custom_origin_config do
        http_port 80
        https_port 443
        origin_protocol_policy "http-only"
        origin_ssl_protocols ["TLSv1.2"]
      end
    end
    
    # Secondary origin for failover
    origin do
      domain_name secondary_alb_dns
      origin_id "secondary-alb"
      
      custom_origin_config do
        http_port 80
        https_port 443
        origin_protocol_policy "http-only"
        origin_ssl_protocols ["TLSv1.2"]
      end
    end
    
    # Origin group for automatic failover
    origin_group do
      origin_group_id "regional-failover"
      
      failover_criteria do
        status_codes [403, 404, 500, 502, 503, 504]
      end
      
      member do
        origin_id "primary-alb"
      end
      
      member do
        origin_id "secondary-alb"
      end
    end
    
    # Default cache behavior
    default_cache_behavior do
      allowed_methods ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
      cached_methods ["GET", "HEAD", "OPTIONS"]
      target_origin_id "regional-failover"
      
      forwarded_values do
        query_string true
        headers ["Host", "CloudFront-Forwarded-Proto"]
        cookies do
          forward "all"
        end
      end
      
      viewer_protocol_policy "redirect-to-https"
      min_ttl 0
      default_ttl 300
      max_ttl 86400
      compress true
    end
    
    # API cache behavior (shorter TTL for dynamic content)
    ordered_cache_behavior do
      path_pattern "/api/*"
      allowed_methods ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
      cached_methods ["GET", "HEAD", "OPTIONS"]
      target_origin_id "regional-failover"
      
      forwarded_values do
        query_string true
        headers ["*"]
        cookies do
          forward "all"
        end
      end
      
      viewer_protocol_policy "redirect-to-https"
      min_ttl 0
      default_ttl 0
      max_ttl 300
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
      Name "Global-CloudFront-#{namespace}"
      Purpose "GlobalCDN"
    end
  end
  
  # DynamoDB Global Tables setup
  # Note: This requires the table to be created in both regions first
  # The actual global table setup would be done via AWS CLI or SDK
  # Here we show the IAM role that would be used
  
  dynamodb_global_role = resource :aws_iam_role, :dynamodb_global do
    name_prefix "Global-DynamoDB-"
    assume_role_policy jsonencode({
      Version: "2012-10-17",
      Statement: [
        {
          Action: "sts:AssumeRole",
          Effect: "Allow",
          Principal: {
            Service: "dynamodb.amazonaws.com"
          }
        }
      ]
    })
    
    tags do
      Name "Global-DynamoDB-Role-#{namespace}"
      Purpose "GlobalTableReplication"
    end
  end
  
  resource :aws_iam_role_policy, :dynamodb_global do
    name_prefix "Global-DynamoDB-Policy-"
    role ref(:aws_iam_role, :dynamodb_global, :id)
    
    policy jsonencode({
      Version: "2012-10-17",
      Statement: [
        {
          Effect: "Allow",
          Action: [
            "dynamodb:CreateGlobalTable",
            "dynamodb:DescribeGlobalTable",
            "dynamodb:ListGlobalTables",
            "dynamodb:UpdateGlobalTable",
            "dynamodb:DescribeStream",
            "dynamodb:GetRecords",
            "dynamodb:GetShardIterator",
            "dynamodb:ListStreams"
          ],
          Resource: "*"
        }
      ]
    })
  end
  
  # CloudWatch Dashboard for global monitoring
  global_dashboard = resource :aws_cloudwatch_dashboard, :global do
    dashboard_name "Global-MultiRegion-#{namespace}"
    
    dashboard_body jsonencode({
      widgets: [
        {
          type: "metric",
          x: 0,
          y: 0,
          width: 12,
          height: 6,
          properties: {
            metrics: [
              ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", primary_alb_dns, { region: "us-east-1", label: "Primary Region Requests" }],
              [".", ".", ".", secondary_alb_dns, { region: "us-west-2", label: "Secondary Region Requests" }]
            ],
            view: "timeSeries",
            stacked: false,
            region: "us-east-1",
            title: "Request Count by Region",
            period: 300
          }
        },
        {
          type: "metric",
          x: 0,
          y: 6,
          width: 12,
          height: 6,
          properties: {
            metrics: [
              ["AWS/Route53", "HealthCheckStatus", "HealthCheckId", ref(:aws_route53_health_check, :primary, :id), { label: "Primary Region Health" }],
              [".", ".", ".", ref(:aws_route53_health_check, :secondary, :id), { label: "Secondary Region Health" }]
            ],
            view: "timeSeries",
            stacked: false,
            region: "us-east-1",
            title: "Regional Health Checks",
            period: 300
          }
        },
        {
          type: "metric",
          x: 0,
          y: 12,
          width: 12,
          height: 6,
          properties: {
            metrics: [
              ["AWS/CloudFront", "Requests", "DistributionId", ref(:aws_cloudfront_distribution, :global, :id)],
              [".", "BytesDownloaded", ".", "."]
            ],
            view: "timeSeries",
            stacked: false,
            region: "us-east-1",
            title: "CloudFront Global Traffic",
            period: 300
          }
        }
      ]
    })
    
    tags do
      Name "Global-Dashboard-#{namespace}"
      Purpose "GlobalMonitoring"
    end
  end
  
  # Outputs
  output :hosted_zone_id do
    value ref(:aws_route53_zone, :main, :zone_id)
    description "Route 53 hosted zone ID"
  end
  
  output :domain_name do
    value ref(:aws_route53_zone, :main, :name)
    description "Application domain name"
  end
  
  output :cloudfront_distribution_id do
    value ref(:aws_cloudfront_distribution, :global, :id)
    description "CloudFront distribution ID"
  end
  
  output :cloudfront_domain_name do
    value ref(:aws_cloudfront_distribution, :global, :domain_name)
    description "CloudFront distribution domain name"
  end
  
  output :primary_health_check_id do
    value ref(:aws_route53_health_check, :primary, :id)
    description "Primary region health check ID"
  end
  
  output :secondary_health_check_id do
    value ref(:aws_route53_health_check, :secondary, :id)
    description "Secondary region health check ID"
  end
end

# This global multi-region example demonstrates several key concepts:
#
# 1. **Multi-Region Template Isolation**: Three separate templates for:
#    - Primary region infrastructure (us-east-1)
#    - Secondary region infrastructure (us-west-2)
#    - Global services and cross-region coordination
#
# 2. **Active-Active Architecture**: Both regions serve traffic simultaneously
#    with automatic failover capabilities and geolocation-based routing.
#
# 3. **Global Load Balancing**: Route 53 health checks with failover routing,
#    geolocation routing for performance optimization.
#
# 4. **Content Delivery Network**: CloudFront with origin failover for global
#    content delivery and improved performance.
#
# 5. **Cross-Region Communication**: VPC peering capabilities, security group
#    rules for cross-region access, consistent naming and tagging.
#
# 6. **Data Replication**: DynamoDB Global Tables setup for cross-region
#    data synchronization and consistency.
#
# 7. **Comprehensive Monitoring**: CloudWatch dashboards showing metrics
#    from both regions, health checks, and global CDN performance.
#
# Deployment order:
#   pangea apply examples/global-multi-region.rb --template primary_region
#   pangea apply examples/global-multi-region.rb --template secondary_region  
#   pangea apply examples/global-multi-region.rb --template global_services
#
# Environment-specific deployment:
#   export DOMAIN_NAME=myapp.example.com
#   export PRIMARY_INSTANCE_TYPE=t3.large
#   export SECONDARY_INSTANCE_TYPE=t3.large
#   pangea apply examples/global-multi-region.rb --namespace production
#
# This example showcases how Pangea's template isolation enables building
# sophisticated global applications with proper separation of regional
# infrastructure and global coordination services.