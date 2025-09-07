# Pangea Resource Function Reference

This comprehensive reference documents all type-safe AWS resource functions available in Pangea. Each resource provides strong typing, validation, and intelligent defaults.

## Core Networking Resources

### AWS VPC
Create type-safe Virtual Private Clouds with validation and computed properties.
```ruby
vpc = aws_vpc(:main, {
  cidr_block: "10.0.0.0/16",
  enable_dns_hostnames: true,
  enable_dns_support: true,
  tags: { Name: "main-vpc", Environment: "production" }
})
```

### AWS Subnet  
Create public and private subnets within VPCs.
```ruby
subnet = aws_subnet(:public_a, {
  vpc_id: vpc.id,
  cidr_block: "10.0.1.0/24", 
  availability_zone: "us-east-1a",
  map_public_ip_on_launch: true,
  tags: { Name: "public-subnet-a", Type: "public" }
})
```

### AWS Security Group
Create security groups with ingress and egress rules.
```ruby
sg = aws_security_group(:web, {
  name: "web-sg",
  description: "Web server security group",
  vpc_id: vpc.id,
  ingress: [{
    from_port: 443,
    to_port: 443,
    protocol: "tcp", 
    cidr_blocks: ["0.0.0.0/0"]
  }],
  tags: { Name: "web-security-group" }
})
```

## Compute Resources

### AWS Instance
Create EC2 instances with type safety and validation.
```ruby
instance = aws_instance(:web, {
  ami: "ami-12345678",
  instance_type: "t3.micro",
  subnet_id: subnet.id,
  vpc_security_group_ids: [sg.id],
  user_data: base64encode(file("user-data.sh")),
  tags: { Name: "web-server", Type: "application" }
})
```

### AWS Launch Template
Create launch templates for Auto Scaling Groups.
```ruby
template = aws_launch_template(:web, {
  name_prefix: "web-",
  image_id: "ami-12345678", 
  instance_type: "t3.micro",
  vpc_security_group_ids: [sg.id],
  user_data: base64encode(file("user-data.sh")),
  tag_specifications: [{
    resource_type: "instance",
    tags: { Name: "web-server", AutoScaled: "true" }
  }]
})
```

### AWS Auto Scaling Group
Create Auto Scaling Groups with launch templates.
```ruby
asg = aws_autoscaling_group(:web, {
  name: "web-asg",
  vpc_zone_identifier: [subnet.id],
  target_group_arns: [target_group.arn],
  health_check_type: "ELB",
  launch_template: {
    id: template.id,
    version: "$Latest"
  },
  min_size: 1,
  max_size: 5,
  desired_capacity: 2,
  tags: [{ 
    key: "Name", 
    value: "web-asg", 
    propagate_at_launch: true 
  }]
})
```

## Load Balancing Resources

### AWS Application Load Balancer
Create Application Load Balancers for HTTP/HTTPS traffic.
```ruby
alb = aws_lb(:web, {
  name: "web-alb",
  load_balancer_type: "application",
  subnets: [public_subnet_a.id, public_subnet_b.id],
  security_groups: [alb_sg.id],
  enable_deletion_protection: false,
  tags: { Name: "web-load-balancer", Type: "public" }
})
```

### AWS Target Group
Create target groups for load balancer health checks.
```ruby
target_group = aws_lb_target_group(:web, {
  name: "web-tg",
  port: 80,
  protocol: "HTTP",
  vpc_id: vpc.id,
  health_check: {
    enabled: true,
    healthy_threshold: 2,
    interval: 30,
    matcher: "200",
    path: "/health",
    port: "traffic-port",
    protocol: "HTTP",
    timeout: 5,
    unhealthy_threshold: 2
  },
  tags: { Name: "web-target-group" }
})
```

### AWS Load Balancer Listener
Create listeners to route traffic to target groups.
```ruby
listener = aws_lb_listener(:web_https, {
  load_balancer_arn: alb.arn,
  port: "443", 
  protocol: "HTTPS",
  ssl_policy: "ELBSecurityPolicy-TLS-1-2-2017-01",
  certificate_arn: "arn:aws:acm:region:account:certificate/cert-id",
  default_action: [{
    type: "forward",
    target_group_arn: target_group.arn
  }]
})
```

## Database Resources

### AWS RDS Instance
Create managed relational database instances.
```ruby
database = aws_db_instance(:app_db, {
  identifier: "app-database",
  engine: "postgres",
  engine_version: "13.7",
  instance_class: "db.t3.micro",
  allocated_storage: 20,
  storage_type: "gp2",
  db_name: "application",
  username: "appuser",
  password: "secure-password",
  vpc_security_group_ids: [db_sg.id],
  db_subnet_group_name: subnet_group.name,
  backup_retention_period: 7,
  backup_window: "03:00-04:00",
  maintenance_window: "sun:04:00-sun:05:00",
  skip_final_snapshot: true,
  tags: { Name: "app-database", Environment: "production" }
})
```

### AWS DB Subnet Group
Create database subnet groups for RDS placement.
```ruby
subnet_group = aws_db_subnet_group(:app, {
  name: "app-db-subnet-group",
  subnet_ids: [private_subnet_a.id, private_subnet_b.id],
  tags: { Name: "app-database-subnets" }
})
```

## Storage Resources

### AWS S3 Bucket  
Create S3 buckets with security and lifecycle configuration.
```ruby
bucket = aws_s3_bucket(:assets, {
  bucket: "myapp-assets-#{random_suffix}",
  tags: { Name: "application-assets", Type: "storage" }
})

# Bucket versioning
aws_s3_bucket_versioning(:assets, {
  bucket: bucket.id,
  versioning_configuration: {
    status: "Enabled"
  }
})

# Server-side encryption
aws_s3_bucket_server_side_encryption_configuration(:assets, {
  bucket: bucket.id,
  rule: [{
    apply_server_side_encryption_by_default: {
      sse_algorithm: "AES256"
    }
  }]
})
```

## Content Delivery

### AWS CloudFront Distribution
Create CloudFront distributions for global content delivery.
```ruby  
distribution = aws_cloudfront_distribution(:web, {
  origin: [{
    domain_name: alb.dns_name,
    origin_id: "web-alb",
    custom_origin_config: {
      http_port: 80,
      https_port: 443,
      origin_protocol_policy: "https-only"
    }
  }],
  enabled: true,
  default_cache_behavior: {
    allowed_methods: ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"],
    cached_methods: ["GET", "HEAD"],
    target_origin_id: "web-alb",
    forwarded_values: {
      query_string: false,
      cookies: { forward: "none" }
    },
    viewer_protocol_policy: "redirect-to-https"
  },
  restrictions: {
    geo_restriction: {
      restriction_type: "none"
    }
  },
  viewer_certificate: {
    cloudfront_default_certificate: true
  },
  tags: { Name: "web-distribution", Type: "cdn" }
})
```

## Monitoring & Logging

### AWS CloudWatch Log Group
Create log groups for application logging.
```ruby
log_group = aws_cloudwatch_log_group(:app, {
  name: "/aws/application/logs",
  retention_in_days: 7,
  tags: { Name: "application-logs", Type: "monitoring" }
})
```

### AWS CloudWatch Metric Alarm
Create CloudWatch alarms for monitoring.
```ruby
alarm = aws_cloudwatch_metric_alarm(:high_cpu, {
  alarm_name: "high-cpu-utilization",
  comparison_operator: "GreaterThanThreshold",
  evaluation_periods: "2",
  metric_name: "CPUUtilization",
  namespace: "AWS/EC2",
  period: "120",
  statistic: "Average", 
  threshold: "80",
  alarm_description: "This metric monitors ec2 cpu utilization",
  alarm_actions: [sns_topic.arn],
  dimensions: {
    AutoScalingGroupName: asg.name
  },
  tags: { Name: "high-cpu-alarm", Type: "monitoring" }
})
```

## Route 53 DNS

### AWS Route53 Zone
Create hosted zones for DNS management.
```ruby
zone = aws_route53_zone(:main, {
  name: "example.com",
  comment: "Main domain hosted zone",
  tags: { Name: "example.com-zone", Type: "dns" }
})
```

### AWS Route53 Record
Create DNS records within hosted zones.
```ruby
record = aws_route53_record(:web, {
  zone_id: zone.zone_id,
  name: "www.example.com",
  type: "A", 
  alias: {
    name: alb.dns_name,
    zone_id: alb.zone_id,
    evaluate_target_health: true
  }
})
```

## Usage Patterns

### Template Integration
All resource functions work seamlessly in templates:

```ruby
template :web_application do
  provider :aws do
    region "us-east-1"
  end
  
  # Create VPC and networking
  vpc = aws_vpc(:main, cidr_block: "10.0.0.0/16")
  
  subnet_a = aws_subnet(:public_a, {
    vpc_id: vpc.id,
    cidr_block: "10.0.1.0/24",
    availability_zone: "us-east-1a"
  })
  
  subnet_b = aws_subnet(:public_b, {
    vpc_id: vpc.id, 
    cidr_block: "10.0.2.0/24",
    availability_zone: "us-east-1b"
  })
  
  # Create security groups
  alb_sg = aws_security_group(:alb, {
    name: "alb-sg",
    description: "Application Load Balancer",
    vpc_id: vpc.id,
    ingress: [{
      from_port: 443,
      to_port: 443,
      protocol: "tcp",
      cidr_blocks: ["0.0.0.0/0"]
    }]
  })
  
  web_sg = aws_security_group(:web, {
    name: "web-sg", 
    description: "Web servers",
    vpc_id: vpc.id,
    ingress: [{
      from_port: 80,
      to_port: 80,
      protocol: "tcp",
      security_groups: [alb_sg.id]
    }]
  })
  
  # Create load balancer and target group
  alb = aws_lb(:web, {
    name: "web-alb",
    subnets: [subnet_a.id, subnet_b.id],
    security_groups: [alb_sg.id]
  })
  
  target_group = aws_lb_target_group(:web, {
    name: "web-tg",
    port: 80,
    protocol: "HTTP", 
    vpc_id: vpc.id
  })
  
  listener = aws_lb_listener(:web, {
    load_balancer_arn: alb.arn,
    port: "80",
    protocol: "HTTP",
    default_action: [{
      type: "forward",
      target_group_arn: target_group.arn
    }]
  })
  
  # Create launch template and auto scaling group
  launch_template = aws_launch_template(:web, {
    name_prefix: "web-",
    image_id: "ami-12345678",
    instance_type: "t3.micro",
    vpc_security_group_ids: [web_sg.id]
  })
  
  asg = aws_autoscaling_group(:web, {
    name: "web-asg",
    vpc_zone_identifier: [subnet_a.id, subnet_b.id], 
    target_group_arns: [target_group.arn],
    launch_template: {
      id: launch_template.id,
      version: "$Latest"
    },
    min_size: 2,
    max_size: 6,
    desired_capacity: 2
  })
  
  # Outputs
  output :load_balancer_dns do
    value alb.dns_name
    description "Load balancer DNS name"
  end
  
  output :vpc_id do
    value vpc.id
    description "VPC identifier"
  end
end
```

### Error Handling
All resource functions provide comprehensive validation:

```ruby
# Type validation
aws_vpc(:invalid, cidr_block: 123)  # Raises Dry::Types::TypeError

# Constraint validation  
aws_vpc(:invalid, cidr_block: "10.0.0.0/8")  # Raises constraint error

# Required attribute validation
aws_instance(:invalid, {})  # Raises missing ami error
```

### Resource References
All resources return `ResourceReference` objects with terraform outputs and computed properties:

```ruby
vpc = aws_vpc(:main, cidr_block: "10.0.0.0/16")

# Terraform references
vpc.id                          # "${aws_vpc.main.id}" 
vpc.cidr_block                  # "${aws_vpc.main.cidr_block}"
vpc.default_security_group_id   # "${aws_vpc.main.default_security_group_id}"

# Computed properties
vpc.is_private_cidr?            # true (RFC1918 detection)
vpc.estimated_subnet_capacity   # 256 (for /24 subnets)
```

This resource system provides the foundation for building scalable, type-safe infrastructure with Pangea.