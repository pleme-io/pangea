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

# Main infrastructure file demonstrating Pangea capabilities
# This file contains multiple templates that represent different parts of infrastructure

# Template 1: Core networking infrastructure
template :networking do
  provider :aws do
    region "us-east-1"
    default_tags do
      tags do
        ManagedBy "pangea"
        Environment "development"
        Project "pangea-test"
      end
    end
  end
  
  # Create VPC using resource function
  vpc = aws_vpc(:main, {
    cidr_block: "10.0.0.0/16",
    enable_dns_hostnames: true,
    enable_dns_support: true,
    tags: {
      Name: "pangea-test-vpc",
      Type: "main"
    }
  })
  
  # Create Internet Gateway
  igw = aws_internet_gateway(:main, {
    vpc_id: vpc.id,
    tags: {
      Name: "pangea-test-igw"
    }
  })
  
  # Public Subnets across multiple AZs
  public_subnet_a = aws_subnet(:public_a, {
    vpc_id: vpc.id,
    cidr_block: "10.0.1.0/24",
    availability_zone: "us-east-1a",
    map_public_ip_on_launch: true,
    tags: {
      Name: "pangea-test-public-1a",
      Type: "public"
    }
  })
  
  public_subnet_b = aws_subnet(:public_b, {
    vpc_id: vpc.id,
    cidr_block: "10.0.2.0/24",
    availability_zone: "us-east-1b",
    map_public_ip_on_launch: true,
    tags: {
      Name: "pangea-test-public-1b",
      Type: "public"
    }
  })
  
  # Private Subnets
  private_subnet_a = aws_subnet(:private_a, {
    vpc_id: vpc.id,
    cidr_block: "10.0.10.0/24",
    availability_zone: "us-east-1a",
    tags: {
      Name: "pangea-test-private-1a",
      Type: "private"
    }
  })
  
  private_subnet_b = aws_subnet(:private_b, {
    vpc_id: vpc.id,
    cidr_block: "10.0.11.0/24",
    availability_zone: "us-east-1b",
    tags: {
      Name: "pangea-test-private-1b",
      Type: "private"
    }
  })
  
  # Route Tables
  public_route_table = aws_route_table(:public, {
    vpc_id: vpc.id,
    tags: {
      Name: "pangea-test-public-rt"
    }
  })
  
  # Route to Internet Gateway
  aws_route(:public_internet, {
    route_table_id: public_route_table.id,
    destination_cidr_block: "0.0.0.0/0",
    gateway_id: igw.id
  })
  
  # Associate public subnets with route table
  aws_route_table_association(:public_a, {
    subnet_id: public_subnet_a.id,
    route_table_id: public_route_table.id
  })
  
  aws_route_table_association(:public_b, {
    subnet_id: public_subnet_b.id,
    route_table_id: public_route_table.id
  })
  
  # Outputs for other templates to reference
  output :vpc_id do
    value vpc.id
    description "ID of the main VPC"
  end
  
  output :public_subnet_ids do
    value [public_subnet_a.id, public_subnet_b.id]
    description "IDs of public subnets"
  end
  
  output :private_subnet_ids do
    value [private_subnet_a.id, private_subnet_b.id]
    description "IDs of private subnets"
  end
end

# Template 2: Security configuration
template :security do
  provider :aws do
    region "us-east-1"
  end
  
  # Import VPC ID from networking template
  data :terraform_remote_state, :networking do
    backend "local"
    config do
      path "../networking/terraform.tfstate"
    end
  end
  
  # Web Server Security Group
  web_sg = aws_security_group(:web, {
    name: "pangea-test-web-sg",
    description: "Security group for web servers",
    vpc_id: "${data.terraform_remote_state.networking.outputs.vpc_id}",
    
    ingress: [
      {
        description: "HTTP from anywhere",
        from_port: 80,
        to_port: 80,
        protocol: "tcp",
        cidr_blocks: ["0.0.0.0/0"]
      },
      {
        description: "HTTPS from anywhere",
        from_port: 443,
        to_port: 443,
        protocol: "tcp",
        cidr_blocks: ["0.0.0.0/0"]
      },
      {
        description: "SSH from VPC",
        from_port: 22,
        to_port: 22,
        protocol: "tcp",
        cidr_blocks: ["10.0.0.0/16"]
      }
    ],
    
    egress: [
      {
        description: "All outbound",
        from_port: 0,
        to_port: 0,
        protocol: "-1",
        cidr_blocks: ["0.0.0.0/0"]
      }
    ],
    
    tags: {
      Name: "pangea-test-web-sg"
    }
  })
  
  # Database Security Group
  db_sg = aws_security_group(:database, {
    name: "pangea-test-db-sg",
    description: "Security group for databases",
    vpc_id: "${data.terraform_remote_state.networking.outputs.vpc_id}",
    
    ingress: [
      {
        description: "PostgreSQL from web servers",
        from_port: 5432,
        to_port: 5432,
        protocol: "tcp",
        security_groups: [web_sg.id]
      }
    ],
    
    egress: [
      {
        description: "All outbound",
        from_port: 0,
        to_port: 0,
        protocol: "-1",
        cidr_blocks: ["0.0.0.0/0"]
      }
    ],
    
    tags: {
      Name: "pangea-test-db-sg"
    }
  })
  
  output :web_security_group_id do
    value web_sg.id
    description "ID of the web server security group"
  end
  
  output :db_security_group_id do
    value db_sg.id
    description "ID of the database security group"
  end
end

# Template 3: Storage resources
template :storage do
  provider :aws do
    region "us-east-1"
  end
  
  # Application assets bucket
  assets_bucket = aws_s3_bucket(:assets, {
    bucket: "pangea-test-assets-${random_id.bucket_suffix.hex}",
    tags: {
      Name: "pangea-test-assets",
      Purpose: "Application assets"
    }
  })
  
  # Bucket versioning
  aws_s3_bucket_versioning(:assets, {
    bucket: assets_bucket.id,
    versioning_configuration: {
      status: "Enabled"
    }
  })
  
  # Bucket encryption
  aws_s3_bucket_server_side_encryption_configuration(:assets, {
    bucket: assets_bucket.id,
    rule: [
      {
        apply_server_side_encryption_by_default: {
          sse_algorithm: "AES256"
        }
      }
    ]
  })
  
  # Public access block
  aws_s3_bucket_public_access_block(:assets, {
    bucket: assets_bucket.id,
    block_public_acls: true,
    block_public_policy: true,
    ignore_public_acls: true,
    restrict_public_buckets: true
  })
  
  # Logs bucket
  logs_bucket = aws_s3_bucket(:logs, {
    bucket: "pangea-test-logs-${random_id.bucket_suffix.hex}",
    tags: {
      Name: "pangea-test-logs",
      Purpose: "Application logs"
    }
  })
  
  # Logs bucket lifecycle
  aws_s3_bucket_lifecycle_configuration(:logs, {
    bucket: logs_bucket.id,
    rule: [
      {
        id: "expire-old-logs",
        status: "Enabled",
        expiration: {
          days: 90
        }
      },
      {
        id: "transition-to-glacier",
        status: "Enabled",
        transition: [
          {
            days: 30,
            storage_class: "GLACIER"
          }
        ]
      }
    ]
  })
  
  # Random suffix for bucket names
  resource :random_id, :bucket_suffix do
    byte_length 4
  end
  
  output :assets_bucket_name do
    value assets_bucket.id
    description "Name of the assets bucket"
  end
  
  output :logs_bucket_name do
    value logs_bucket.id
    description "Name of the logs bucket"
  end
end

# Template 4: Compute resources
template :compute do
  provider :aws do
    region "us-east-1"
  end
  
  # Import from other templates
  data :terraform_remote_state, :networking do
    backend "local"
    config do
      path "../networking/terraform.tfstate"
    end
  end
  
  data :terraform_remote_state, :security do
    backend "local"
    config do
      path "../security/terraform.tfstate"
    end
  end
  
  # Latest Amazon Linux 2 AMI
  data :aws_ami, :amazon_linux do
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
  
  # Launch Template for web servers
  launch_template = aws_launch_template(:web, {
    name_prefix: "pangea-test-web-",
    image_id: "${data.aws_ami.amazon_linux.id}",
    instance_type: "t3.micro",
    
    vpc_security_group_ids: ["${data.terraform_remote_state.security.outputs.web_security_group_id}"],
    
    user_data: base64encode(<<-EOF
      #!/bin/bash
      yum update -y
      yum install -y httpd
      systemctl start httpd
      systemctl enable httpd
      echo "<h1>Hello from Pangea!</h1>" > /var/www/html/index.html
    EOF
    ),
    
    tag_specifications: [
      {
        resource_type: "instance",
        tags: {
          Name: "pangea-test-web-server"
        }
      }
    ]
  })
  
  # Auto Scaling Group
  aws_autoscaling_group(:web, {
    name: "pangea-test-web-asg",
    vpc_zone_identifier: "${data.terraform_remote_state.networking.outputs.public_subnet_ids}",
    target_group_arns: [], # Would connect to ALB target group
    health_check_type: "EC2",
    health_check_grace_period: 300,
    
    min_size: 1,
    max_size: 3,
    desired_capacity: 2,
    
    launch_template: {
      id: launch_template.id,
      version: "$Latest"
    },
    
    tag: [
      {
        key: "Name",
        value: "pangea-test-asg-instance",
        propagate_at_launch: true
      }
    ]
  })
  
  output :launch_template_id do
    value launch_template.id
    description "ID of the web server launch template"
  end
end

# Template 5: Monitoring and observability
template :monitoring do
  provider :aws do
    region "us-east-1"
  end
  
  # CloudWatch Log Group for application logs
  log_group = aws_cloudwatch_log_group(:app, {
    name: "/aws/pangea-test/application",
    retention_in_days: 7,
    
    tags: {
      Name: "pangea-test-logs",
      Application: "pangea-test"
    }
  })
  
  # SNS Topic for alerts
  alert_topic = aws_sns_topic(:alerts, {
    name: "pangea-test-alerts",
    display_name: "Pangea Test Alerts",
    
    tags: {
      Name: "pangea-test-alerts"
    }
  })
  
  # Email subscription (would need to be confirmed)
  aws_sns_topic_subscription(:alert_email, {
    topic_arn: alert_topic.arn,
    protocol: "email",
    endpoint: "test@example.com"
  })
  
  # High CPU Alarm
  aws_cloudwatch_metric_alarm(:high_cpu, {
    alarm_name: "pangea-test-high-cpu",
    comparison_operator: "GreaterThanThreshold",
    evaluation_periods: 2,
    metric_name: "CPUUtilization",
    namespace: "AWS/EC2",
    period: 300,
    statistic: "Average",
    threshold: 80,
    alarm_description: "This metric monitors CPU utilization",
    alarm_actions: [alert_topic.arn]
  })
  
  # CloudWatch Dashboard
  aws_cloudwatch_dashboard(:main, {
    dashboard_name: "pangea-test-dashboard",
    dashboard_body: jsonencode({
      widgets: [
        {
          type: "metric",
          x: 0,
          y: 0,
          width: 12,
          height: 6,
          properties: {
            metrics: [
              ["AWS/EC2", "CPUUtilization", { stat: "Average" }]
            ],
            period: 300,
            stat: "Average",
            region: "us-east-1",
            title: "EC2 CPU Utilization"
          }
        }
      ]
    })
  })
  
  output :log_group_name do
    value log_group.name
    description "Name of the CloudWatch log group"
  end
  
  output :alert_topic_arn do
    value alert_topic.arn
    description "ARN of the SNS alert topic"
  end
end