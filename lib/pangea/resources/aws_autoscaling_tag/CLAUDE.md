# AWS Auto Scaling Tag Implementation

## Overview

The `aws_autoscaling_tag` resource creates and manages tags for Auto Scaling Groups with precise control over tag propagation to launched instances. This implementation provides comprehensive validation for tag formats, limits, and AWS constraints while enabling flexible tagging strategies for cost allocation, compliance, and operational management.

## Key Features

### Tag Propagation Control
- **Instance-Level Tags**: `propagate_at_launch: true` applies tags to launched instances
- **ASG-Only Tags**: `propagate_at_launch: false` applies tags only to the Auto Scaling Group
- **Flexible Propagation**: Mixed propagation strategies within the same tag set

### Comprehensive Validation
- **AWS Tag Constraints**: Key length (128 chars), value length (256 chars), AWS prefix restrictions
- **Tag Limits**: Maximum 50 tags per Auto Scaling Group
- **Duplicate Prevention**: Ensures unique tag keys within the same resource
- **Required Fields**: Validates all tag specification components

### Rich Query Interface
- **Standard Tag Queries**: Built-in queries for common tags (Environment, Name, Owner, etc.)
- **Propagation Queries**: Methods to analyze tag propagation patterns
- **Tag Analytics**: Count, filter, and analyze tag configurations

## Implementation Details

### Type System Architecture

```ruby
class AutoScalingTagAttributes < Dry::Struct
  # ASG name validation
  attribute :autoscaling_group_name, Resources::Types::String
  
  # Tag array with minimum constraint
  attribute :tags, Resources::Types::Array.of(TagSpecification)
    .constrained(min_size: 1)
  
  class TagSpecification < Dry::Struct
    attribute :key, Resources::Types::String
    attribute :value, Resources::Types::String  
    attribute :propagate_at_launch, Resources::Types::Bool
  end
end
```

### Tag Validation System

Comprehensive validation ensuring AWS compliance:

```ruby
def self.validate_tags(tags)
  tag_keys = []
  
  tags.each do |tag|
    key = tag_hash[:key]
    
    # Key validation
    if key.length > 128
      raise Dry::Struct::Error, "Tag key cannot exceed 128 characters: #{key}"
    end
    
    if key.start_with?('aws:')
      raise Dry::Struct::Error, "Tag key cannot start with 'aws:' prefix: #{key}"
    end
    
    # Value validation  
    if value.length > 256
      raise Dry::Struct::Error, "Tag value cannot exceed 256 characters for key '#{key}'"
    end
    
    # Duplicate key detection
    if tag_keys.include?(key)
      raise Dry::Struct::Error, "Duplicate tag key not allowed: #{key}"
    end
    
    tag_keys << key
  end
  
  # AWS tag limit validation
  if tags.length > 50
    raise Dry::Struct::Error, "Cannot exceed 50 tags per Auto Scaling Group"
  end
end
```

**Validation Features:**
- **AWS Prefix Protection**: Prevents use of reserved `aws:` prefix
- **Length Constraints**: Enforces AWS character limits
- **Uniqueness**: Ensures no duplicate tag keys
- **Resource Limits**: Enforces 50-tag limit per Auto Scaling Group

### Individual Tag Resource Generation

The implementation creates separate Terraform resources for each tag:

```ruby
def aws_autoscaling_tag(name, attributes)
  validated_attributes = Types::AutoScalingTagAttributes.new(attributes)
  
  tag_resources = []
  
  validated_attributes.tags.each_with_index do |tag_spec, index|
    tag_name = :"#{name}_#{tag_spec.key.downcase.gsub(/[^a-z0-9]/, '_')}"
    
    resource :aws_autoscaling_group_tag, tag_name do
      autoscaling_group_name validated_attributes.autoscaling_group_name
      
      tag do
        key tag_spec.key
        value tag_spec.value
        propagate_at_launch tag_spec.propagate_at_launch
      end
    end
    
    tag_resources << ResourceReference.new(
      type: :aws_autoscaling_group_tag,
      name: tag_name,
      attributes: tag_spec,
      terraform_resource: "aws_autoscaling_group_tag.#{tag_name}"
    )
  end
end
```

**Implementation Benefits:**
- **Individual Management**: Each tag is a separate Terraform resource
- **Selective Updates**: Change individual tags without affecting others
- **Clear Resource Names**: Generated names reflect tag keys
- **Resource References**: Full reference tracking for each tag

## Query Method Implementation

Rich query interface for operational and analytical purposes:

```ruby
# Propagation analysis
def has_propagated_tags?
  tags.any?(&:propagate_at_launch)
end

def all_tags_propagated?
  tags.all?(&:propagate_at_launch)
end

def propagated_tag_count
  tags.count(&:propagate_at_launch)
end

# Tag analysis
def has_tag?(key)
  tag_keys.include?(key)
end

def tag_value(key)
  tag = tags.find { |t| t.key == key }
  tag&.value
end

# Standard tag queries
def has_environment_tag?
  has_tag?('Environment') || has_tag?('environment')
end

def environment
  tag_value('Environment') || tag_value('environment')
end
```

These methods enable:
- **Conditional Logic**: Make decisions based on tag presence and values
- **Operational Queries**: Analyze tagging patterns and compliance
- **Standard Tag Access**: Easy access to common organizational tags

## Production Integration Patterns

### Multi-Tier Application Tagging

```ruby
# Web tier with comprehensive tagging
aws_autoscaling_tag(:web_tier_tags, {
  autoscaling_group_name: ref(:aws_autoscaling_group, :web_servers, :name),
  tags: [
    # Environment and application identification
    { key: "Environment", value: "production", propagate_at_launch: true },
    { key: "Application", value: "ecommerce-platform", propagate_at_launch: true },
    { key: "Component", value: "web-tier", propagate_at_launch: true },
    { key: "Version", value: "v2.1.0", propagate_at_launch: true },
    
    # Cost allocation
    { key: "CostCenter", value: "engineering-platform", propagate_at_launch: true },
    { key: "Project", value: "ecommerce-modernization", propagate_at_launch: true },
    { key: "Owner", value: "frontend-team@company.com", propagate_at_launch: true },
    
    # Operational metadata
    { key: "BackupRequired", value: "no", propagate_at_launch: true },
    { key: "MonitoringLevel", value: "standard", propagate_at_launch: true },
    { key: "LogRetention", value: "30days", propagate_at_launch: true },
    
    # ASG-specific tags
    { key: "TerraformManaged", value: "true", propagate_at_launch: false },
    { key: "AutoScalingPolicy", value: "cpu-based", propagate_at_launch: false }
  ]
})

# Database tier with enhanced security tags
aws_autoscaling_tag(:database_tier_tags, {
  autoscaling_group_name: ref(:aws_autoscaling_group, :database_servers, :name),
  tags: [
    # Core identification
    { key: "Environment", value: "production", propagate_at_launch: true },
    { key: "Component", value: "database-tier", propagate_at_launch: true },
    
    # Security and compliance
    { key: "DataClassification", value: "confidential", propagate_at_launch: true },
    { key: "EncryptionRequired", value: "yes", propagate_at_launch: true },
    { key: "BackupRequired", value: "yes", propagate_at_launch: true },
    { key: "PCI-DSS-Scope", value: "yes", propagate_at_launch: true },
    
    # Operational requirements
    { key: "DisasterRecovery", value: "tier1", propagate_at_launch: true },
    { key: "MaintenanceWindow", value: "sunday-3am-utc", propagate_at_launch: false },
    { key: "AlertingLevel", value: "critical", propagate_at_launch: false }
  ]
})
```

### Cost Management Tagging Strategy

```ruby
# Comprehensive cost allocation tagging
aws_autoscaling_tag(:cost_allocation_tags, {
  autoscaling_group_name: ref(:aws_autoscaling_group, :api_services, :name),
  tags: [
    # Hierarchical cost structure
    { key: "Department", value: "engineering", propagate_at_launch: true },
    { key: "Team", value: "backend-platform", propagate_at_launch: true },
    { key: "Project", value: "customer-api-v3", propagate_at_launch: true },
    { key: "Service", value: "user-management-api", propagate_at_launch: true },
    
    # Financial tracking
    { key: "CostCenter", value: "ENG-BACKEND-001", propagate_at_launch: true },
    { key: "BudgetCode", value: "PROJ-2024-API-MODERNIZATION", propagate_at_launch: true },
    { key: "ChargebackCode", value: "INTERNAL-BACKEND", propagate_at_launch: true },
    { key: "PurchaseOrder", value: "PO-2024-CLOUD-INFRA", propagate_at_launch: false },
    
    # Resource optimization
    { key: "RightSizingCandidate", value: "yes", propagate_at_launch: false },
    { key: "SpotInstanceEligible", value: "no", propagate_at_launch: false }
  ]
})
```

### Compliance and Security Tagging

```ruby
# Security and compliance framework tagging
aws_autoscaling_tag(:compliance_tags, {
  autoscaling_group_name: ref(:aws_autoscaling_group, :payment_services, :name),
  tags: [
    # Data classification
    { key: "DataClassification", value: "restricted", propagate_at_launch: true },
    { key: "DataSovereign", value: "us-only", propagate_at_launch: true },
    { key: "PIIContained", value: "yes", propagate_at_launch: true },
    { key: "PHIContained", value: "no", propagate_at_launch: true },
    
    # Compliance frameworks
    { key: "PCI-DSS-Level", value: "level1", propagate_at_launch: true },
    { key: "SOX-Scope", value: "yes", propagate_at_launch: true },
    { key: "GDPR-Applicable", value: "yes", propagate_at_launch: true },
    { key: "CCPA-Applicable", value: "yes", propagate_at_launch: true },
    
    # Security requirements
    { key: "EncryptionAtRest", value: "required", propagate_at_launch: true },
    { key: "EncryptionInTransit", value: "required", propagate_at_launch: true },
    { key: "VulnerabilityScanning", value: "daily", propagate_at_launch: true },
    { key: "PenetrationTesting", value: "quarterly", propagate_at_launch: false },
    
    # Access controls  
    { key: "AccessReviewFrequency", value: "quarterly", propagate_at_launch: false },
    { key: "PrivilegedAccess", value: "restricted", propagate_at_launch: false }
  ]
})
```

## Operational Patterns

### Environment-Specific Tagging

```ruby
# Development environment with cost-conscious tagging
aws_autoscaling_tag(:dev_environment_tags, {
  autoscaling_group_name: ref(:aws_autoscaling_group, :dev_services, :name),
  tags: [
    { key: "Environment", value: "development", propagate_at_launch: true },
    { key: "AutoShutdown", value: "enabled", propagate_at_launch: true },
    { key: "ShutdownSchedule", value: "weekdays-6pm-pst", propagate_at_launch: true },
    { key: "CostOptimization", value: "spot-instances", propagate_at_launch: true },
    { key: "DataPersistence", value: "temporary", propagate_at_launch: true }
  ]
})

# Production environment with comprehensive operational tags
aws_autoscaling_tag(:prod_environment_tags, {
  autoscaling_group_name: ref(:aws_autoscaling_group, :prod_services, :name),
  tags: [
    { key: "Environment", value: "production", propagate_at_launch: true },
    { key: "HighAvailability", value: "required", propagate_at_launch: true },
    { key: "DisasterRecovery", value: "cross-region", propagate_at_launch: true },
    { key: "MonitoringLevel", value: "comprehensive", propagate_at_launch: true },
    { key: "AlertingLevel", value: "critical", propagate_at_launch: false },
    { key: "OnCallTeam", value: "platform-oncall", propagate_at_launch: false }
  ]
})
```

### Lifecycle Management Tagging

```ruby
# Automated lifecycle management tags
aws_autoscaling_tag(:lifecycle_management_tags, {
  autoscaling_group_name: ref(:aws_autoscaling_group, :batch_processors, :name),
  tags: [
    # Backup configuration
    { key: "BackupRequired", value: "yes", propagate_at_launch: true },
    { key: "BackupSchedule", value: "daily-2am-utc", propagate_at_launch: true },
    { key: "BackupRetention", value: "30days", propagate_at_launch: true },
    
    # Maintenance windows
    { key: "MaintenanceWindow", value: "saturday-4am-utc", propagate_at_launch: false },
    { key: "PatchingSchedule", value: "monthly-second-saturday", propagate_at_launch: false },
    
    # Scaling behavior
    { key: "AutoScalingEnabled", value: "yes", propagate_at_launch: false },
    { key: "MinInstances", value: "2", propagate_at_launch: false },
    { key: "MaxInstances", value: "20", propagate_at_launch: false }
  ]
})
```

## Error Handling

Detailed validation provides comprehensive error messages:

```ruby
# Tag key validation errors
"Tag key cannot be empty"
"Tag key cannot exceed 128 characters: very-long-key-name..."
"Tag key cannot start with 'aws:' prefix: aws:custom-tag"

# Tag value validation errors
"Tag value cannot be nil for key: Environment"
"Tag value cannot exceed 256 characters for key 'Description'"

# Duplicate and limit errors
"Duplicate tag key not allowed: Environment"
"Cannot exceed 50 tags per Auto Scaling Group (provided: 51)"

# ASG name validation errors
"Auto Scaling Group name cannot be empty"
"Auto Scaling Group name cannot exceed 255 characters"
```

## Testing Strategy

### Unit Tests
- Tag key and value length validation
- AWS prefix restriction enforcement
- Duplicate key detection
- Tag count limit enforcement
- Propagation flag validation

### Integration Tests
- Tag application to Auto Scaling Groups
- Instance tag propagation verification
- Tag modification and deletion
- Multiple tag resource coordination

### Production Validation
- Tag propagation to launched instances
- Cost allocation report generation
- Compliance tag audit verification
- Operational automation tag usage

## AWS Cost and Billing Integration

### Cost Allocation Tags

Tags enable detailed cost analysis:

```ruby
# Tags that appear in AWS Cost Explorer
tags: [
  { key: "Department", value: "engineering", propagate_at_launch: true },
  { key: "Project", value: "mobile-backend", propagate_at_launch: true },
  { key: "Environment", value: "production", propagate_at_launch: true },
  { key: "CostCenter", value: "ENG-PLATFORM", propagate_at_launch: true }
]
```

### Budget Integration

```ruby
# Tags for AWS Budgets filtering
tags: [
  { key: "BudgetCode", value: "PROJ-2024-001", propagate_at_launch: true },
  { key: "BudgetOwner", value: "platform-team", propagate_at_launch: true },
  { key: "CostAlert", value: "enabled", propagate_at_launch: false }
]
```

## Terraform Resource Mapping

The implementation creates individual `aws_autoscaling_group_tag` resources:

```hcl
resource "aws_autoscaling_group_tag" "web_server_tags_environment" {
  autoscaling_group_name = aws_autoscaling_group.web_servers.name
  
  tag {
    key                 = "Environment"
    value               = "production"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_group_tag" "web_server_tags_application" {
  autoscaling_group_name = aws_autoscaling_group.web_servers.name
  
  tag {
    key                 = "Application" 
    value               = "web-frontend"
    propagate_at_launch = true
  }
}
```

This approach provides:
- **Granular Control**: Manage each tag independently
- **Selective Updates**: Modify individual tags without affecting others
- **Clear Resource Tracking**: Each tag has its own Terraform resource
- **Dependency Management**: Precise dependency tracking per tag

The implementation ensures reliable, well-validated Auto Scaling Group tagging that supports comprehensive cost allocation, compliance tracking, and operational automation while maintaining AWS best practices and constraints.