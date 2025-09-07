# AWS EC2 Instance Implementation Documentation

## Overview

This directory contains the implementation for the `aws_instance` resource function, providing type-safe creation and management of AWS Elastic Compute Cloud (EC2) instances through terraform-synthesizer integration.

## Implementation Architecture

### Core Components

#### 1. Resource Function (`resource.rb`)
The main `aws_instance` function that:
- Accepts a symbol name and attributes hash
- Validates attributes using dry-struct types
- Generates terraform resource blocks via terraform-synthesizer
- Returns ResourceReference with computed outputs and properties

#### 2. Type Definitions (`types.rb`)
InstanceAttributes dry-struct defining:
- Required attributes: `ami`, `instance_type`
- Optional attributes: `subnet_id`, `key_name`, `user_data`, `iam_instance_profile`
- Storage configuration with root and additional EBS volumes
- Instance behavior settings

#### 3. Documentation
- **CLAUDE.md** (this file): Implementation details for developers
- **README.md**: User-facing documentation with examples

## Technical Implementation Details

### Instance Configuration

#### Core Attributes
- **AMI**: Amazon Machine Image ID (required)
- **Instance Type**: Compute capacity (t3.micro, m5.large, etc.)
- **Network**: Subnet, security groups, availability zone
- **Access**: Key pair for SSH, IAM instance profile for permissions

#### Storage Configuration
- **Root Block Device**: Boot volume configuration
- **EBS Block Devices**: Additional data volumes
- **Storage Types**: gp2, gp3, io1, io2 with appropriate IOPS/throughput

### Type Validation Logic

```ruby
class InstanceAttributes < Dry::Struct
  # Core validation
  attribute :ami, Types::String
  attribute :instance_type, Types::String
  
  # Storage validation
  attribute? :root_block_device, Types::Hash.schema(
    volume_type?: Types::String.enum("standard", "gp2", "gp3", "io1", "io2"),
    iops?: Types::Integer.optional,
    throughput?: Types::Integer.optional
  )
  
  # Custom validation
  def self.new(attributes = {})
    attrs = super(attributes)
    
    # User data exclusivity
    if attrs.user_data && attrs.user_data_base64
      raise Dry::Struct::Error, "Cannot specify both 'user_data' and 'user_data_base64'"
    end
    
    # IOPS only for io1/io2
    if attrs.root_block_device && attrs.root_block_device[:iops]
      if !%w[io1 io2].include?(attrs.root_block_device[:volume_type])
        raise Dry::Struct::Error, "IOPS can only be specified for io1 or io2"
      end
    end
    
    attrs
  end
end
```

### Terraform Synthesis

The resource function generates terraform JSON through terraform-synthesizer:

```ruby
resource(:aws_instance, name) do
  # Required
  ami instance_attrs.ami
  instance_type instance_attrs.instance_type
  
  # Network
  subnet_id instance_attrs.subnet_id if instance_attrs.subnet_id
  vpc_security_group_ids instance_attrs.vpc_security_group_ids if instance_attrs.vpc_security_group_ids.any?
  
  # Storage
  if instance_attrs.root_block_device
    root_block_device do
      volume_type device[:volume_type]
      volume_size device[:volume_size]
      encrypted device[:encrypted]
    end
  end
  
  # Additional volumes
  instance_attrs.ebs_block_device.each do |ebs_device|
    ebs_block_device do
      device_name ebs_device[:device_name]
      volume_type ebs_device[:volume_type]
      volume_size ebs_device[:volume_size]
    end
  end
  
  # Behavior
  monitoring instance_attrs.monitoring
  ebs_optimized instance_attrs.ebs_optimized
  disable_api_termination instance_attrs.disable_api_termination
end
```

### ResourceReference Return Value

The function returns a ResourceReference providing:

#### Terraform Outputs
- `id`: Instance ID
- `arn`: Instance ARN
- `public_ip`: Public IP address (if assigned)
- `private_ip`: Private IP address
- `public_dns`: Public DNS name
- `private_dns`: Private DNS name
- `instance_state`: Current state
- `subnet_id`: Subnet placement
- `availability_zone`: AZ placement
- `key_name`: SSH key pair name
- `vpc_security_group_ids`: Security groups

#### Computed Properties
- `instance_family`: Instance type family (t3, m5, etc.)
- `instance_size`: Instance size (micro, small, large, etc.)
- `supports_ebs_optimization`: Whether type supports EBS optimization
- `will_have_public_ip`: Prediction of public IP assignment
- `estimated_hourly_cost`: Rough cost estimate

## Integration Patterns

### 1. Basic Web Server
```ruby
template :web_server do
  # Create instance
  web_instance = aws_instance(:web, {
    ami: "ami-0c02fb55956c7d316",  # Amazon Linux 2
    instance_type: "t3.micro",
    subnet_id: public_subnet.id,
    vpc_security_group_ids: [web_sg.id],
    key_name: "my-key-pair",
    associate_public_ip_address: true,
    
    user_data: <<~USERDATA,
      #!/bin/bash
      yum update -y
      yum install -y httpd
      systemctl start httpd
      systemctl enable httpd
    USERDATA
    
    tags: {
      Name: "web-server",
      Environment: "production"
    }
  })
end
```

### 2. Application Server with IAM Role
```ruby
template :app_server do
  # Create IAM instance profile first
  instance_profile = aws_iam_instance_profile(:app_profile, {
    name: "app-instance-profile",
    role: app_role.name
  })
  
  # Application instance
  app_instance = aws_instance(:app, {
    ami: data.aws_ami.ubuntu.id,
    instance_type: "m5.large",
    subnet_id: private_subnet.id,
    vpc_security_group_ids: [app_sg.id],
    iam_instance_profile: instance_profile.name,
    
    root_block_device: {
      volume_type: "gp3",
      volume_size: 50,
      encrypted: true,
      delete_on_termination: true
    },
    
    ebs_block_device: [{
      device_name: "/dev/sdf",
      volume_type: "gp3",
      volume_size: 100,
      encrypted: true,
      delete_on_termination: false
    }],
    
    monitoring: true,
    ebs_optimized: true,
    
    tags: {
      Name: "app-server",
      Application: "backend",
      Tier: "application"
    }
  })
end
```

### 3. High-Performance Database Instance
```ruby
template :database_instance do
  # High-performance database server
  db_instance = aws_instance(:database, {
    ami: "ami-database-optimized",
    instance_type: "r5.2xlarge",
    subnet_id: private_subnet_a.id,
    vpc_security_group_ids: [db_sg.id],
    
    root_block_device: {
      volume_type: "gp3",
      volume_size: 100,
      throughput: 250,  # gp3 throughput
      encrypted: true
    },
    
    ebs_block_device: [
      {
        device_name: "/dev/sdf",
        volume_type: "io2",
        volume_size: 1000,
        iops: 20000,
        encrypted: true,
        kms_key_id: kms_key.arn
      },
      {
        device_name: "/dev/sdg",
        volume_type: "io2", 
        volume_size: 1000,
        iops: 20000,
        encrypted: true,
        kms_key_id: kms_key.arn
      }
    ],
    
    disable_api_termination: true,
    monitoring: true,
    ebs_optimized: true,
    
    tags: {
      Name: "database-server",
      Type: "primary-database",
      CriticalInfrastructure: "true"
    }
  })
end
```

## Error Handling and Validation

### Common Validation Errors

#### 1. User Data Conflicts
```ruby
# ERROR: Both user_data formats
aws_instance(:bad, {
  ami: "ami-12345",
  instance_type: "t3.micro",
  user_data: "#!/bin/bash\necho hello",
  user_data_base64: "IyEvYmluL2Jhc2g..."  # Can't use both
})
# Raises: Dry::Struct::Error: "Cannot specify both 'user_data' and 'user_data_base64'"
```

#### 2. Storage Configuration
```ruby
# ERROR: IOPS on wrong volume type
aws_instance(:bad_storage, {
  ami: "ami-12345",
  instance_type: "t3.micro",
  root_block_device: {
    volume_type: "gp3",
    iops: 10000  # IOPS only for io1/io2
  }
})
# Raises: Dry::Struct::Error: "IOPS can only be specified for io1 or io2"

# ERROR: Throughput on wrong volume type
aws_instance(:bad_throughput, {
  ami: "ami-12345",
  instance_type: "t3.micro",
  root_block_device: {
    volume_type: "gp2",
    throughput: 250  # Throughput only for gp3
  }
})
# Raises: Dry::Struct::Error: "Throughput can only be specified for gp3"
```

## Testing Strategy

### Unit Tests
```ruby
RSpec.describe Pangea::Resources::AWS do
  describe "#aws_instance" do
    it "creates EC2 instance with valid configuration" do
      instance_ref = aws_instance(:test, {
        ami: "ami-12345678",
        instance_type: "t3.micro"
      })
      
      expect(instance_ref).to be_a(ResourceReference)
      expect(instance_ref.type).to eq('aws_instance')
      expect(instance_ref.instance_family).to eq('t3')
      expect(instance_ref.instance_size).to eq('micro')
    end
    
    it "validates user data exclusivity" do
      expect {
        aws_instance(:test, {
          ami: "ami-12345",
          instance_type: "t3.micro",
          user_data: "data",
          user_data_base64: "base64data"
        })
      }.to raise_error(Dry::Struct::Error, /Cannot specify both/)
    end
    
    it "calculates cost estimates" do
      instance_ref = aws_instance(:test, {
        ami: "ami-12345",
        instance_type: "m5.xlarge"
      })
      
      expect(instance_ref.estimated_hourly_cost).to eq(0.192)
    end
  end
end
```

## Security Best Practices

### 1. Network Security
- Place instances in appropriate subnets (public/private)
- Use security groups with least privilege
- Avoid public IPs unless necessary
- Use VPC endpoints for AWS services

### 2. Access Control
- Always use key pairs for SSH access
- Use IAM instance profiles instead of embedding credentials
- Enable termination protection for critical instances
- Use Systems Manager Session Manager instead of SSH when possible

### 3. Storage Security
- Always encrypt EBS volumes
- Use customer-managed KMS keys for sensitive data
- Enable EBS snapshots for backup
- Set appropriate delete_on_termination flags

### 4. Monitoring
- Enable detailed monitoring for production
- Use CloudWatch logs agent
- Set up instance status checks
- Configure auto-recovery for critical instances

## Future Enhancements

### 1. Spot Instance Support
- Spot instance requests
- Spot fleet integration
- Price optimization

### 2. Advanced Networking
- Multiple network interfaces
- Elastic IP associations
- IPv6 support

### 3. Placement Strategies
- Placement groups
- Dedicated hosts
- Capacity reservations

### 4. Instance Lifecycle
- Instance refresh patterns
- Blue/green deployment helpers
- Automated patching integration

This implementation provides comprehensive EC2 instance management within the Pangea resource system, emphasizing security, flexibility, and ease of use.