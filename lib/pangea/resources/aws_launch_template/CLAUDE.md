# AWS Launch Template Resource Implementation

## Overview

The `aws_launch_template` resource creates an AWS EC2 Launch Template that provides a versioned template for launching EC2 instances. Launch templates enable you to store launch parameters so you can quickly launch instances with predefined configurations. They support all EC2 features and are the recommended way to launch instances.

## Type Safety Implementation

### Attributes Structure

```ruby
class LaunchTemplateAttributes < Dry::Struct
  attribute :name, String.optional                    # Template name
  attribute :name_prefix, String.optional              # Name prefix (conflicts with name)
  attribute :description, String.optional              # Template description
  attribute :launch_template_data, LaunchTemplateData  # Launch configuration
  attribute :tags, AwsTags                            # Resource tags
end

class LaunchTemplateData < Dry::Struct
  # Core configuration
  attribute :image_id, String.optional
  attribute :instance_type, Ec2InstanceType.optional
  attribute :key_name, String.optional
  
  # Security
  attribute :iam_instance_profile, IamInstanceProfile.optional
  attribute :security_group_ids, Array.of(String)
  attribute :vpc_security_group_ids, Array.of(String)
  
  # Advanced configuration
  attribute :user_data, String.optional
  attribute :monitoring, Hash.optional
  attribute :block_device_mappings, Array.of(BlockDeviceMapping)
  attribute :network_interfaces, Array.of(NetworkInterface)
  attribute :tag_specifications, Array.of(TagSpecification)
end
```

### Key Design Decisions

1. **Name vs Name Prefix**:
   - Mutually exclusive - cannot specify both
   - `name`: Fixed template name
   - `name_prefix`: AWS generates unique name with prefix
   - Validation ensures only one is specified

2. **Nested Type Safety**:
   - `IamInstanceProfile`: Supports both string (name) and hash (arn/name)
   - `BlockDeviceMapping`: Full EBS configuration support
   - `NetworkInterface`: Complete network configuration
   - `TagSpecification`: Tags for created resources

3. **Flexible Configuration**:
   - All launch data attributes are optional
   - Supports partial templates for flexibility
   - Can be used with Auto Scaling Groups and EC2 Fleet

4. **Complex Nested Structures**:
   - Block devices with EBS settings
   - Network interfaces with security groups
   - Tag specifications for different resource types

## Resource Function Pattern

The `aws_launch_template` function handles complex nested structures:

```ruby
def aws_launch_template(name, attributes = {})
  # 1. Validate attributes with dry-struct
  lt_attrs = Types::LaunchTemplateAttributes.new(attributes)
  
  # 2. Generate Terraform resource via synthesizer
  resource(:aws_launch_template, name) do
    # Handle name/name_prefix
    name lt_attrs.name if lt_attrs.name
    name_prefix lt_attrs.name_prefix if lt_attrs.name_prefix
    
    # Complex nested launch_template_data block
    launch_template_data do
      # Basic settings
      image_id data.image_id if data.image_id
      
      # Nested blocks for complex structures
      data.block_device_mappings.each do |bdm|
        block_device_mappings do
          # Block device configuration
        end
      end
    end
  end
  
  # 3. Return ResourceReference with outputs
  ResourceReference.new(
    type: 'aws_launch_template',
    name: name,
    outputs: { id, arn, latest_version, default_version, name }
  )
end
```

## Integration with Terraform Synthesizer

The resource generation handles multiple levels of nesting:

```ruby
resource(:aws_launch_template, name) do
  launch_template_data do
    # Simple attributes
    image_id "ami-12345678"
    instance_type "t3.micro"
    
    # Nested IAM profile
    iam_instance_profile do
      name "my-instance-profile"
    end
    
    # Multiple block devices
    block_device_mappings do
      device_name "/dev/sda1"
      ebs do
        volume_size 100
        volume_type "gp3"
        encrypted true
      end
    end
    
    # Tag specifications for instances
    tag_specifications do
      resource_type "instance"
      tags do
        Name "web-server"
        Environment "production"
      end
    end
  end
end
```

## Common Usage Patterns

### 1. Basic Web Server Template
```ruby
lt = aws_launch_template(:web, {
  name: "web-server-template",
  launch_template_data: {
    image_id: "ami-12345678",
    instance_type: "t3.micro",
    key_name: "my-key",
    vpc_security_group_ids: [web_sg.id],
    user_data: Base64.encode64(startup_script)
  }
})
```

### 2. Auto Scaling Template with Monitoring
```ruby
lt = aws_launch_template(:asg, {
  name_prefix: "asg-template-",
  launch_template_data: {
    image_id: latest_ami.id,
    instance_type: "t3.small",
    iam_instance_profile: { name: role.name },
    monitoring: { enabled: true },
    tag_specifications: [{
      resource_type: "instance",
      tags: { 
        Name: "asg-instance",
        ManagedBy: "auto-scaling"
      }
    }]
  }
})
```

### 3. Template with Custom Block Devices
```ruby
lt = aws_launch_template(:database, {
  name: "database-template",
  launch_template_data: {
    image_id: "ami-12345678",
    instance_type: "r5.large",
    block_device_mappings: [
      {
        device_name: "/dev/sda1",
        ebs: {
          volume_size: 50,
          volume_type: "gp3",
          encrypted: true
        }
      },
      {
        device_name: "/dev/sdf",
        ebs: {
          volume_size: 1000,
          volume_type: "io2",
          iops: 10000,
          encrypted: true,
          delete_on_termination: false
        }
      }
    ]
  }
})
```

### 4. Template with Network Configuration
```ruby
lt = aws_launch_template(:custom_network, {
  name: "custom-network-template",
  launch_template_data: {
    image_id: "ami-12345678",
    instance_type: "t3.micro",
    network_interfaces: [{
      device_index: 0,
      subnet_id: private_subnet.id,
      groups: [app_sg.id],
      delete_on_termination: true,
      associate_public_ip_address: false
    }]
  }
})
```

## Testing Considerations

1. **Type Validation**:
   - Test name/name_prefix mutual exclusivity
   - Test nested structure validation
   - Test enum validations (instance types, volume types)
   - Test optional vs required fields

2. **Nested Structure Generation**:
   - Verify IAM instance profile formats
   - Test block device mapping generation
   - Test network interface configuration
   - Test tag specification nesting

3. **Terraform Generation**:
   - Verify complex nested block syntax
   - Test conditional attribute inclusion
   - Test array handling for multiple items

4. **Edge Cases**:
   - Empty launch_template_data
   - Mixed security group types
   - Multiple network interfaces

## Future Enhancements

1. **Enhanced Validation**:
   - AMI ID format validation
   - Cross-reference validation (subnet/security group compatibility)
   - Instance type to AMI compatibility

2. **Computed Properties**:
   - Estimated hourly cost based on instance type
   - Storage cost estimation
   - Network bandwidth capabilities

3. **Helper Methods**:
   - Generate user data from templates
   - Version management helpers
   - Default version setter

4. **Template Composition**:
   - Merge multiple template configurations
   - Template inheritance patterns
   - Conditional configuration based on environment