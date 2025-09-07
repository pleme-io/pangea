# Example 10: Disaster Recovery Architecture
#
# This example demonstrates a comprehensive disaster recovery (DR) infrastructure
# using Pangea's template-level isolation and cross-region capabilities.
#
# Key Patterns Demonstrated:
# 1. Primary-Secondary Region Pattern: Active-passive DR setup
# 2. Automated Failover: Route 53 health checks and DNS failover
# 3. Data Replication: Cross-region RDS snapshots and S3 replication
# 4. Infrastructure Replication: Identical infrastructure in both regions
# 5. Backup and Recovery: Automated backup strategies across services
# 6. Monitoring and Alerting: CloudWatch alarms for DR events
# 7. Recovery Testing: Lambda functions for DR testing automation
#
# Templates:
# - primary_region: Production infrastructure in primary region
# - disaster_recovery_region: Standby infrastructure in DR region  
# - backup_and_monitoring: Cross-region backup coordination and monitoring
#
# Usage:
#   # Deploy primary region first
#   pangea apply disaster-recovery-architecture.rb --template primary_region
#   
#   # Deploy DR region
#   pangea apply disaster-recovery-architecture.rb --template disaster_recovery_region
#   
#   # Deploy backup and monitoring
#   pangea apply disaster-recovery-architecture.rb --template backup_and_monitoring
#
# Recovery Process:
#   1. Manual failover: Update Route 53 records to point to DR region
#   2. Restore RDS from latest snapshot in DR region
#   3. Update application configuration to use DR resources
#   4. Scale up DR infrastructure to handle production load
#
# Testing:
#   # Test DR failover (non-destructive)
#   pangea apply disaster-recovery-architecture.rb --template backup_and_monitoring
#   # Then invoke the DR test Lambda function via AWS console/CLI

# Primary Region Template - Production Infrastructure
template :primary_region do
  provider :aws do
    region "us-east-1"
    alias "primary"
  end

  # Primary Region VPC with full networking
  resource :aws_vpc, :primary_vpc do
    cidr_block "10.0.0.0/16"
    enable_dns_hostnames true
    enable_dns_support true
    
    tags do
      Name "primary-vpc"
      Environment "production"
      Region "primary"
      DisasterRecovery "source"
    end
  end

  # Internet Gateway for primary region
  resource :aws_internet_gateway, :primary_igw do
    vpc_id ref(:aws_vpc, :primary_vpc, :id)
    
    tags do
      Name "primary-igw"
      Environment "production"
    end
  end

  # Public subnets in multiple AZs for high availability
  resource :aws_subnet, :primary_public_1a do
    vpc_id ref(:aws_vpc, :primary_vpc, :id)
    cidr_block "10.0.1.0/24"
    availability_zone "us-east-1a"
    map_public_ip_on_launch true
    
    tags do
      Name "primary-public-1a"
      Type "public"
      Environment "production"
    end
  end

  resource :aws_subnet, :primary_public_1b do
    vpc_id ref(:aws_vpc, :primary_vpc, :id)
    cidr_block "10.0.2.0/24"
    availability_zone "us-east-1b" 
    map_public_ip_on_launch true
    
    tags do
      Name "primary-public-1b"
      Type "public"
      Environment "production"
    end
  end

  # Private subnets for application and database tiers
  resource :aws_subnet, :primary_private_1a do
    vpc_id ref(:aws_vpc, :primary_vpc, :id)
    cidr_block "10.0.10.0/24"
    availability_zone "us-east-1a"
    
    tags do
      Name "primary-private-1a"
      Type "private"
      Environment "production"
    end
  end

  resource :aws_subnet, :primary_private_1b do
    vpc_id ref(:aws_vpc, :primary_vpc, :id)
    cidr_block "10.0.11.0/24"
    availability_zone "us-east-1b"
    
    tags do
      Name "primary-private-1b" 
      Type "private"
      Environment "production"
    end
  end

  # Database subnets in separate AZs
  resource :aws_subnet, :primary_db_1a do
    vpc_id ref(:aws_vpc, :primary_vpc, :id)
    cidr_block "10.0.20.0/24"
    availability_zone "us-east-1a"
    
    tags do
      Name "primary-db-1a"
      Type "database"
      Environment "production"
    end
  end

  resource :aws_subnet, :primary_db_1b do
    vpc_id ref(:aws_vpc, :primary_vpc, :id)
    cidr_block "10.0.21.0/24"
    availability_zone "us-east-1b"
    
    tags do
      Name "primary-db-1b"
      Type "database" 
      Environment "production"
    end
  end

  # Route table for public subnets
  resource :aws_route_table, :primary_public_rt do
    vpc_id ref(:aws_vpc, :primary_vpc, :id)
    
    route do
      cidr_block "0.0.0.0/0"
      gateway_id ref(:aws_internet_gateway, :primary_igw, :id)
    end
    
    tags do
      Name "primary-public-rt"
      Environment "production"
    end
  end

  # Associate public subnets with route table
  resource :aws_route_table_association, :primary_public_1a_rt_assoc do
    subnet_id ref(:aws_subnet, :primary_public_1a, :id)
    route_table_id ref(:aws_route_table, :primary_public_rt, :id)
  end

  resource :aws_route_table_association, :primary_public_1b_rt_assoc do
    subnet_id ref(:aws_subnet, :primary_public_1b, :id)
    route_table_id ref(:aws_route_table, :primary_public_rt, :id)
  end

  # NAT Gateway for private subnet internet access
  resource :aws_eip, :primary_nat_eip do
    domain "vpc"
    depends_on [ref(:aws_internet_gateway, :primary_igw)]
    
    tags do
      Name "primary-nat-eip"
      Environment "production"
    end
  end

  resource :aws_nat_gateway, :primary_nat_gw do
    allocation_id ref(:aws_eip, :primary_nat_eip, :id)
    subnet_id ref(:aws_subnet, :primary_public_1a, :id)
    depends_on [ref(:aws_internet_gateway, :primary_igw)]
    
    tags do
      Name "primary-nat-gw"
      Environment "production"
    end
  end

  # Route table for private subnets
  resource :aws_route_table, :primary_private_rt do
    vpc_id ref(:aws_vpc, :primary_vpc, :id)
    
    route do
      cidr_block "0.0.0.0/0"
      nat_gateway_id ref(:aws_nat_gateway, :primary_nat_gw, :id)
    end
    
    tags do
      Name "primary-private-rt"
      Environment "production"
    end
  end

  # Associate private subnets with route table
  resource :aws_route_table_association, :primary_private_1a_rt_assoc do
    subnet_id ref(:aws_subnet, :primary_private_1a, :id)
    route_table_id ref(:aws_route_table, :primary_private_rt, :id)
  end

  resource :aws_route_table_association, :primary_private_1b_rt_assoc do
    subnet_id ref(:aws_subnet, :primary_private_1b, :id)
    route_table_id ref(:aws_route_table, :primary_private_rt, :id)
  end

  # Security Groups
  resource :aws_security_group, :primary_alb_sg do
    name_prefix "primary-alb-"
    description "Security group for primary region ALB"
    vpc_id ref(:aws_vpc, :primary_vpc, :id)

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
      Name "primary-alb-sg"
      Environment "production"
    end
  end

  resource :aws_security_group, :primary_app_sg do
    name_prefix "primary-app-"
    description "Security group for primary region application servers"
    vpc_id ref(:aws_vpc, :primary_vpc, :id)

    ingress do
      from_port 80
      to_port 80
      protocol "tcp"
      security_groups [ref(:aws_security_group, :primary_alb_sg, :id)]
    end

    egress do
      from_port 0
      to_port 0
      protocol "-1"
      cidr_blocks ["0.0.0.0/0"]
    end

    tags do
      Name "primary-app-sg"
      Environment "production"
    end
  end

  resource :aws_security_group, :primary_db_sg do
    name_prefix "primary-db-"
    description "Security group for primary region database"
    vpc_id ref(:aws_vpc, :primary_vpc, :id)

    ingress do
      from_port 3306
      to_port 3306
      protocol "tcp"
      security_groups [ref(:aws_security_group, :primary_app_sg, :id)]
    end

    tags do
      Name "primary-db-sg"
      Environment "production"
    end
  end

  # Application Load Balancer
  resource :aws_lb, :primary_alb do
    name "primary-alb"
    load_balancer_type "application"
    subnets [
      ref(:aws_subnet, :primary_public_1a, :id),
      ref(:aws_subnet, :primary_public_1b, :id)
    ]
    security_groups [ref(:aws_security_group, :primary_alb_sg, :id)]

    tags do
      Name "primary-alb"
      Environment "production"
      DisasterRecovery "source"
    end
  end

  # Target Group for ALB
  resource :aws_lb_target_group, :primary_app_tg do
    name "primary-app-tg"
    port 80
    protocol "HTTP"
    vpc_id ref(:aws_vpc, :primary_vpc, :id)
    target_type "instance"

    health_check do
      enabled true
      healthy_threshold 2
      unhealthy_threshold 2
      timeout 10
      interval 30
      path "/health"
      matcher "200"
      port "traffic-port"
      protocol "HTTP"
    end

    tags do
      Name "primary-app-tg"
      Environment "production"
    end
  end

  # ALB Listener
  resource :aws_lb_listener, :primary_alb_listener do
    load_balancer_arn ref(:aws_lb, :primary_alb, :arn)
    port "80"
    protocol "HTTP"

    default_action do
      type "forward"
      target_group_arn ref(:aws_lb_target_group, :primary_app_tg, :arn)
    end
  end

  # Launch Template for Auto Scaling Group
  data :aws_ami, :amazon_linux do
    most_recent true
    owners ["amazon"]
    
    filter do
      name "name"
      values ["amzn2-ami-hvm-*-x86_64-gp2"]
    end
  end

  resource :aws_launch_template, :primary_app_lt do
    name_prefix "primary-app-"
    description "Launch template for primary region application servers"

    image_id data(:aws_ami, :amazon_linux, :id)
    instance_type "t3.medium"
    key_name "my-key-pair"  # Replace with your key pair

    vpc_security_group_ids [ref(:aws_security_group, :primary_app_sg, :id)]

    user_data base64encode(<<-EOF
#!/bin/bash
yum update -y
yum install -y httpd
systemctl start httpd
systemctl enable httpd

# Create a simple health check endpoint
echo "OK" > /var/www/html/health

# Create a simple application page
cat <<HTML > /var/www/html/index.html
<!DOCTYPE html>
<html>
<head>
    <title>Primary Region Application</title>
</head>
<body>
    <h1>Primary Region - Production</h1>
    <p>Server Region: us-east-1</p>
    <p>Instance ID: \$(curl -s http://169.254.169.254/latest/meta-data/instance-id)</p>
    <p>Status: Active (Primary)</p>
</body>
</html>
HTML

# Install CloudWatch agent for monitoring
wget https://s3.amazonaws.com/amazoncloudwatch-agent/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm
rpm -U ./amazon-cloudwatch-agent.rpm
EOF
    )

    tag_specifications do
      resource_type "instance"
      tags do
        Name "primary-app-server"
        Environment "production"
        Region "primary"
        DisasterRecovery "source"
      end
    end
  end

  # Auto Scaling Group
  resource :aws_autoscaling_group, :primary_app_asg do
    name "primary-app-asg"
    vpc_zone_identifier [
      ref(:aws_subnet, :primary_private_1a, :id),
      ref(:aws_subnet, :primary_private_1b, :id)
    ]
    target_group_arns [ref(:aws_lb_target_group, :primary_app_tg, :arn)]
    health_check_type "ELB"
    health_check_grace_period 300

    min_size 2
    max_size 6
    desired_capacity 2

    launch_template do
      id ref(:aws_launch_template, :primary_app_lt, :id)
      version "$Latest"
    end

    tag do
      key "Name"
      value "primary-app-asg"
      propagate_at_launch true
    end

    tag do
      key "Environment"
      value "production"
      propagate_at_launch true
    end

    tag do
      key "DisasterRecovery"
      value "source"
      propagate_at_launch true
    end
  end

  # Database Subnet Group
  resource :aws_db_subnet_group, :primary_db_subnet_group do
    name "primary-db-subnet-group"
    description "Subnet group for primary region database"
    subnet_ids [
      ref(:aws_subnet, :primary_db_1a, :id),
      ref(:aws_subnet, :primary_db_1b, :id)
    ]

    tags do
      Name "primary-db-subnet-group"
      Environment "production"
    end
  end

  # RDS Database with automated backups and cross-region snapshots
  resource :aws_db_instance, :primary_database do
    identifier "primary-database"
    engine "mysql"
    engine_version "8.0"
    instance_class "db.t3.micro"
    allocated_storage 20
    max_allocated_storage 100
    storage_encrypted true

    db_name "productiondb"
    username "admin"
    password "replace_with_secure_password"  # Use AWS Secrets Manager in production

    vpc_security_group_ids [ref(:aws_security_group, :primary_db_sg, :id)]
    db_subnet_group_name ref(:aws_db_subnet_group, :primary_db_subnet_group, :name)

    # Backup configuration for disaster recovery
    backup_retention_period 7
    backup_window "03:00-04:00"
    maintenance_window "sun:04:00-sun:05:00"

    # Enable automated snapshots to DR region
    copy_tags_to_snapshot true
    
    # Multi-AZ for high availability in primary region
    multi_az false  # Set to true for production
    
    # Prevent accidental deletion
    deletion_protection false  # Set to true for production
    skip_final_snapshot false
    final_snapshot_identifier "primary-database-final-snapshot"

    tags do
      Name "primary-database"
      Environment "production"
      DisasterRecovery "source"
    end
  end

  # S3 Bucket for application data with cross-region replication
  resource :aws_s3_bucket, :primary_app_data do
    bucket "primary-app-data-${random_id(8)}"  # Use random suffix to avoid conflicts

    tags do
      Name "primary-app-data"
      Environment "production"
      DisasterRecovery "source"
    end
  end

  resource :aws_s3_bucket_versioning, :primary_app_data_versioning do
    bucket ref(:aws_s3_bucket, :primary_app_data, :id)
    versioning_configuration do
      status "Enabled"
    end
  end

  resource :aws_s3_bucket_server_side_encryption_configuration, :primary_app_data_encryption do
    bucket ref(:aws_s3_bucket, :primary_app_data, :id)

    rule do
      apply_server_side_encryption_by_default do
        sse_algorithm "AES256"
      end
      bucket_key_enabled true
    end
  end

  # CloudWatch Alarms for monitoring primary region health
  resource :aws_cloudwatch_metric_alarm, :primary_alb_target_response_time do
    alarm_name "primary-alb-high-response-time"
    alarm_description "Primary region ALB target response time is high"
    comparison_operator "GreaterThanThreshold"
    evaluation_periods "2"
    metric_name "TargetResponseTime"
    namespace "AWS/ApplicationELB"
    period "300"
    statistic "Average"
    threshold "1.0"
    alarm_actions []  # Add SNS topic ARN for notifications

    dimensions do
      LoadBalancer ref(:aws_lb, :primary_alb, :arn_suffix)
    end

    tags do
      Name "primary-alb-response-time-alarm"
      Environment "production"
    end
  end

  resource :aws_cloudwatch_metric_alarm, :primary_asg_unhealthy_instances do
    alarm_name "primary-asg-unhealthy-instances"
    alarm_description "Primary region has unhealthy instances"
    comparison_operator "GreaterThanThreshold"
    evaluation_periods "2"
    metric_name "UnHealthyHostCount"
    namespace "AWS/ApplicationELB"
    period "300"
    statistic "Average"
    threshold "0"
    alarm_actions []  # Add SNS topic ARN for notifications

    dimensions do
      TargetGroup ref(:aws_lb_target_group, :primary_app_tg, :arn_suffix)
    end

    tags do
      Name "primary-asg-unhealthy-alarm"
      Environment "production"
    end
  end

  # Outputs for cross-template references and monitoring
  output :primary_vpc_id do
    description "Primary region VPC ID"
    value ref(:aws_vpc, :primary_vpc, :id)
  end

  output :primary_alb_dns do
    description "Primary region ALB DNS name"
    value ref(:aws_lb, :primary_alb, :dns_name)
  end

  output :primary_alb_zone_id do
    description "Primary region ALB hosted zone ID"
    value ref(:aws_lb, :primary_alb, :zone_id)
  end

  output :primary_database_endpoint do
    description "Primary region database endpoint"
    value ref(:aws_db_instance, :primary_database, :endpoint)
  end

  output :primary_app_data_bucket do
    description "Primary region application data bucket"
    value ref(:aws_s3_bucket, :primary_app_data, :id)
  end

  output :primary_region do
    description "Primary region identifier"
    value "us-east-1"
  end
end

# Disaster Recovery Region Template - Standby Infrastructure
template :disaster_recovery_region do
  provider :aws do
    region "us-west-2"
    alias "dr"
  end

  # DR Region VPC - mirrors primary region networking
  resource :aws_vpc, :dr_vpc do
    cidr_block "10.1.0.0/16"  # Different CIDR to avoid conflicts
    enable_dns_hostnames true
    enable_dns_support true
    
    tags do
      Name "dr-vpc"
      Environment "disaster-recovery"
      Region "disaster-recovery"
      DisasterRecovery "target"
    end
  end

  # Internet Gateway for DR region
  resource :aws_internet_gateway, :dr_igw do
    vpc_id ref(:aws_vpc, :dr_vpc, :id)
    
    tags do
      Name "dr-igw"
      Environment "disaster-recovery"
    end
  end

  # Public subnets in DR region
  resource :aws_subnet, :dr_public_2a do
    vpc_id ref(:aws_vpc, :dr_vpc, :id)
    cidr_block "10.1.1.0/24"
    availability_zone "us-west-2a"
    map_public_ip_on_launch true
    
    tags do
      Name "dr-public-2a"
      Type "public"
      Environment "disaster-recovery"
    end
  end

  resource :aws_subnet, :dr_public_2b do
    vpc_id ref(:aws_vpc, :dr_vpc, :id)
    cidr_block "10.1.2.0/24"
    availability_zone "us-west-2b"
    map_public_ip_on_launch true
    
    tags do
      Name "dr-public-2b"
      Type "public"
      Environment "disaster-recovery"
    end
  end

  # Private subnets for DR region
  resource :aws_subnet, :dr_private_2a do
    vpc_id ref(:aws_vpc, :dr_vpc, :id)
    cidr_block "10.1.10.0/24"
    availability_zone "us-west-2a"
    
    tags do
      Name "dr-private-2a"
      Type "private"
      Environment "disaster-recovery"
    end
  end

  resource :aws_subnet, :dr_private_2b do
    vpc_id ref(:aws_vpc, :dr_vpc, :id)
    cidr_block "10.1.11.0/24"
    availability_zone "us-west-2b"
    
    tags do
      Name "dr-private-2b"
      Type "private"
      Environment "disaster-recovery"
    end
  end

  # Database subnets in DR region
  resource :aws_subnet, :dr_db_2a do
    vpc_id ref(:aws_vpc, :dr_vpc, :id)
    cidr_block "10.1.20.0/24"
    availability_zone "us-west-2a"
    
    tags do
      Name "dr-db-2a"
      Type "database"
      Environment "disaster-recovery"
    end
  end

  resource :aws_subnet, :dr_db_2b do
    vpc_id ref(:aws_vpc, :dr_vpc, :id)
    cidr_block "10.1.21.0/24"
    availability_zone "us-west-2b"
    
    tags do
      Name "dr-db-2b"
      Type "database"
      Environment "disaster-recovery"
    end
  end

  # Route table for public subnets in DR region
  resource :aws_route_table, :dr_public_rt do
    vpc_id ref(:aws_vpc, :dr_vpc, :id)
    
    route do
      cidr_block "0.0.0.0/0"
      gateway_id ref(:aws_internet_gateway, :dr_igw, :id)
    end
    
    tags do
      Name "dr-public-rt"
      Environment "disaster-recovery"
    end
  end

  # Associate public subnets with route table
  resource :aws_route_table_association, :dr_public_2a_rt_assoc do
    subnet_id ref(:aws_subnet, :dr_public_2a, :id)
    route_table_id ref(:aws_route_table, :dr_public_rt, :id)
  end

  resource :aws_route_table_association, :dr_public_2b_rt_assoc do
    subnet_id ref(:aws_subnet, :dr_public_2b, :id)
    route_table_id ref(:aws_route_table, :dr_public_rt, :id)
  end

  # NAT Gateway for DR region private subnet access
  resource :aws_eip, :dr_nat_eip do
    domain "vpc"
    depends_on [ref(:aws_internet_gateway, :dr_igw)]
    
    tags do
      Name "dr-nat-eip"
      Environment "disaster-recovery"
    end
  end

  resource :aws_nat_gateway, :dr_nat_gw do
    allocation_id ref(:aws_eip, :dr_nat_eip, :id)
    subnet_id ref(:aws_subnet, :dr_public_2a, :id)
    depends_on [ref(:aws_internet_gateway, :dr_igw)]
    
    tags do
      Name "dr-nat-gw"
      Environment "disaster-recovery"
    end
  end

  # Route table for private subnets in DR region
  resource :aws_route_table, :dr_private_rt do
    vpc_id ref(:aws_vpc, :dr_vpc, :id)
    
    route do
      cidr_block "0.0.0.0/0"
      nat_gateway_id ref(:aws_nat_gateway, :dr_nat_gw, :id)
    end
    
    tags do
      Name "dr-private-rt"
      Environment "disaster-recovery"
    end
  end

  # Associate private subnets with route table
  resource :aws_route_table_association, :dr_private_2a_rt_assoc do
    subnet_id ref(:aws_subnet, :dr_private_2a, :id)
    route_table_id ref(:aws_route_table, :dr_private_rt, :id)
  end

  resource :aws_route_table_association, :dr_private_2b_rt_assoc do
    subnet_id ref(:aws_subnet, :dr_private_2b, :id)
    route_table_id ref(:aws_route_table, :dr_private_rt, :id)
  end

  # Security Groups for DR region (mirror primary)
  resource :aws_security_group, :dr_alb_sg do
    name_prefix "dr-alb-"
    description "Security group for DR region ALB"
    vpc_id ref(:aws_vpc, :dr_vpc, :id)

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
      Name "dr-alb-sg"
      Environment "disaster-recovery"
    end
  end

  resource :aws_security_group, :dr_app_sg do
    name_prefix "dr-app-"
    description "Security group for DR region application servers"
    vpc_id ref(:aws_vpc, :dr_vpc, :id)

    ingress do
      from_port 80
      to_port 80
      protocol "tcp"
      security_groups [ref(:aws_security_group, :dr_alb_sg, :id)]
    end

    egress do
      from_port 0
      to_port 0
      protocol "-1"
      cidr_blocks ["0.0.0.0/0"]
    end

    tags do
      Name "dr-app-sg"
      Environment "disaster-recovery"
    end
  end

  resource :aws_security_group, :dr_db_sg do
    name_prefix "dr-db-"
    description "Security group for DR region database"
    vpc_id ref(:aws_vpc, :dr_vpc, :id)

    ingress do
      from_port 3306
      to_port 3306
      protocol "tcp"
      security_groups [ref(:aws_security_group, :dr_app_sg, :id)]
    end

    tags do
      Name "dr-db-sg"
      Environment "disaster-recovery"
    end
  end

  # Application Load Balancer for DR region (initially scaled down)
  resource :aws_lb, :dr_alb do
    name "dr-alb"
    load_balancer_type "application"
    subnets [
      ref(:aws_subnet, :dr_public_2a, :id),
      ref(:aws_subnet, :dr_public_2b, :id)
    ]
    security_groups [ref(:aws_security_group, :dr_alb_sg, :id)]

    tags do
      Name "dr-alb"
      Environment "disaster-recovery"
      DisasterRecovery "target"
    end
  end

  # Target Group for DR ALB
  resource :aws_lb_target_group, :dr_app_tg do
    name "dr-app-tg"
    port 80
    protocol "HTTP"
    vpc_id ref(:aws_vpc, :dr_vpc, :id)
    target_type "instance"

    health_check do
      enabled true
      healthy_threshold 2
      unhealthy_threshold 2
      timeout 10
      interval 30
      path "/health"
      matcher "200"
      port "traffic-port"
      protocol "HTTP"
    end

    tags do
      Name "dr-app-tg"
      Environment "disaster-recovery"
    end
  end

  # ALB Listener for DR region
  resource :aws_lb_listener, :dr_alb_listener do
    load_balancer_arn ref(:aws_lb, :dr_alb, :arn)
    port "80"
    protocol "HTTP"

    default_action do
      type "forward"
      target_group_arn ref(:aws_lb_target_group, :dr_app_tg, :arn)
    end
  end

  # Launch Template for DR Auto Scaling Group
  data :aws_ami, :amazon_linux_dr do
    most_recent true
    owners ["amazon"]
    
    filter do
      name "name"
      values ["amzn2-ami-hvm-*-x86_64-gp2"]
    end
  end

  resource :aws_launch_template, :dr_app_lt do
    name_prefix "dr-app-"
    description "Launch template for DR region application servers"

    image_id data(:aws_ami, :amazon_linux_dr, :id)
    instance_type "t3.micro"  # Smaller instances for standby
    key_name "my-key-pair"    # Replace with your key pair

    vpc_security_group_ids [ref(:aws_security_group, :dr_app_sg, :id)]

    user_data base64encode(<<-EOF
#!/bin/bash
yum update -y
yum install -y httpd
systemctl start httpd
systemctl enable httpd

# Create a simple health check endpoint
echo "OK" > /var/www/html/health

# Create a simple application page indicating DR status
cat <<HTML > /var/www/html/index.html
<!DOCTYPE html>
<html>
<head>
    <title>Disaster Recovery Region Application</title>
</head>
<body>
    <h1>Disaster Recovery Region - Standby</h1>
    <p>Server Region: us-west-2</p>
    <p>Instance ID: \$(curl -s http://169.254.169.254/latest/meta-data/instance-id)</p>
    <p>Status: Standby (Disaster Recovery)</p>
    <p style="color: orange;">⚠️ This is the disaster recovery region. Primary region may be experiencing issues.</p>
</body>
</html>
HTML

# Install CloudWatch agent for monitoring
wget https://s3.amazonaws.com/amazoncloudwatch-agent/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm
rpm -U ./amazon-cloudwatch-agent.rpm
EOF
    )

    tag_specifications do
      resource_type "instance"
      tags do
        Name "dr-app-server"
        Environment "disaster-recovery"
        Region "disaster-recovery"
        DisasterRecovery "target"
      end
    end
  end

  # Auto Scaling Group for DR region (minimal instances for cost savings)
  resource :aws_autoscaling_group, :dr_app_asg do
    name "dr-app-asg"
    vpc_zone_identifier [
      ref(:aws_subnet, :dr_private_2a, :id),
      ref(:aws_subnet, :dr_private_2b, :id)
    ]
    target_group_arns [ref(:aws_lb_target_group, :dr_app_tg, :arn)]
    health_check_type "ELB"
    health_check_grace_period 300

    min_size 0     # Start with 0 instances to save costs
    max_size 6     # Can scale up during DR events
    desired_capacity 1  # Keep 1 instance for testing/warm standby

    launch_template do
      id ref(:aws_launch_template, :dr_app_lt, :id)
      version "$Latest"
    end

    tag do
      key "Name"
      value "dr-app-asg"
      propagate_at_launch true
    end

    tag do
      key "Environment"
      value "disaster-recovery"
      propagate_at_launch true
    end

    tag do
      key "DisasterRecovery"
      value "target"
      propagate_at_launch true
    end
  end

  # Database Subnet Group for DR region
  resource :aws_db_subnet_group, :dr_db_subnet_group do
    name "dr-db-subnet-group"
    description "Subnet group for DR region database"
    subnet_ids [
      ref(:aws_subnet, :dr_db_2a, :id),
      ref(:aws_subnet, :dr_db_2b, :id)
    ]

    tags do
      Name "dr-db-subnet-group"
      Environment "disaster-recovery"
    end
  end

  # RDS Database for DR region (restored from primary snapshots)
  # Note: In practice, you would restore this from a snapshot during DR activation
  resource :aws_db_instance, :dr_database do
    identifier "dr-database"
    engine "mysql"
    engine_version "8.0"
    instance_class "db.t3.micro"
    allocated_storage 20
    storage_encrypted true

    db_name "productiondb"
    username "admin"
    password "replace_with_secure_password"  # Use AWS Secrets Manager in production

    vpc_security_group_ids [ref(:aws_security_group, :dr_db_sg, :id)]
    db_subnet_group_name ref(:aws_db_subnet_group, :dr_db_subnet_group, :name)

    # Backup configuration
    backup_retention_period 7
    backup_window "03:00-04:00"
    maintenance_window "sun:04:00-sun:05:00"
    copy_tags_to_snapshot true
    
    # Single AZ for cost savings in standby mode
    multi_az false
    
    # Allow final snapshots
    deletion_protection false
    skip_final_snapshot false
    final_snapshot_identifier "dr-database-final-snapshot"

    tags do
      Name "dr-database"
      Environment "disaster-recovery"
      DisasterRecovery "target"
    end
  end

  # S3 Bucket for DR region (receives replicated data)
  resource :aws_s3_bucket, :dr_app_data do
    bucket "dr-app-data-${random_id(8)}"  # Use random suffix to avoid conflicts

    tags do
      Name "dr-app-data"
      Environment "disaster-recovery"
      DisasterRecovery "target"
    end
  end

  resource :aws_s3_bucket_versioning, :dr_app_data_versioning do
    bucket ref(:aws_s3_bucket, :dr_app_data, :id)
    versioning_configuration do
      status "Enabled"
    end
  end

  resource :aws_s3_bucket_server_side_encryption_configuration, :dr_app_data_encryption do
    bucket ref(:aws_s3_bucket, :dr_app_data, :id)

    rule do
      apply_server_side_encryption_by_default do
        sse_algorithm "AES256"
      end
      bucket_key_enabled true
    end
  end

  # Outputs for DR region
  output :dr_vpc_id do
    description "DR region VPC ID"
    value ref(:aws_vpc, :dr_vpc, :id)
  end

  output :dr_alb_dns do
    description "DR region ALB DNS name"
    value ref(:aws_lb, :dr_alb, :dns_name)
  end

  output :dr_alb_zone_id do
    description "DR region ALB hosted zone ID"
    value ref(:aws_lb, :dr_alb, :zone_id)
  end

  output :dr_database_endpoint do
    description "DR region database endpoint"
    value ref(:aws_db_instance, :dr_database, :endpoint)
  end

  output :dr_app_data_bucket do
    description "DR region application data bucket"
    value ref(:aws_s3_bucket, :dr_app_data, :id)
  end

  output :dr_region do
    description "DR region identifier"
    value "us-west-2"
  end
end

# Backup and Monitoring Template - Cross-region coordination and monitoring
template :backup_and_monitoring do
  provider :aws do
    region "us-east-1"  # Primary region for global resources
    alias "global"
  end

  provider :aws do
    region "us-west-2"  # DR region
    alias "dr_global"
  end

  # Get references to resources from other templates
  data :aws_lb, :primary_alb do
    name "primary-alb"
  end

  data :aws_lb, :dr_alb do
    provider "aws.dr_global"
    name "dr-alb"
  end

  data :aws_s3_bucket, :primary_app_data do
    bucket "primary-app-data"  # This would need to match actual bucket name
  end

  data :aws_s3_bucket, :dr_app_data do
    provider "aws.dr_global"
    bucket "dr-app-data"     # This would need to match actual bucket name
  end

  # Route 53 Health Checks for automated failover
  resource :aws_route53_health_check, :primary_health_check do
    fqdn data(:aws_lb, :primary_alb, :dns_name)
    port 80
    type "HTTP"
    resource_path "/health"
    failure_threshold "3"
    request_interval "30"
    
    tags do
      Name "primary-region-health-check"
      Environment "production"
    end
  end

  resource :aws_route53_health_check, :dr_health_check do
    fqdn data(:aws_lb, :dr_alb, :dns_name)
    port 80
    type "HTTP"
    resource_path "/health"
    failure_threshold "3"
    request_interval "30"
    
    tags do
      Name "dr-region-health-check"
      Environment "disaster-recovery"
    end
  end

  # Route 53 Hosted Zone for application domain
  resource :aws_route53_zone, :app_domain do
    name "myapp.com"  # Replace with your domain
    
    tags do
      Name "myapp.com"
      Environment "production"
    end
  end

  # Route 53 Records with health check-based failover
  resource :aws_route53_record, :primary_app_record do
    zone_id ref(:aws_route53_zone, :app_domain, :zone_id)
    name "www.myapp.com"
    type "A"
    set_identifier "primary"
    
    failover_routing_policy do
      type "PRIMARY"
    end
    
    health_check_id ref(:aws_route53_health_check, :primary_health_check, :id)
    
    alias do
      name data(:aws_lb, :primary_alb, :dns_name)
      zone_id data(:aws_lb, :primary_alb, :zone_id)
      evaluate_target_health true
    end
  end

  resource :aws_route53_record, :dr_app_record do
    zone_id ref(:aws_route53_zone, :app_domain, :zone_id)
    name "www.myapp.com"
    type "A"
    set_identifier "disaster-recovery"
    
    failover_routing_policy do
      type "SECONDARY"
    end
    
    health_check_id ref(:aws_route53_health_check, :dr_health_check, :id)
    
    alias do
      name data(:aws_lb, :dr_alb, :dns_name)
      zone_id data(:aws_lb, :dr_alb, :zone_id)
      evaluate_target_health true
    end
  end

  # SNS Topic for DR notifications
  resource :aws_sns_topic, :dr_notifications do
    name "disaster-recovery-notifications"
    display_name "Disaster Recovery Alerts"
    
    tags do
      Name "dr-notifications"
      Environment "production"
    end
  end

  # SNS Subscription for email notifications
  resource :aws_sns_topic_subscription, :dr_email_notifications do
    topic_arn ref(:aws_sns_topic, :dr_notifications, :arn)
    protocol "email"
    endpoint "ops-team@mycompany.com"  # Replace with your email
  end

  # CloudWatch Alarms for DR events
  resource :aws_cloudwatch_metric_alarm, :primary_region_failure do
    alarm_name "primary-region-failure"
    alarm_description "Primary region health check is failing"
    comparison_operator "LessThanThreshold"
    evaluation_periods "2"
    metric_name "HealthCheckStatus"
    namespace "AWS/Route53"
    period "60"
    statistic "Minimum"
    threshold "1"
    alarm_actions [ref(:aws_sns_topic, :dr_notifications, :arn)]

    dimensions do
      HealthCheckId ref(:aws_route53_health_check, :primary_health_check, :id)
    end

    tags do
      Name "primary-region-failure-alarm"
      Environment "production"
    end
  end

  resource :aws_cloudwatch_metric_alarm, :dr_activation do
    alarm_name "disaster-recovery-activation"
    alarm_description "Disaster recovery region is receiving traffic"
    comparison_operator "GreaterThanThreshold"
    evaluation_periods "1"
    metric_name "RequestCount"
    namespace "AWS/ApplicationELB"
    period "300"
    statistic "Sum"
    threshold "10"
    alarm_actions [ref(:aws_sns_topic, :dr_notifications, :arn)]

    dimensions do
      LoadBalancer data(:aws_lb, :dr_alb, :arn_suffix)
    end

    tags do
      Name "dr-activation-alarm"
      Environment "disaster-recovery"
    end
  end

  # IAM Role for Lambda DR automation functions
  resource :aws_iam_role, :dr_automation_role do
    name "dr-automation-role"
    assume_role_policy jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action = "sts:AssumeRole"
          Effect = "Allow"
          Principal = {
            Service = "lambda.amazonaws.com"
          }
        }
      ]
    })

    tags do
      Name "dr-automation-role"
      Environment "production"
    end
  end

  # IAM Policy for DR automation
  resource :aws_iam_role_policy, :dr_automation_policy do
    name "dr-automation-policy"
    role ref(:aws_iam_role, :dr_automation_role, :id)
    
    policy jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "logs:CreateLogGroup",
            "logs:CreateLogStream", 
            "logs:PutLogEvents",
            "rds:DescribeDBSnapshots",
            "rds:RestoreDBInstanceFromDBSnapshot",
            "autoscaling:UpdateAutoScalingGroup",
            "s3:ListBucket",
            "s3:GetObject",
            "sns:Publish",
            "route53:ChangeResourceRecordSets"
          ]
          Resource = "*"
        }
      ]
    })
  end

  # Lambda function for DR automation and testing
  resource :aws_lambda_function, :dr_automation do
    filename "dr_automation.zip"  # You would need to create this zip file
    function_name "disaster-recovery-automation"
    role ref(:aws_iam_role, :dr_automation_role, :arn)
    handler "index.handler"
    runtime "python3.9"
    timeout 300

    environment do
      variables = {
        PRIMARY_REGION = "us-east-1"
        DR_REGION = "us-west-2"
        SNS_TOPIC_ARN = ref(:aws_sns_topic, :dr_notifications, :arn)
      }
    end

    tags do
      Name "dr-automation-function"
      Environment "production"
    end
  end

  # CloudWatch Event Rule for scheduled DR testing
  resource :aws_cloudwatch_event_rule, :dr_test_schedule do
    name "dr-test-schedule"
    description "Schedule for disaster recovery testing"
    schedule_expression "cron(0 2 ? * SUN *)"  # Every Sunday at 2 AM UTC
    
    tags do
      Name "dr-test-schedule"
      Environment "production"
    end
  end

  # CloudWatch Event Target to trigger DR test Lambda
  resource :aws_cloudwatch_event_target, :dr_test_target do
    rule ref(:aws_cloudwatch_event_rule, :dr_test_schedule, :name)
    target_id "DrTestLambdaTarget"
    arn ref(:aws_lambda_function, :dr_automation, :arn)
    
    input jsonencode({
      test_mode = true
      action = "test_dr_readiness"
    })
  end

  # Lambda permission for CloudWatch Events
  resource :aws_lambda_permission, :allow_cloudwatch_events do
    statement_id "AllowExecutionFromCloudWatch"
    action "lambda:InvokeFunction"
    function_name ref(:aws_lambda_function, :dr_automation, :function_name)
    principal "events.amazonaws.com"
    source_arn ref(:aws_cloudwatch_event_rule, :dr_test_schedule, :arn)
  end

  # S3 Cross-Region Replication Configuration
  # Note: This requires the buckets to exist and have versioning enabled
  
  # IAM Role for S3 Cross-Region Replication
  resource :aws_iam_role, :s3_replication_role do
    name "s3-cross-region-replication-role"
    assume_role_policy jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action = "sts:AssumeRole"
          Effect = "Allow"
          Principal = {
            Service = "s3.amazonaws.com"
          }
        }
      ]
    })

    tags do
      Name "s3-replication-role"
      Environment "production"
    end
  end

  resource :aws_iam_role_policy, :s3_replication_policy do
    name "s3-replication-policy"
    role ref(:aws_iam_role, :s3_replication_role, :id)
    
    policy jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "s3:GetObjectVersionForReplication",
            "s3:GetObjectVersionAcl",
            "s3:GetObjectVersionTagging"
          ]
          Resource = "${data(:aws_s3_bucket, :primary_app_data, :arn)}/*"
        },
        {
          Effect = "Allow"
          Action = [
            "s3:ListBucket"
          ]
          Resource = data(:aws_s3_bucket, :primary_app_data, :arn)
        },
        {
          Effect = "Allow"
          Action = [
            "s3:ReplicateObject",
            "s3:ReplicateDelete",
            "s3:ReplicateTags"
          ]
          Resource = "${data(:aws_s3_bucket, :dr_app_data, :arn)}/*"
        }
      ]
    })
  end

  # Outputs for monitoring and coordination
  output :route53_zone_id do
    description "Route 53 hosted zone ID for the application domain"
    value ref(:aws_route53_zone, :app_domain, :zone_id)
  end

  output :primary_health_check_id do
    description "Route 53 health check ID for primary region"
    value ref(:aws_route53_health_check, :primary_health_check, :id)
  end

  output :dr_health_check_id do
    description "Route 53 health check ID for DR region"
    value ref(:aws_route53_health_check, :dr_health_check, :id)
  end

  output :dr_notification_topic do
    description "SNS topic for disaster recovery notifications"
    value ref(:aws_sns_topic, :dr_notifications, :arn)
  end

  output :dr_automation_function do
    description "Lambda function for DR automation"
    value ref(:aws_lambda_function, :dr_automation, :arn)
  end

  output :application_url do
    description "Main application URL with automatic failover"
    value "https://www.myapp.com"
  end
end