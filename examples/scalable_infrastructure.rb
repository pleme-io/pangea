# Scalable Infrastructure Example
# Demonstrates Pangea's template-based isolation and incremental deployment patterns

# Foundation template - networking and security
template :foundation do
  provider :aws do
    region "us-east-1"
    
    default_tags do
      tags do
        ManagedBy "Pangea"
        Environment "development"
        Project "MyApp"
      end
    end
  end
  
  # VPC and networking
  resource :aws_vpc, :main do
    cidr_block "10.0.0.0/16"
    enable_dns_hostnames true
    enable_dns_support true
    
    tags do
      Name "main-vpc"
    end
  end
  
  resource :aws_subnet, :public_a do
    vpc_id ref(:aws_vpc, :main, :id)
    cidr_block "10.0.1.0/24"
    availability_zone "us-east-1a"
    map_public_ip_on_launch true
    
    tags do
      Name "public-subnet-a"
      Type "public"
    end
  end
  
  resource :aws_subnet, :public_b do
    vpc_id ref(:aws_vpc, :main, :id)
    cidr_block "10.0.2.0/24"
    availability_zone "us-east-1b"
    map_public_ip_on_launch true
    
    tags do
      Name "public-subnet-b"
      Type "public"
    end
  end
  
  resource :aws_subnet, :private_a do
    vpc_id ref(:aws_vpc, :main, :id)
    cidr_block "10.0.10.0/24"
    availability_zone "us-east-1a"
    
    tags do
      Name "private-subnet-a"
      Type "private"
    end
  end
  
  resource :aws_subnet, :private_b do
    vpc_id ref(:aws_vpc, :main, :id)
    cidr_block "10.0.20.0/24"
    availability_zone "us-east-1b"
    
    tags do
      Name "private-subnet-b" 
      Type "private"
    end
  end
  
  # Internet Gateway
  resource :aws_internet_gateway, :main do
    vpc_id ref(:aws_vpc, :main, :id)
    
    tags do
      Name "main-igw"
    end
  end
  
  # Route tables
  resource :aws_route_table, :public do
    vpc_id ref(:aws_vpc, :main, :id)
    
    route do
      cidr_block "0.0.0.0/0"
      gateway_id ref(:aws_internet_gateway, :main, :id)
    end
    
    tags do
      Name "public-rt"
    end
  end
  
  # Outputs for other templates to reference
  output :vpc_id do
    value ref(:aws_vpc, :main, :id)
    description "VPC ID for use by other templates"
  end
  
  output :public_subnet_ids do
    value [
      ref(:aws_subnet, :public_a, :id),
      ref(:aws_subnet, :public_b, :id)
    ]
    description "Public subnet IDs"
  end
  
  output :private_subnet_ids do
    value [
      ref(:aws_subnet, :private_a, :id), 
      ref(:aws_subnet, :private_b, :id)
    ]
    description "Private subnet IDs"
  end
end

# Application template - web servers and load balancing
template :web_application do
  provider :aws do
    region "us-east-1"
  end
  
  # Data source to reference foundation outputs
  data :terraform_remote_state, :foundation do
    backend "s3"
    config do
      bucket "terraform-state-dev"
      key    "pangea/development/foundation/terraform.tfstate"
      region "us-east-1"
    end
  end
  
  # Security groups
  resource :aws_security_group, :web do
    name_prefix "web-sg"
    vpc_id data(:terraform_remote_state, :foundation, :outputs, :vpc_id)
    
    ingress do
      from_port 80
      to_port 80
      protocol "tcp"
      cidr_blocks ["0.0.0.0/0"]
    end
    
    ingress do
      from_port 443
      to_port 443
      protocol "tcp"
      cidr_blocks ["0.0.0.0/0"]
    end
    
    egress do
      from_port 0
      to_port 0
      protocol "-1"
      cidr_blocks ["0.0.0.0/0"]
    end
    
    tags do
      Name "web-security-group"
    end
  end
  
  # Application Load Balancer
  resource :aws_lb, :main do
    name "main-alb"
    load_balancer_type "application"
    subnets data(:terraform_remote_state, :foundation, :outputs, :public_subnet_ids)
    security_groups [ref(:aws_security_group, :web, :id)]
    
    tags do
      Name "main-alb"
    end
  end
  
  # Launch template for web servers
  resource :aws_launch_template, :web do
    name_prefix "web-server"
    image_id "ami-0c55b159cbfafe1f0"
    instance_type "t3.micro"
    vpc_security_group_ids [ref(:aws_security_group, :web, :id)]
    
    user_data base64encode(<<~USERDATA)
      #!/bin/bash
      yum update -y
      yum install -y httpd
      systemctl start httpd
      systemctl enable httpd
      echo "<h1>Hello from Pangea Web Server!</h1>" > /var/www/html/index.html
    USERDATA
    
    tag_specifications do
      resource_type "instance"
      tags do
        Name "web-server"
        Type "application"
      end
    end
  end
  
  # Auto Scaling Group
  resource :aws_autoscaling_group, :web do
    name "web-asg"
    vpc_zone_identifier data(:terraform_remote_state, :foundation, :outputs, :private_subnet_ids)
    target_group_arns [ref(:aws_lb_target_group, :web, :arn)]
    health_check_type "ELB"
    health_check_grace_period 300
    
    min_size 2
    max_size 10
    desired_capacity 3
    
    launch_template do
      id ref(:aws_launch_template, :web, :id)
      version "$Latest"
    end
    
    tag do
      key "Name"
      value "web-asg"
      propagate_at_launch true
    end
  end
  
  # Target group
  resource :aws_lb_target_group, :web do
    name "web-tg"
    port 80
    protocol "HTTP"
    vpc_id data(:terraform_remote_state, :foundation, :outputs, :vpc_id)
    
    health_check do
      enabled true
      healthy_threshold 2
      unhealthy_threshold 2
      timeout 5
      interval 30
      path "/"
      matcher "200"
    end
    
    tags do
      Name "web-target-group"
    end
  end
  
  # ALB Listener
  resource :aws_lb_listener, :web do
    load_balancer_arn ref(:aws_lb, :main, :arn)
    port "80"
    protocol "HTTP"
    
    default_action do
      type "forward"
      target_group_arn ref(:aws_lb_target_group, :web, :arn)
    end
  end
  
  output :load_balancer_dns do
    value ref(:aws_lb, :main, :dns_name)
    description "Load balancer DNS name"
  end
end

# Database template - isolated data layer
template :database do
  provider :aws do
    region "us-east-1"
  end
  
  # Reference foundation outputs
  data :terraform_remote_state, :foundation do
    backend "s3"
    config do
      bucket "terraform-state-dev"
      key    "pangea/development/foundation/terraform.tfstate"
      region "us-east-1"
    end
  end
  
  # Database subnet group
  resource :aws_db_subnet_group, :main do
    name "main-db-subnet-group"
    subnet_ids data(:terraform_remote_state, :foundation, :outputs, :private_subnet_ids)
    
    tags do
      Name "main-db-subnet-group"
    end
  end
  
  # Database security group
  resource :aws_security_group, :database do
    name_prefix "db-sg"
    vpc_id data(:terraform_remote_state, :foundation, :outputs, :vpc_id)
    
    ingress do
      from_port 5432
      to_port 5432
      protocol "tcp"
      cidr_blocks ["10.0.0.0/16"]  # Only from VPC
      description "PostgreSQL from VPC"
    end
    
    tags do
      Name "database-security-group"
    end
  end
  
  # RDS instance
  resource :aws_db_instance, :main do
    identifier "main-database"
    engine "postgres"
    engine_version "15.3"
    instance_class "db.t3.micro"
    allocated_storage 20
    storage_type "gp2"
    storage_encrypted true
    
    db_name "myapp"
    username "admin"
    manage_master_user_password true
    
    vpc_security_group_ids [ref(:aws_security_group, :database, :id)]
    db_subnet_group_name ref(:aws_db_subnet_group, :main, :name)
    
    backup_retention_period 7
    backup_window "03:00-04:00"
    maintenance_window "sun:04:00-sun:05:00"
    
    skip_final_snapshot true
    deletion_protection false
    
    tags do
      Name "main-database"
      Type "database"
    end
  end
  
  output :database_endpoint do
    value ref(:aws_db_instance, :main, :endpoint)
    description "Database endpoint for application configuration"
  end
  
  output :database_port do
    value ref(:aws_db_instance, :main, :port)
    description "Database port"
  end
end

# Monitoring template - observability stack
template :monitoring do
  provider :aws do
    region "us-east-1"
  end
  
  # CloudWatch log groups
  resource :aws_cloudwatch_log_group, :application do
    name "/aws/application/myapp"
    retention_in_days 30
    
    tags do
      Name "application-logs"
      Type "monitoring"
    end
  end
  
  # CloudWatch dashboard
  resource :aws_cloudwatch_dashboard, :main do
    dashboard_name "MyApp-Dashboard"
    
    dashboard_body jsonencode({
      widgets: [
        {
          type: "metric",
          properties: {
            metrics: [
              ["AWS/ApplicationELB", "RequestCount"],
              ["AWS/ApplicationELB", "TargetResponseTime"]
            ],
            period: 300,
            stat: "Average",
            region: "us-east-1",
            title: "Application Metrics"
          }
        }
      ]
    })
  end
  
  # SNS topic for alerts
  resource :aws_sns_topic, :alerts do
    name "myapp-alerts"
    
    tags do
      Name "application-alerts"
      Type "monitoring"
    end
  end
  
  output :log_group_name do
    value ref(:aws_cloudwatch_log_group, :application, :name)
    description "CloudWatch log group for application logs"
  end
end