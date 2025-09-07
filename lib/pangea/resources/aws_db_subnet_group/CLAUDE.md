# AWS DB Subnet Group Implementation

## Resource Overview

The `aws_db_subnet_group` resource creates and manages AWS RDS DB Subnet Groups, which define the subnets that RDS instances and clusters can be placed in within a VPC.

## Implementation Architecture

### Type Safety Structure
```
DbSubnetGroupAttributes (Dry::Struct)
├── name: String (required)
├── subnet_ids: Array[String] (min 2, required) 
├── description: String (optional, defaults to generated)
└── tags: Hash[String, String] (optional, defaults to {})
```

### Core Validations

1. **Subnet Count Validation**
   - Minimum 2 subnets required for RDS multi-AZ functionality
   - Enforced at the type level with `constrained(min_size: 2)`

2. **Subnet ID Uniqueness**
   - Validates all subnet IDs are unique within the group
   - Prevents accidental duplicate subnet specifications

3. **Subnet ID Format Validation**
   - Validates AWS subnet ID format: `subnet-[a-f0-9]+`
   - Ensures proper AWS resource referencing

4. **Engine Compatibility Validation**
   - `validate_for_engine(engine)` method for engine-specific requirements
   - Aurora clusters require minimum 2 AZ coverage

### Resource Function Signature
```ruby
def aws_db_subnet_group(name, attributes = {})
  # Returns ResourceReference with:
  # - All Terraform outputs
  # - Computed properties for operational insights
  # - Type-safe attribute validation
end
```

## Terraform Resource Mapping

### Generated Terraform JSON Structure
```json
{
  "resource": {
    "aws_db_subnet_group": {
      "resource_name": {
        "name": "subnet-group-name",
        "subnet_ids": ["subnet-xxx", "subnet-yyy"],
        "description": "Generated or provided description",
        "tags": {
          "key": "value"
        }
      }
    }
  }
}
```

### Available Outputs
- `id`: RDS subnet group identifier
- `arn`: Amazon Resource Name
- `name`: Subnet group name
- `description`: Subnet group description
- `subnet_ids`: List of included subnet IDs
- `vpc_id`: VPC containing the subnets
- `supported_network_types`: Network types supported

## Design Patterns

### Subnet Group Naming Strategy
- Uses explicit `name` attribute for terraform resource name
- Supports both static names and dynamic generation
- Follows AWS naming conventions and constraints

### Multi-AZ Architecture Support
```ruby
# Computed property for multi-AZ capability
def is_multi_az?
  subnet_count >= 2
end
```

### Description Auto-Generation
```ruby
def effective_description
  description || "DB subnet group with #{subnet_count} subnets for #{name}"
end
```

## Integration Patterns

### VPC Integration
- Subnet IDs reference `aws_subnet` resources
- Automatic VPC inference through subnet membership
- Cross-resource validation capabilities

### Database Resource Integration
- Subnet group name used in `db_subnet_group_name` attribute
- Compatible with both RDS instances and Aurora clusters
- Engine-specific validation support

### Security Integration
- Works with VPC security groups
- Supports network ACLs through subnet configuration
- Private subnet enforcement for database security

## Operational Considerations

### Cost Implications
- DB subnet groups have no direct AWS charges
- Costs come from associated RDS resources
- `estimated_monthly_cost` returns "$0.00/month" with explanation

### High Availability Support
- Enforces multi-AZ subnet requirements
- Validates subnet distribution across availability zones
- Supports disaster recovery through regional subnet groups

### Compliance and Security
- Supports comprehensive tagging for compliance tracking
- Enables network segmentation through subnet selection
- Facilitates security auditing through resource references

## Error Handling

### Validation Errors
```ruby
# Insufficient subnets
raise Dry::Struct::Error, "DB subnet groups require at least 2 subnets in different Availability Zones"

# Duplicate subnets
raise Dry::Struct::Error, "Subnet IDs must be unique within the subnet group"

# Invalid format
raise Dry::Struct::Error, "Invalid subnet ID format: #{subnet_id}. Expected format: subnet-xxxxxxxx"
```

### Runtime Validation
- Subnet existence validated by Terraform during apply
- VPC membership consistency enforced by AWS
- Availability zone distribution validated by AWS RDS service

## Testing Considerations

### Unit Testing
- Dry::Struct validation testing
- Computed properties testing
- Edge case validation (minimum subnets, format validation)

### Integration Testing
- Cross-resource reference validation
- Terraform resource generation testing
- AWS API compatibility testing

## Performance Characteristics

### Resource Creation
- Low-latency resource creation (subnet groups are metadata only)
- No compute resources provisioned
- Immediate availability for database resource creation

### State Management
- Minimal Terraform state footprint
- Simple resource dependency chain
- Easy to modify and update

## Future Extensibility

### Additional Validation
- Availability zone distribution validation
- VPC CIDR overlap detection
- Subnet size and capacity planning

### Enhanced Integration
- Automatic security group recommendations
- Cross-region replication subnet group management
- Database migration subnet group validation

### Operational Enhancements
- Subnet health checking integration
- Cost optimization recommendations
- Capacity planning insights