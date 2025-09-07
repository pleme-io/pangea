# Multi-Tier Architecture Infrastructure
#
# This example demonstrates Pangea's template isolation pattern with three separate
# templates that work together to create a complete application infrastructure.
# Each template has its own state file, enabling independent deployment and management.
#
# Templates:
# 1. networking - VPC, subnets, security groups, and network infrastructure
# 2. application - Web servers, load balancers, and application layer
# 3. database - RDS instances, backups, and data layer
#
# Cross-template communication is achieved through data sources and outputs.

# Template 1: Networking Infrastructure
# This template creates the foundational network resources
template :networking do
  provider :aws do
    region var(:aws_region, "us-east-1")
  end

  # Variables
  variable :environment do
    type "string"
    default "development"
    description "Environment name"
  end

  variable :aws_region do
    type "string"
    default "us-east-1"
    description "AWS region"
  end

  variable :vpc_cidr do
    type "string"
    default "10.0.0.0/16"
    description "CIDR block for VPC"
  end

  variable :availability_zones do
    type "list"
    default ["a", "b", "c"]
    description "List of availability zone suffixes"
  end

  # Local values
  locals do
    common_tags {
      Environment var(:environment)
      Project "multi-tier-app"
      ManagedBy "pangea"
      Template "networking"
    }
  end

  # VPC
  resource :aws_vpc, :main do
    cidr_block var(:vpc_cidr)
    enable_dns_hostnames true
    enable_dns_support true
    
    tags merge(local(:common_tags), {
      Name: "multi-tier-${var(:environment)}-vpc"
    })
  end

  # Internet Gateway
  resource :aws_internet_gateway, :main do
    vpc_id ref(:aws_vpc, :main, :id)
    
    tags merge(local(:common_tags), {
      Name: "multi-tier-${var(:environment)}-igw"
    })
  end

  # Public Subnets
  dynamic :aws_subnet do
    for_each var(:availability_zones)
    iterator "az"
    
    labels ["public", az.value]
    
    content do
      vpc_id ref(:aws_vpc, :main, :id)
      cidr_block "10.0.${1 + az.key}.0/24"
      availability_zone "${var(:aws_region)}${az.value}"
      map_public_ip_on_launch true
      
      tags merge(local(:common_tags), {
        Name: "multi-tier-${var(:environment)}-public-${az.value}",
        Type: "public",
        Tier: "public"
      })
    end
  end

  # Private App Subnets
  dynamic :aws_subnet do
    for_each var(:availability_zones)
    iterator "az"
    
    labels ["private_app", az.value]
    
    content do
      vpc_id ref(:aws_vpc, :main, :id)
      cidr_block "10.0.${10 + az.key}.0/24"
      availability_zone "${var(:aws_region)}${az.value}"
      
      tags merge(local(:common_tags), {
        Name: "multi-tier-${var(:environment)}-private-app-${az.value}",
        Type: "private",
        Tier: "application"
      })
    end
  end

  # Private Database Subnets
  dynamic :aws_subnet do
    for_each var(:availability_zones)
    iterator "az"
    
    labels ["private_db", az.value]
    
    content do
      vpc_id ref(:aws_vpc, :main, :id)
      cidr_block "10.0.${20 + az.key}.0/24"
      availability_zone "${var(:aws_region)}${az.value}"
      
      tags merge(local(:common_tags), {
        Name: "multi-tier-${var(:environment)}-private-db-${az.value}",
        Type: "private",
        Tier: "database"
      })
    end
  end

  # Elastic IPs for NAT Gateways
  dynamic :aws_eip do
    for_each var(:availability_zones)
    iterator "az"
    
    labels ["nat", az.value]
    
    content do
      domain "vpc"
      depends_on [ref(:aws_internet_gateway, :main)]
      
      tags merge(local(:common_tags), {
        Name: "multi-tier-${var(:environment)}-nat-eip-${az.value}"
      })
    end
  end

  # NAT Gateways
  dynamic :aws_nat_gateway do
    for_each var(:availability_zones)
    iterator "az"
    
    labels ["nat", az.value]
    
    content do
      allocation_id ref(:aws_eip, ["nat", az.value], :id)
      subnet_id ref(:aws_subnet, ["public", az.value], :id)
      depends_on [ref(:aws_internet_gateway, :main)]
      
      tags merge(local(:common_tags), {
        Name: "multi-tier-${var(:environment)}-nat-${az.value}"
      })
    end
  end

  # Route Tables
  resource :aws_route_table, :public do
    vpc_id ref(:aws_vpc, :main, :id)
    
    route do
      cidr_block "0.0.0.0/0"
      gateway_id ref(:aws_internet_gateway, :main, :id)
    end
    
    tags merge(local(:common_tags), {
      Name: "multi-tier-${var(:environment)}-public-rt"
    })
  end

  # Private Route Tables (one per AZ for high availability)
  dynamic :aws_route_table do
    for_each var(:availability_zones)
    iterator "az"
    
    labels ["private", az.value]
    
    content do
      vpc_id ref(:aws_vpc, :main, :id)
      
      route do
        cidr_block "0.0.0.0/0"
        nat_gateway_id ref(:aws_nat_gateway, ["nat", az.value], :id)
      end
      
      tags merge(local(:common_tags), {
        Name: "multi-tier-${var(:environment)}-private-rt-${az.value}"
      })
    end
  end

  # Route Table Associations - Public
  dynamic :aws_route_table_association do
    for_each var(:availability_zones)
    iterator "az"
    
    labels ["public", az.value]
    
    content do
      subnet_id ref(:aws_subnet, ["public", az.value], :id)
      route_table_id ref(:aws_route_table, :public, :id)
    end
  end

  # Route Table Associations - Private App
  dynamic :aws_route_table_association do
    for_each var(:availability_zones)
    iterator "az"
    
    labels ["private_app", az.value]
    
    content do
      subnet_id ref(:aws_subnet, ["private_app", az.value], :id)
      route_table_id ref(:aws_route_table, ["private", az.value], :id)
    end
  end

  # Route Table Associations - Private DB
  dynamic :aws_route_table_association do
    for_each var(:availability_zones)
    iterator "az"
    
    labels ["private_db", az.value]
    
    content do
      subnet_id ref(:aws_subnet, ["private_db", az.value], :id)
      route_table_id ref(:aws_route_table, ["private", az.value], :id)
    end
  end

  # Security Groups
  resource :aws_security_group, :alb do
    name_prefix "multi-tier-${var(:environment)}-alb-"
    description "Security group for Application Load Balancer"
    vpc_id ref(:aws_vpc, :main, :id)

    ingress do
      from_port 80
      to_port 80
      protocol "tcp"
      cidr_blocks ["0.0.0.0/0"]
      description "HTTP from anywhere"
    end

    ingress do
      from_port 443
      to_port 443
      protocol "tcp"
      cidr_blocks ["0.0.0.0/0"]
      description "HTTPS from anywhere"
    end

    egress do
      from_port 0
      to_port 0
      protocol "-1"
      cidr_blocks ["0.0.0.0/0"]
      description "Allow all outbound"
    end

    tags merge(local(:common_tags), {
      Name: "multi-tier-${var(:environment)}-alb-sg"
    })
  end

  resource :aws_security_group, :app do
    name_prefix "multi-tier-${var(:environment)}-app-"
    description "Security group for application servers"
    vpc_id ref(:aws_vpc, :main, :id)

    ingress do
      from_port 80
      to_port 80
      protocol "tcp"
      security_groups [ref(:aws_security_group, :alb, :id)]
      description "HTTP from ALB"
    end

    ingress do
      from_port 22
      to_port 22
      protocol "tcp"
      cidr_blocks [var(:vpc_cidr)]
      description "SSH from within VPC"
    end

    egress do
      from_port 0
      to_port 0
      protocol "-1"
      cidr_blocks ["0.0.0.0/0"]
      description "Allow all outbound"
    end

    tags merge(local(:common_tags), {
      Name: "multi-tier-${var(:environment)}-app-sg"
    })
  end

  resource :aws_security_group, :database do
    name_prefix "multi-tier-${var(:environment)}-db-"
    description "Security group for database"
    vpc_id ref(:aws_vpc, :main, :id)

    ingress do
      from_port 3306
      to_port 3306
      protocol "tcp"
      security_groups [ref(:aws_security_group, :app, :id)]
      description "MySQL from app servers"
    end

    tags merge(local(:common_tags), {
      Name: "multi-tier-${var(:environment)}-db-sg"
    })
  end

  # Outputs for other templates
  output :vpc_id do
    description "VPC ID"
    value ref(:aws_vpc, :main, :id)
  end

  output :vpc_cidr do
    description "VPC CIDR block"
    value ref(:aws_vpc, :main, :cidr_block)
  end

  output :public_subnet_ids do
    description "Public subnet IDs"
    value [for az in var(:availability_zones) : ref(:aws_subnet, ["public", az], :id)]
  end

  output :private_app_subnet_ids do
    description "Private application subnet IDs"
    value [for az in var(:availability_zones) : ref(:aws_subnet, ["private_app", az], :id)]
  end

  output :private_db_subnet_ids do
    description "Private database subnet IDs"
    value [for az in var(:availability_zones) : ref(:aws_subnet, ["private_db", az], :id)]
  end

  output :alb_security_group_id do
    description "ALB security group ID"
    value ref(:aws_security_group, :alb, :id)
  end

  output :app_security_group_id do
    description "Application security group ID"
    value ref(:aws_security_group, :app, :id)
  end

  output :database_security_group_id do
    description "Database security group ID"
    value ref(:aws_security_group, :database, :id)
  end
end

# Template 2: Application Infrastructure
# This template creates the application layer resources
template :application do
  provider :aws do
    region var(:aws_region, "us-east-1")
  end

  # Variables
  variable :environment do
    type "string"
    default "development"
  end

  variable :aws_region do
    type "string"
    default "us-east-1"
  end

  variable :instance_type do
    type "string"
    default "t3.small"
    description "EC2 instance type for app servers"
  end

  variable :min_size do
    type "number"
    default 2
    description "Minimum number of instances"
  end

  variable :max_size do
    type "number"
    default 10
    description "Maximum number of instances"
  end

  variable :desired_capacity do
    type "number"
    default 3
    description "Desired number of instances"
  end

  # Data sources to read from networking template outputs
  data :terraform_remote_state, :networking do
    backend "local"
    
    config do
      path "../.terraform/workspaces/${var(:environment)}/networking/terraform.tfstate"
    end
  end

  # Local values
  locals do
    common_tags {
      Environment var(:environment)
      Project "multi-tier-app"
      ManagedBy "pangea"
      Template "application"
    }
    
    # Reference networking outputs
    vpc_id data(:terraform_remote_state, :networking, :outputs, :vpc_id)
    public_subnet_ids data(:terraform_remote_state, :networking, :outputs, :public_subnet_ids)
    private_app_subnet_ids data(:terraform_remote_state, :networking, :outputs, :private_app_subnet_ids)
    alb_security_group_id data(:terraform_remote_state, :networking, :outputs, :alb_security_group_id)
    app_security_group_id data(:terraform_remote_state, :networking, :outputs, :app_security_group_id)
  end

  # Application Load Balancer
  resource :aws_lb, :app do
    name "multi-tier-${var(:environment)}-alb"
    load_balancer_type "application"
    subnets local(:public_subnet_ids)
    security_groups [local(:alb_security_group_id)]

    enable_deletion_protection false
    enable_http2 true
    enable_cross_zone_load_balancing true

    tags merge(local(:common_tags), {
      Name: "multi-tier-${var(:environment)}-alb"
    })
  end

  # Target Group
  resource :aws_lb_target_group, :app do
    name "multi-tier-${var(:environment)}-tg"
    port 80
    protocol "HTTP"
    vpc_id local(:vpc_id)
    target_type "instance"

    health_check do
      enabled true
      healthy_threshold 2
      unhealthy_threshold 3
      timeout 10
      interval 30
      path "/health"
      matcher "200"
    end

    stickiness do
      type "lb_cookie"
      enabled true
      cookie_duration 3600
    end

    deregistration_delay 30

    tags merge(local(:common_tags), {
      Name: "multi-tier-${var(:environment)}-tg"
    })
  end

  # ALB Listener
  resource :aws_lb_listener, :http do
    load_balancer_arn ref(:aws_lb, :app, :arn)
    port "80"
    protocol "HTTP"

    default_action do
      type "forward"
      target_group_arn ref(:aws_lb_target_group, :app, :arn)
    end
  end

  # Data source for database endpoint
  data :terraform_remote_state, :database do
    backend "local"
    
    config do
      path "../.terraform/workspaces/${var(:environment)}/database/terraform.tfstate"
    end
  end

  # Launch Template
  data :aws_ami, :app do
    most_recent true
    owners ["amazon"]
    
    filter do
      name "name"
      values ["amzn2-ami-hvm-*-x86_64-gp2"]
    end
  end

  resource :aws_launch_template, :app do
    name_prefix "multi-tier-${var(:environment)}-"
    description "Launch template for multi-tier app servers"

    image_id data(:aws_ami, :app, :id)
    instance_type var(:instance_type)
    
    vpc_security_group_ids [local(:app_security_group_id)]

    # IAM instance profile for CloudWatch metrics and SSM
    iam_instance_profile do
      name ref(:aws_iam_instance_profile, :app, :name)
    end

    user_data base64encode(<<-EOF
#!/bin/bash
yum update -y

# Install required packages
yum install -y httpd mysql jq amazon-cloudwatch-agent amazon-ssm-agent

# Configure Apache
systemctl start httpd
systemctl enable httpd

# Create health check endpoint
echo "OK" > /var/www/html/health

# Get database endpoint from metadata
DB_ENDPOINT="${try(data(:terraform_remote_state, :database, :outputs, :db_endpoint), "localhost")}"

# Create application page
cat <<'HTML' > /var/www/html/index.html
<!DOCTYPE html>
<html>
<head>
    <title>Multi-Tier Application</title>
    <style>
        body { font-family: Arial, sans-serif; max-width: 1200px; margin: 0 auto; padding: 20px; }
        .container { display: flex; gap: 20px; }
        .tier { flex: 1; background: #f5f5f5; padding: 20px; border-radius: 8px; }
        .tier h2 { color: #333; margin-top: 0; }
        .info { margin: 10px 0; }
        .status { color: green; font-weight: bold; }
        .error { color: red; font-weight: bold; }
    </style>
</head>
<body>
    <h1>Multi-Tier Application - ${var(:environment)}</h1>
    <div class="container">
        <div class="tier">
            <h2>Presentation Tier</h2>
            <div class="info">Load Balancer: <span class="status">Active</span></div>
            <div class="info">Instance ID: <span id="instance-id"></span></div>
            <div class="info">Availability Zone: <span id="az"></span></div>
        </div>
        <div class="tier">
            <h2>Application Tier</h2>
            <div class="info">Server Status: <span class="status">Running</span></div>
            <div class="info">Instance Type: ${var(:instance_type)}</div>
            <div class="info">Region: ${var(:aws_region)}</div>
        </div>
        <div class="tier">
            <h2>Database Tier</h2>
            <div class="info">Database Endpoint: <span>${DB_ENDPOINT}</span></div>
            <div class="info">Connection Status: <span id="db-status">Checking...</span></div>
        </div>
    </div>
    <script>
        // Get instance metadata
        fetch('http://169.254.169.254/latest/meta-data/instance-id')
            .then(r => r.text())
            .then(data => document.getElementById('instance-id').textContent = data);
        
        fetch('http://169.254.169.254/latest/meta-data/placement/availability-zone')
            .then(r => r.text())
            .then(data => document.getElementById('az').textContent = data);
            
        // Check database connectivity (in real app, this would be server-side)
        document.getElementById('db-status').innerHTML = 
            '${DB_ENDPOINT}' ? '<span class="status">Configured</span>' : '<span class="error">Not configured</span>';
    </script>
</body>
</html>
HTML

# Configure CloudWatch agent
cat <<'CONFIG' > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
{
  "metrics": {
    "namespace": "MultiTierApp/${var(:environment)}",
    "metrics_collected": {
      "cpu": {
        "measurement": [
          "cpu_usage_idle",
          "cpu_usage_active"
        ],
        "metrics_collection_interval": 60
      },
      "disk": {
        "measurement": [
          "used_percent"
        ],
        "metrics_collection_interval": 60,
        "resources": [
          "*"
        ]
      },
      "mem": {
        "measurement": [
          "mem_used_percent"
        ],
        "metrics_collection_interval": 60
      }
    }
  },
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/httpd/access_log",
            "log_group_name": "/aws/multi-tier/${var(:environment)}/apache/access",
            "log_stream_name": "{instance_id}"
          },
          {
            "file_path": "/var/log/httpd/error_log",
            "log_group_name": "/aws/multi-tier/${var(:environment)}/apache/error",
            "log_stream_name": "{instance_id}"
          }
        ]
      }
    }
  }
}
CONFIG

# Start CloudWatch agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
    -a fetch-config \
    -m ec2 \
    -s \
    -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json

# Enable SSM agent
systemctl enable amazon-ssm-agent
systemctl start amazon-ssm-agent
EOF
    )

    monitoring do
      enabled true
    end

    tag_specifications do
      resource_type "instance"
      tags merge(local(:common_tags), {
        Name: "multi-tier-${var(:environment)}-app-server"
      })
    end

    tag_specifications do
      resource_type "volume"
      tags merge(local(:common_tags), {
        Name: "multi-tier-${var(:environment)}-app-volume"
      })
    end
  end

  # IAM Role for EC2 instances
  resource :aws_iam_role, :app do
    name "multi-tier-${var(:environment)}-app-role"
    
    assume_role_policy jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action = "sts:AssumeRole"
          Effect = "Allow"
          Principal = {
            Service = "ec2.amazonaws.com"
          }
        }
      ]
    })

    tags merge(local(:common_tags), {
      Name: "multi-tier-${var(:environment)}-app-role"
    })
  end

  # Attach managed policies
  resource :aws_iam_role_policy_attachment, :cloudwatch do
    role ref(:aws_iam_role, :app, :name)
    policy_arn "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  end

  resource :aws_iam_role_policy_attachment, :ssm do
    role ref(:aws_iam_role, :app, :name)
    policy_arn "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  end

  # IAM Instance Profile
  resource :aws_iam_instance_profile, :app do
    name "multi-tier-${var(:environment)}-app-profile"
    role ref(:aws_iam_role, :app, :name)
    
    tags merge(local(:common_tags), {
      Name: "multi-tier-${var(:environment)}-app-profile"
    })
  end

  # Auto Scaling Group
  resource :aws_autoscaling_group, :app do
    name "multi-tier-${var(:environment)}-asg"
    vpc_zone_identifier local(:private_app_subnet_ids)
    
    target_group_arns [ref(:aws_lb_target_group, :app, :arn)]
    health_check_type "ELB"
    health_check_grace_period 300
    
    min_size var(:min_size)
    max_size var(:max_size)
    desired_capacity var(:desired_capacity)

    launch_template do
      id ref(:aws_launch_template, :app, :id)
      version "$Latest"
    end

    enabled_metrics [
      "GroupMinSize",
      "GroupMaxSize",
      "GroupDesiredCapacity",
      "GroupInServiceInstances",
      "GroupTotalInstances"
    ]

    tag do
      key "Name"
      value "multi-tier-${var(:environment)}-asg"
      propagate_at_launch false
    end

    dynamic :tag do
      for_each local(:common_tags)
      
      content do
        key tag.key
        value tag.value
        propagate_at_launch true
      end
    end
  end

  # Auto Scaling Policies
  resource :aws_autoscaling_policy, :scale_up do
    name "multi-tier-${var(:environment)}-scale-up"
    autoscaling_group_name ref(:aws_autoscaling_group, :app, :name)
    policy_type "TargetTrackingScaling"

    target_tracking_configuration do
      predefined_metric_specification do
        predefined_metric_type "ASGAverageCPUUtilization"
      end
      target_value 70.0
    end
  end

  # CloudWatch Log Groups
  resource :aws_cloudwatch_log_group, :access_logs do
    name "/aws/multi-tier/${var(:environment)}/apache/access"
    retention_in_days 7

    tags merge(local(:common_tags), {
      Name: "multi-tier-${var(:environment)}-access-logs"
    })
  end

  resource :aws_cloudwatch_log_group, :error_logs do
    name "/aws/multi-tier/${var(:environment)}/apache/error"
    retention_in_days 30

    tags merge(local(:common_tags), {
      Name: "multi-tier-${var(:environment)}-error-logs"
    })
  end

  # Outputs
  output :alb_dns_name do
    description "Application Load Balancer DNS name"
    value ref(:aws_lb, :app, :dns_name)
  end

  output :alb_url do
    description "Application URL"
    value "http://${ref(:aws_lb, :app, :dns_name)}"
  end

  output :asg_name do
    description "Auto Scaling Group name"
    value ref(:aws_autoscaling_group, :app, :name)
  end

  output :target_group_arn do
    description "Target Group ARN"
    value ref(:aws_lb_target_group, :app, :arn)
  end
end

# Template 3: Database Infrastructure
# This template creates the database layer resources
template :database do
  provider :aws do
    region var(:aws_region, "us-east-1")
  end

  # Variables
  variable :environment do
    type "string"
    default "development"
  end

  variable :aws_region do
    type "string"
    default "us-east-1"
  end

  variable :db_instance_class do
    type "string"
    default "db.t3.micro"
    description "RDS instance class"
  end

  variable :db_allocated_storage do
    type "number"
    default 20
    description "Allocated storage in GB"
  end

  variable :db_name do
    type "string"
    default "appdatabase"
    description "Database name"
  end

  variable :db_username do
    type "string"
    default "admin"
    description "Database master username"
  end

  variable :backup_retention_period do
    type "number"
    default 7
    description "Backup retention period in days"
  end

  variable :multi_az do
    type "bool"
    default false
    description "Enable Multi-AZ deployment"
  end

  # Data sources to read from networking template
  data :terraform_remote_state, :networking do
    backend "local"
    
    config do
      path "../.terraform/workspaces/${var(:environment)}/networking/terraform.tfstate"
    end
  end

  # Local values
  locals do
    common_tags {
      Environment var(:environment)
      Project "multi-tier-app"
      ManagedBy "pangea"
      Template "database"
    }
    
    vpc_id data(:terraform_remote_state, :networking, :outputs, :vpc_id)
    private_db_subnet_ids data(:terraform_remote_state, :networking, :outputs, :private_db_subnet_ids)
    database_security_group_id data(:terraform_remote_state, :networking, :outputs, :database_security_group_id)
  end

  # Random password for database
  resource :random_password, :db do
    length 16
    special true
    override_special "!#$%&*()-_=+[]{}<>:?"
  end

  # Store password in SSM Parameter Store
  resource :aws_ssm_parameter, :db_password do
    name "/${var(:environment)}/multi-tier/database/password"
    description "Database password for multi-tier app"
    type "SecureString"
    value ref(:random_password, :db, :result)

    tags merge(local(:common_tags), {
      Name: "multi-tier-${var(:environment)}-db-password"
    })
  end

  # Database Subnet Group
  resource :aws_db_subnet_group, :main do
    name "multi-tier-${var(:environment)}-db-subnet-group"
    description "Database subnet group for multi-tier app"
    subnet_ids local(:private_db_subnet_ids)

    tags merge(local(:common_tags), {
      Name: "multi-tier-${var(:environment)}-db-subnet-group"
    })
  end

  # RDS MySQL Instance
  resource :aws_db_instance, :main do
    identifier "multi-tier-${var(:environment)}-db"
    
    engine "mysql"
    engine_version "8.0"
    instance_class var(:db_instance_class)
    
    allocated_storage var(:db_allocated_storage)
    max_allocated_storage var(:db_allocated_storage) * 2
    storage_encrypted true
    storage_type "gp3"

    db_name var(:db_name)
    username var(:db_username)
    password ref(:random_password, :db, :result)
    
    vpc_security_group_ids [local(:database_security_group_id)]
    db_subnet_group_name ref(:aws_db_subnet_group, :main, :name)
    
    backup_retention_period var(:backup_retention_period)
    backup_window "03:00-04:00"
    maintenance_window "sun:04:00-sun:05:00"
    
    multi_az var(:multi_az)
    
    enabled_cloudwatch_logs_exports ["error", "general", "slowquery"]
    
    deletion_protection var(:environment) == "production" ? true : false
    skip_final_snapshot var(:environment) == "production" ? false : true
    final_snapshot_identifier var(:environment) == "production" ? "multi-tier-${var(:environment)}-final-snapshot-${timestamp()}" : null
    
    tags merge(local(:common_tags), {
      Name: "multi-tier-${var(:environment)}-database"
    })
  end

  # CloudWatch Log Groups for RDS logs
  resource :aws_cloudwatch_log_group, :rds_error do
    name "/aws/rds/instance/multi-tier-${var(:environment)}-db/error"
    retention_in_days 30

    tags merge(local(:common_tags), {
      Name: "multi-tier-${var(:environment)}-rds-error-logs"
    })
  end

  resource :aws_cloudwatch_log_group, :rds_general do
    name "/aws/rds/instance/multi-tier-${var(:environment)}-db/general"
    retention_in_days 7

    tags merge(local(:common_tags), {
      Name: "multi-tier-${var(:environment)}-rds-general-logs"
    })
  end

  resource :aws_cloudwatch_log_group, :rds_slowquery do
    name "/aws/rds/instance/multi-tier-${var(:environment)}-db/slowquery"
    retention_in_days 7

    tags merge(local(:common_tags), {
      Name: "multi-tier-${var(:environment)}-rds-slowquery-logs"
    })
  end

  # CloudWatch Alarms
  resource :aws_cloudwatch_metric_alarm, :db_cpu_high do
    alarm_name "multi-tier-${var(:environment)}-db-cpu-high"
    alarm_description "RDS instance CPU utilization is too high"
    comparison_operator "GreaterThanThreshold"
    evaluation_periods "2"
    metric_name "CPUUtilization"
    namespace "AWS/RDS"
    period "300"
    statistic "Average"
    threshold "80"

    dimensions do
      DBInstanceIdentifier ref(:aws_db_instance, :main, :id)
    end

    tags merge(local(:common_tags), {
      Name: "multi-tier-${var(:environment)}-db-cpu-alarm"
    })
  end

  resource :aws_cloudwatch_metric_alarm, :db_storage_low do
    alarm_name "multi-tier-${var(:environment)}-db-storage-low"
    alarm_description "RDS instance free storage space is low"
    comparison_operator "LessThanThreshold"
    evaluation_periods "1"
    metric_name "FreeStorageSpace"
    namespace "AWS/RDS"
    period "300"
    statistic "Average"
    threshold 1073741824  # 1GB in bytes

    dimensions do
      DBInstanceIdentifier ref(:aws_db_instance, :main, :id)
    end

    tags merge(local(:common_tags), {
      Name: "multi-tier-${var(:environment)}-db-storage-alarm"
    })
  end

  # Outputs
  output :db_endpoint do
    description "RDS instance endpoint"
    value ref(:aws_db_instance, :main, :endpoint)
    sensitive true
  end

  output :db_port do
    description "RDS instance port"
    value ref(:aws_db_instance, :main, :port)
  end

  output :db_name do
    description "Database name"
    value ref(:aws_db_instance, :main, :db_name)
  end

  output :db_username do
    description "Database username"
    value ref(:aws_db_instance, :main, :username)
    sensitive true
  end

  output :db_password_ssm_parameter do
    description "SSM parameter name for database password"
    value ref(:aws_ssm_parameter, :db_password, :name)
  end

  output :db_instance_id do
    description "RDS instance ID"
    value ref(:aws_db_instance, :main, :id)
  end
end