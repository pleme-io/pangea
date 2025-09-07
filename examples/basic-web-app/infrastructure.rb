# Basic Web Application Infrastructure
#
# This example demonstrates a complete web application infrastructure in a single template.
# It includes networking, compute, load balancing, and auto-scaling capabilities.
#
# Architecture:
# - VPC with public/private subnets across 2 availability zones
# - Application Load Balancer for traffic distribution
# - Auto Scaling Group with configurable capacity
# - Security groups with least-privilege access
# - CloudWatch monitoring and alarms
#
# Usage:
#   # Local development
#   pangea plan infrastructure.rb
#   pangea apply infrastructure.rb
#   
#   # Staging deployment
#   pangea plan infrastructure.rb --namespace staging
#   pangea apply infrastructure.rb --namespace staging
#   
#   # Production deployment
#   pangea plan infrastructure.rb --namespace production
#   pangea apply infrastructure.rb --namespace production

template :web_application do
  # AWS Provider configuration
  provider :aws do
    region var(:aws_region, "us-east-1")
  end

  # Variables for environment-specific configuration
  variable :environment do
    type "string"
    default "development"
    description "Environment name (development, staging, production)"
  end

  variable :aws_region do
    type "string"
    default "us-east-1"
    description "AWS region for deployment"
  end

  variable :app_name do
    type "string"
    default "basic-web-app"
    description "Application name used for resource naming"
  end

  variable :instance_type do
    type "string"
    default "t3.micro"
    description "EC2 instance type for application servers"
  end

  variable :min_instances do
    type "number"
    default 1
    description "Minimum number of instances in Auto Scaling Group"
  end

  variable :max_instances do
    type "number"
    default 4
    description "Maximum number of instances in Auto Scaling Group"
  end

  variable :desired_instances do
    type "number"
    default 2
    description "Desired number of instances in Auto Scaling Group"
  end

  # Locals for computed values
  locals do
    common_tags {
      Application var(:app_name)
      Environment var(:environment)
      ManagedBy "pangea"
    }
  end

  # VPC Configuration
  resource :aws_vpc, :main do
    cidr_block "10.0.0.0/16"
    enable_dns_hostnames true
    enable_dns_support true
    
    tags merge(local(:common_tags), {
      Name: "${var(:app_name)}-vpc-${var(:environment)}"
    })
  end

  # Internet Gateway
  resource :aws_internet_gateway, :main do
    vpc_id ref(:aws_vpc, :main, :id)
    
    tags merge(local(:common_tags), {
      Name: "${var(:app_name)}-igw-${var(:environment)}"
    })
  end

  # Public Subnets
  resource :aws_subnet, :public_a do
    vpc_id ref(:aws_vpc, :main, :id)
    cidr_block "10.0.1.0/24"
    availability_zone "${var(:aws_region)}a"
    map_public_ip_on_launch true
    
    tags merge(local(:common_tags), {
      Name: "${var(:app_name)}-public-subnet-a-${var(:environment)}",
      Type: "public"
    })
  end

  resource :aws_subnet, :public_b do
    vpc_id ref(:aws_vpc, :main, :id)
    cidr_block "10.0.2.0/24"
    availability_zone "${var(:aws_region)}b"
    map_public_ip_on_launch true
    
    tags merge(local(:common_tags), {
      Name: "${var(:app_name)}-public-subnet-b-${var(:environment)}",
      Type: "public"
    })
  end

  # Private Subnets
  resource :aws_subnet, :private_a do
    vpc_id ref(:aws_vpc, :main, :id)
    cidr_block "10.0.10.0/24"
    availability_zone "${var(:aws_region)}a"
    
    tags merge(local(:common_tags), {
      Name: "${var(:app_name)}-private-subnet-a-${var(:environment)}",
      Type: "private"
    })
  end

  resource :aws_subnet, :private_b do
    vpc_id ref(:aws_vpc, :main, :id)
    cidr_block "10.0.11.0/24"
    availability_zone "${var(:aws_region)}b"
    
    tags merge(local(:common_tags), {
      Name: "${var(:app_name)}-private-subnet-b-${var(:environment)}",
      Type: "private"
    })
  end

  # Elastic IPs for NAT Gateways
  resource :aws_eip, :nat_a do
    domain "vpc"
    depends_on [ref(:aws_internet_gateway, :main)]
    
    tags merge(local(:common_tags), {
      Name: "${var(:app_name)}-nat-eip-a-${var(:environment)}"
    })
  end

  resource :aws_eip, :nat_b do
    domain "vpc"
    depends_on [ref(:aws_internet_gateway, :main)]
    
    tags merge(local(:common_tags), {
      Name: "${var(:app_name)}-nat-eip-b-${var(:environment)}"
    })
  end

  # NAT Gateways
  resource :aws_nat_gateway, :nat_a do
    allocation_id ref(:aws_eip, :nat_a, :id)
    subnet_id ref(:aws_subnet, :public_a, :id)
    depends_on [ref(:aws_internet_gateway, :main)]
    
    tags merge(local(:common_tags), {
      Name: "${var(:app_name)}-nat-gw-a-${var(:environment)}"
    })
  end

  resource :aws_nat_gateway, :nat_b do
    allocation_id ref(:aws_eip, :nat_b, :id)
    subnet_id ref(:aws_subnet, :public_b, :id)
    depends_on [ref(:aws_internet_gateway, :main)]
    
    tags merge(local(:common_tags), {
      Name: "${var(:app_name)}-nat-gw-b-${var(:environment)}"
    })
  end

  # Route Tables
  resource :aws_route_table, :public do
    vpc_id ref(:aws_vpc, :main, :id)
    
    route do
      cidr_block "0.0.0.0/0"
      gateway_id ref(:aws_internet_gateway, :main, :id)
    end
    
    tags merge(local(:common_tags), {
      Name: "${var(:app_name)}-public-rt-${var(:environment)}"
    })
  end

  resource :aws_route_table, :private_a do
    vpc_id ref(:aws_vpc, :main, :id)
    
    route do
      cidr_block "0.0.0.0/0"
      nat_gateway_id ref(:aws_nat_gateway, :nat_a, :id)
    end
    
    tags merge(local(:common_tags), {
      Name: "${var(:app_name)}-private-rt-a-${var(:environment)}"
    })
  end

  resource :aws_route_table, :private_b do
    vpc_id ref(:aws_vpc, :main, :id)
    
    route do
      cidr_block "0.0.0.0/0"
      nat_gateway_id ref(:aws_nat_gateway, :nat_b, :id)
    end
    
    tags merge(local(:common_tags), {
      Name: "${var(:app_name)}-private-rt-b-${var(:environment)}"
    })
  end

  # Route Table Associations
  resource :aws_route_table_association, :public_a do
    subnet_id ref(:aws_subnet, :public_a, :id)
    route_table_id ref(:aws_route_table, :public, :id)
  end

  resource :aws_route_table_association, :public_b do
    subnet_id ref(:aws_subnet, :public_b, :id)
    route_table_id ref(:aws_route_table, :public, :id)
  end

  resource :aws_route_table_association, :private_a do
    subnet_id ref(:aws_subnet, :private_a, :id)
    route_table_id ref(:aws_route_table, :private_a, :id)
  end

  resource :aws_route_table_association, :private_b do
    subnet_id ref(:aws_subnet, :private_b, :id)
    route_table_id ref(:aws_route_table, :private_b, :id)
  end

  # Security Groups
  resource :aws_security_group, :alb do
    name_prefix "${var(:app_name)}-alb-${var(:environment)}-"
    description "Security group for Application Load Balancer"
    vpc_id ref(:aws_vpc, :main, :id)

    ingress do
      from_port 80
      to_port 80
      protocol "tcp"
      cidr_blocks ["0.0.0.0/0"]
      description "Allow HTTP from anywhere"
    end

    ingress do
      from_port 443
      to_port 443
      protocol "tcp"
      cidr_blocks ["0.0.0.0/0"]
      description "Allow HTTPS from anywhere"
    end

    egress do
      from_port 0
      to_port 0
      protocol "-1"
      cidr_blocks ["0.0.0.0/0"]
      description "Allow all outbound traffic"
    end

    tags merge(local(:common_tags), {
      Name: "${var(:app_name)}-alb-sg-${var(:environment)}"
    })
  end

  resource :aws_security_group, :app do
    name_prefix "${var(:app_name)}-app-${var(:environment)}-"
    description "Security group for application servers"
    vpc_id ref(:aws_vpc, :main, :id)

    ingress do
      from_port 80
      to_port 80
      protocol "tcp"
      security_groups [ref(:aws_security_group, :alb, :id)]
      description "Allow HTTP from ALB"
    end

    egress do
      from_port 0
      to_port 0
      protocol "-1"
      cidr_blocks ["0.0.0.0/0"]
      description "Allow all outbound traffic"
    end

    tags merge(local(:common_tags), {
      Name: "${var(:app_name)}-app-sg-${var(:environment)}"
    })
  end

  # Application Load Balancer
  resource :aws_lb, :main do
    name "${var(:app_name)}-alb-${var(:environment)}"
    load_balancer_type "application"
    subnets [
      ref(:aws_subnet, :public_a, :id),
      ref(:aws_subnet, :public_b, :id)
    ]
    security_groups [ref(:aws_security_group, :alb, :id)]

    enable_deletion_protection false
    enable_http2 true

    tags merge(local(:common_tags), {
      Name: "${var(:app_name)}-alb-${var(:environment)}"
    })
  end

  # ALB Target Group
  resource :aws_lb_target_group, :app do
    name "${var(:app_name)}-tg-${var(:environment)}"
    port 80
    protocol "HTTP"
    vpc_id ref(:aws_vpc, :main, :id)
    target_type "instance"

    health_check do
      enabled true
      healthy_threshold 2
      unhealthy_threshold 2
      timeout 5
      interval 30
      path "/health"
      matcher "200"
    end

    stickiness do
      type "lb_cookie"
      enabled true
      cookie_duration 86400
    end

    tags merge(local(:common_tags), {
      Name: "${var(:app_name)}-tg-${var(:environment)}"
    })
  end

  # ALB Listener
  resource :aws_lb_listener, :http do
    load_balancer_arn ref(:aws_lb, :main, :arn)
    port "80"
    protocol "HTTP"

    default_action do
      type "forward"
      target_group_arn ref(:aws_lb_target_group, :app, :arn)
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

    filter do
      name "virtualization-type"
      values ["hvm"]
    end
  end

  resource :aws_launch_template, :app do
    name_prefix "${var(:app_name)}-${var(:environment)}-"
    description "Launch template for ${var(:app_name)} application servers"

    image_id data(:aws_ami, :app, :id)
    instance_type var(:instance_type)
    
    vpc_security_group_ids [ref(:aws_security_group, :app, :id)]

    user_data base64encode(<<-EOF
#!/bin/bash
yum update -y
yum install -y httpd
systemctl start httpd
systemctl enable httpd

# Create health check endpoint
echo "OK" > /var/www/html/health

# Create sample application
cat <<'HTML' > /var/www/html/index.html
<!DOCTYPE html>
<html>
<head>
    <title>${var(:app_name)}</title>
    <style>
        body { font-family: Arial, sans-serif; max-width: 800px; margin: 0 auto; padding: 20px; }
        .info { background: #e3f2fd; padding: 15px; border-radius: 5px; margin: 20px 0; }
        .metric { display: inline-block; margin: 10px 20px 10px 0; }
    </style>
</head>
<body>
    <h1>${var(:app_name)} - ${var(:environment)}</h1>
    <div class="info">
        <h2>Instance Information</h2>
        <div class="metric"><strong>Instance ID:</strong> <span id="instance-id"></span></div>
        <div class="metric"><strong>Availability Zone:</strong> <span id="az"></span></div>
        <div class="metric"><strong>Instance Type:</strong> ${var(:instance_type)}</div>
        <div class="metric"><strong>Region:</strong> ${var(:aws_region)}</div>
    </div>
    <script>
        fetch('http://169.254.169.254/latest/meta-data/instance-id')
            .then(response => response.text())
            .then(data => document.getElementById('instance-id').textContent = data);
        fetch('http://169.254.169.254/latest/meta-data/placement/availability-zone')
            .then(response => response.text())
            .then(data => document.getElementById('az').textContent = data);
    </script>
</body>
</html>
HTML

# Install CloudWatch agent
wget https://s3.amazonaws.com/amazoncloudwatch-agent/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm
rpm -U ./amazon-cloudwatch-agent.rpm

# Configure CloudWatch agent for basic metrics
cat <<'CONFIG' > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
{
  "metrics": {
    "namespace": "${var(:app_name)}-${var(:environment)}",
    "metrics_collected": {
      "cpu": {
        "measurement": [
          "cpu_usage_idle",
          "cpu_usage_active"
        ],
        "metrics_collection_interval": 60,
        "totalcpu": true
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
  }
}
CONFIG

# Start CloudWatch agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
    -a fetch-config \
    -m ec2 \
    -s \
    -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
EOF
    )

    monitoring do
      enabled true
    end

    tag_specifications do
      resource_type "instance"
      tags merge(local(:common_tags), {
        Name: "${var(:app_name)}-instance-${var(:environment)}"
      })
    end

    tag_specifications do
      resource_type "volume"
      tags merge(local(:common_tags), {
        Name: "${var(:app_name)}-volume-${var(:environment)}"
      })
    end
  end

  # Auto Scaling Group
  resource :aws_autoscaling_group, :app do
    name "${var(:app_name)}-asg-${var(:environment)}"
    vpc_zone_identifier [
      ref(:aws_subnet, :private_a, :id),
      ref(:aws_subnet, :private_b, :id)
    ]
    
    target_group_arns [ref(:aws_lb_target_group, :app, :arn)]
    health_check_type "ELB"
    health_check_grace_period 300
    
    min_size var(:min_instances)
    max_size var(:max_instances)
    desired_capacity var(:desired_instances)

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
      value "${var(:app_name)}-asg-${var(:environment)}"
      propagate_at_launch true
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
    name "${var(:app_name)}-scale-up-${var(:environment)}"
    autoscaling_group_name ref(:aws_autoscaling_group, :app, :name)
    adjustment_type "ChangeInCapacity"
    scaling_adjustment 1
    cooldown 300
  end

  resource :aws_autoscaling_policy, :scale_down do
    name "${var(:app_name)}-scale-down-${var(:environment)}"
    autoscaling_group_name ref(:aws_autoscaling_group, :app, :name)
    adjustment_type "ChangeInCapacity"
    scaling_adjustment -1
    cooldown 300
  end

  # CloudWatch Alarms
  resource :aws_cloudwatch_metric_alarm, :high_cpu do
    alarm_name "${var(:app_name)}-high-cpu-${var(:environment)}"
    alarm_description "Trigger scaling up when CPU exceeds 70%"
    comparison_operator "GreaterThanThreshold"
    evaluation_periods "2"
    metric_name "CPUUtilization"
    namespace "AWS/EC2"
    period "300"
    statistic "Average"
    threshold "70"
    alarm_actions [ref(:aws_autoscaling_policy, :scale_up, :arn)]

    dimensions do
      AutoScalingGroupName ref(:aws_autoscaling_group, :app, :name)
    end

    tags merge(local(:common_tags), {
      Name: "${var(:app_name)}-high-cpu-alarm-${var(:environment)}"
    })
  end

  resource :aws_cloudwatch_metric_alarm, :low_cpu do
    alarm_name "${var(:app_name)}-low-cpu-${var(:environment)}"
    alarm_description "Trigger scaling down when CPU is below 30%"
    comparison_operator "LessThanThreshold"
    evaluation_periods "2"
    metric_name "CPUUtilization"
    namespace "AWS/EC2"
    period "300"
    statistic "Average"
    threshold "30"
    alarm_actions [ref(:aws_autoscaling_policy, :scale_down, :arn)]

    dimensions do
      AutoScalingGroupName ref(:aws_autoscaling_group, :app, :name)
    end

    tags merge(local(:common_tags), {
      Name: "${var(:app_name)}-low-cpu-alarm-${var(:environment)}"
    })
  end

  # S3 Bucket for application logs
  resource :aws_s3_bucket, :logs do
    bucket "${var(:app_name)}-logs-${var(:environment)}-${random_id(8)}"

    tags merge(local(:common_tags), {
      Name: "${var(:app_name)}-logs-${var(:environment)}"
    })
  end

  resource :aws_s3_bucket_lifecycle_configuration, :logs do
    bucket ref(:aws_s3_bucket, :logs, :id)

    rule do
      id "expire-old-logs"
      status "Enabled"

      expiration do
        days 30
      end
    end
  end

  resource :aws_s3_bucket_server_side_encryption_configuration, :logs do
    bucket ref(:aws_s3_bucket, :logs, :id)

    rule do
      apply_server_side_encryption_by_default do
        sse_algorithm "AES256"
      end
    end
  end

  # Outputs
  output :alb_dns_name do
    description "DNS name of the Application Load Balancer"
    value ref(:aws_lb, :main, :dns_name)
  end

  output :alb_url do
    description "URL of the application"
    value "http://${ref(:aws_lb, :main, :dns_name)}"
  end

  output :vpc_id do
    description "ID of the VPC"
    value ref(:aws_vpc, :main, :id)
  end

  output :public_subnet_ids do
    description "IDs of public subnets"
    value [
      ref(:aws_subnet, :public_a, :id),
      ref(:aws_subnet, :public_b, :id)
    ]
  end

  output :private_subnet_ids do
    description "IDs of private subnets"
    value [
      ref(:aws_subnet, :private_a, :id),
      ref(:aws_subnet, :private_b, :id)
    ]
  end

  output :asg_name do
    description "Name of the Auto Scaling Group"
    value ref(:aws_autoscaling_group, :app, :name)
  end

  output :log_bucket do
    description "S3 bucket for application logs"
    value ref(:aws_s3_bucket, :logs, :id)
  end
end