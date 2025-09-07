# Auto Scaling Web Servers Component

A production-ready Auto Scaling Group component for web servers with CPU-based scaling, health checks, and comprehensive monitoring.

## Features

- **Auto Scaling**: CPU-based scaling with configurable policies
- **Launch Template**: Modern EC2 launch configuration
- **Health Checks**: EC2 and ELB health check integration
- **Load Balancer Integration**: Automatic target group attachment
- **Security**: Encrypted EBS volumes and IMDSv2 enforcement
- **Monitoring**: CloudWatch alarms and detailed metrics
- **Cost Optimization**: Mixed instance types and Spot Fleet support

## Usage

### Basic Web Server Auto Scaling Group

```ruby
# Create VPC and subnets first
vpc = aws_vpc(:main, { cidr_block: "10.0.0.0/16" })
public_subnet_1 = aws_subnet(:public_1, { 
  vpc_id: vpc.id, 
  cidr_block: "10.0.1.0/24",
  availability_zone: "us-east-1a"
})
public_subnet_2 = aws_subnet(:public_2, { 
  vpc_id: vpc.id, 
  cidr_block: "10.0.2.0/24",
  availability_zone: "us-east-1b"
})

# Create security group
web_sg = aws_security_group(:web_servers, {
  name: "web-servers-sg",
  description: "Security group for web servers",
  vpc_id: vpc.id,
  ingress: [
    { from_port: 80, to_port: 80, protocol: "tcp", cidr_blocks: ["10.0.0.0/16"] },
    { from_port: 443, to_port: 443, protocol: "tcp", cidr_blocks: ["10.0.0.0/16"] },
    { from_port: 22, to_port: 22, protocol: "tcp", cidr_blocks: ["10.0.0.0/16"] }
  ]
})

# Create Auto Scaling Web Servers
web_servers = auto_scaling_web_servers(:web_servers, {
  vpc_ref: vpc,
  subnet_refs: [public_subnet_1, public_subnet_2],
  security_group_refs: [web_sg],
  
  # Instance configuration
  ami_id: "ami-0abcdef1234567890",
  instance_type: "t3.micro",
  key_name: "my-key-pair",
  
  # Auto Scaling configuration
  min_size: 2,
  max_size: 10,
  desired_capacity: 3,
  
  # Health checks
  health_check_type: "ELB",
  health_check_grace_period: 300,
  
  # CPU-based scaling
  enable_cpu_scaling: true,
  cpu_target_value: 70.0,
  
  tags: {
    Environment: "production",
    Application: "web-app"
  }
})
```

### Advanced Configuration with Custom Scaling Policies

```ruby
advanced_asg = auto_scaling_web_servers(:advanced_web, {
  vpc_ref: vpc,
  subnet_refs: [private_subnet_1, private_subnet_2, private_subnet_3],
  security_group_refs: [web_sg, monitoring_sg],
  
  # Instance configuration
  ami_id: "ami-0abcdef1234567890",
  instance_type: "c5.large",
  key_name: "production-key",
  iam_instance_profile: "WebServerInstanceProfile",
  
  # Custom user data for web server setup
  user_data: base64encode(<<~SCRIPT
    #!/bin/bash
    yum update -y
    yum install -y httpd php mysql
    systemctl start httpd
    systemctl enable httpd
    
    # Configure PHP application
    cd /var/www/html
    wget https://github.com/myapp/releases/latest/download/app.tar.gz
    tar -xzf app.tar.gz
    
    # Set up health check endpoint
    echo '<?php echo "OK"; ?>' > /var/www/html/health.php
    
    # Configure CloudWatch agent
    /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
      -a fetch-config -m ec2 -c ssm:CloudWatch-Config -s
    
    # Signal Auto Scaling success
    /opt/aws/bin/cfn-signal -e $? --stack ${AWS::StackName} --resource AutoScalingGroup --region ${AWS::Region}
  SCRIPT
  ),
  
  # Auto Scaling configuration
  min_size: 3,
  max_size: 20,
  desired_capacity: 5,
  default_cooldown: 300,
  
  # Advanced health checks
  health_check_type: "ELB",
  health_check_grace_period: 600,
  
  # Custom storage configuration
  block_device_mappings: [{
    device_name: "/dev/xvda",
    volume_type: "gp3",
    volume_size: 30,
    iops: 3000,
    throughput: 125,
    encrypted: true,
    delete_on_termination: true
  }],
  
  # Multiple scaling policies
  enable_cpu_scaling: false,  # Disable default CPU scaling
  scaling_policies: [
    {
      policy_type: "TargetTrackingScaling",
      target_value: 75.0,
      metric_type: "ASGAverageCPUUtilization",
      scale_out_cooldown: 300,
      scale_in_cooldown: 600
    },
    {
      policy_type: "TargetTrackingScaling", 
      target_value: 1000.0,
      metric_type: "ALBRequestCountPerTarget",
      target_group_arn: target_group.arn,
      scale_out_cooldown: 180,
      scale_in_cooldown: 300
    }
  ],
  
  # Termination policies
  termination_policies: ["OldestInstance", "Default"],
  
  # Enhanced monitoring
  monitoring: {
    enabled: true,
    granularity: "1Minute",
    enabled_metrics: [
      "GroupMinSize", "GroupMaxSize", "GroupDesiredCapacity",
      "GroupInServiceInstances", "GroupPendingInstances",
      "GroupStandbyInstances", "GroupTerminatingInstances",
      "GroupTotalInstances"
    ]
  },
  
  # Security configuration
  metadata_options: {
    http_endpoint: "enabled",
    http_tokens: "required",
    http_put_response_hop_limit: 1,
    instance_metadata_tags: "enabled"
  }
})
```

### Mixed Instance Types for Cost Optimization

```ruby
cost_optimized_asg = auto_scaling_web_servers(:cost_optimized, {
  vpc_ref: vpc,
  subnet_refs: [private_subnet_1, private_subnet_2],
  security_group_refs: [web_sg],
  
  ami_id: "ami-0abcdef1234567890",
  instance_type: "t3.medium",  # Will be overridden by mixed instances policy
  
  # Enable mixed instances for cost optimization
  enable_mixed_instances: true,
  mixed_instances_policy: {
    instances_distribution: {
      on_demand_allocation_strategy: "prioritized",
      on_demand_base_capacity: 2,
      on_demand_percentage_above_base_capacity: 25,
      spot_allocation_strategy: "capacity-optimized",
      spot_instance_pools: 4,
      spot_max_price: "0.05"
    },
    launch_template: {
      launch_template_specification: {
        launch_template_id: launch_template.id,
        version: "$Latest"
      },
      overrides: [
        { instance_type: "t3.medium", weighted_capacity: "1" },
        { instance_type: "t3.large", weighted_capacity: "2" },
        { instance_type: "c5.large", weighted_capacity: "2" },
        { instance_type: "m5.large", weighted_capacity: "2" }
      ]
    }
  },
  
  min_size: 2,
  max_size: 10,
  desired_capacity: 4
})
```

### Auto Scaling with Warm Pool

```ruby
warm_pool_asg = auto_scaling_web_servers(:warm_pool, {
  vpc_ref: vpc,
  subnet_refs: [private_subnet_1, private_subnet_2],
  security_group_refs: [web_sg],
  
  ami_id: "ami-0abcdef1234567890",
  instance_type: "t3.small",
  
  min_size: 2,
  max_size: 8,
  desired_capacity: 3,
  
  # Enable warm pool for faster scaling
  enable_warm_pool: true,
  warm_pool_config: {
    pool_state: "Hibernated",  # Hibernate instances to save costs
    min_size: 2,
    max_group_prepared_capacity: 5,
    instance_reuse_policy: {
      reuse_on_scale_in: true
    }
  }
})
```

## Component Outputs

The component returns a `ComponentReference` with the following outputs:

```ruby
asg.outputs[:asg_name]                   # Auto Scaling Group name
asg.outputs[:asg_arn]                    # Auto Scaling Group ARN
asg.outputs[:launch_template_id]         # Launch Template ID
asg.outputs[:min_size]                   # Minimum capacity
asg.outputs[:max_size]                   # Maximum capacity
asg.outputs[:desired_capacity]           # Desired capacity
asg.outputs[:target_group_arns]          # Associated target group ARNs
asg.outputs[:security_features]          # Array of security features
asg.outputs[:availability_zones]         # Deployment availability zones
asg.outputs[:estimated_monthly_cost]     # Estimated monthly cost
```

## Security Features

- **Encrypted EBS Volumes**: All volumes encrypted by default
- **IMDSv2 Required**: Instance Metadata Service v2 enforcement
- **Security Groups**: Network-level access control
- **IAM Instance Profiles**: Proper IAM roles and permissions
- **Session Manager**: SSM Session Manager for secure access
- **CloudWatch Monitoring**: Comprehensive instance monitoring

## Scaling Policies

### Target Tracking Scaling
- **CPU Utilization**: Scale based on average CPU usage
- **Network I/O**: Scale based on network traffic
- **ALB Request Count**: Scale based on requests per target

### Step Scaling
- **Graduated Response**: Different scaling amounts based on alarm magnitude
- **Fast Response**: Quick scaling for sudden load changes

### Simple Scaling
- **Fixed Adjustments**: Add or remove fixed number of instances
- **Predictable Scaling**: Simple scaling for predictable workloads

## Monitoring and Alerting

The component automatically creates CloudWatch alarms for:

- **CPU Utilization**: High CPU usage alerts
- **Instance Count**: Minimum instance threshold alerts
- **Network Utilization**: High network usage alerts
- **System Status**: Instance health monitoring

## Best Practices

1. **Multi-AZ Deployment**: Distribute instances across availability zones
2. **Health Check Grace Period**: Allow sufficient time for instance initialization
3. **Scaling Cooldowns**: Prevent thrashing with appropriate cooldown periods
4. **Instance Types**: Choose appropriate instance types for your workload
5. **Spot Instances**: Use Spot instances for cost-sensitive workloads
6. **Warm Pools**: Use warm pools for predictable scaling patterns

## Integration with Other Components

The ASG component works seamlessly with:

- **Application Load Balancers**: Automatic target registration
- **Network Load Balancers**: Layer 4 load balancing
- **Launch Templates**: Modern instance configuration
- **CloudWatch**: Metrics and alerting
- **Systems Manager**: Patch management and configuration

## Cost Optimization Features

- **Mixed Instance Types**: Diversify instance types for better pricing
- **Spot Instances**: Use Spot instances for significant cost savings
- **Warm Pools**: Reduce instance launch times
- **Intelligent Scaling**: Efficient scaling based on actual demand
- **Instance Rightsizing**: Automatic recommendations for optimal instance types