# AWS RDS Cluster Instance Implementation

## Resource Overview

The `aws_rds_cluster_instance` resource creates and manages AWS Aurora RDS Cluster Instances, which serve as the compute nodes within Aurora clusters. Each instance handles database operations and can be configured as writers or readers with specific performance characteristics and failover priorities.

## Implementation Architecture

### Type Safety Structure
```
RdsClusterInstanceAttributes (Dry::Struct)
├── identifier: String (optional)
├── identifier_prefix: String (optional)
├── cluster_identifier: String (required)
├── instance_class: String (enum of Aurora instance types, required)
├── engine: String (optional, inherited from cluster)
├── engine_version: String (optional, inherited from cluster)
├── availability_zone: String (optional)
├── db_parameter_group_name: String (optional)
├── publicly_accessible: Bool (default: false)
├── monitoring_interval: Integer (0-60, default: 0)
├── monitoring_role_arn: String (optional)
├── performance_insights_enabled: Bool (default: false)
├── performance_insights_kms_key_id: String (optional)
├── performance_insights_retention_period: Integer (7-731, default: 7)
├── preferred_backup_window: String (optional)
├── preferred_maintenance_window: String (optional)
├── auto_minor_version_upgrade: Bool (default: true)
├── apply_immediately: Bool (default: false)
├── copy_tags_to_snapshot: Bool (default: true)
├── ca_cert_identifier: String (optional)
├── promotion_tier: Integer (0-15, default: 1)
└── tags: Hash[String, String] (default: {})
```

### Core Validations

1. **Identifier Validation**
   - Cannot specify both identifier and identifier_prefix
   - AWS will generate identifier if neither provided

2. **Instance Class Validation**
   - Comprehensive enum of Aurora-supported instance types
   - Includes burstable (t3, t4g), memory-optimized (r5, r6g, r6i, x2g)
   - Special handling for "serverless" instance class

3. **Promotion Tier Validation**
   - Must be between 0-15 (0 = highest priority for writer role)
   - Determines failover order and instance role

4. **Monitoring Configuration Validation**
   - monitoring_role_arn required when monitoring_interval > 0
   - Performance Insights retention period must be >= 7 days when enabled
   - Serverless instances don't support enhanced monitoring

5. **Performance Insights Validation**
   - Retention period validation (7-731 days)
   - KMS key validation when encryption is enabled
   - Feature availability by instance type

6. **Serverless Instance Validation**
   - Enhanced monitoring not supported
   - Different constraint validation for serverless vs. provisioned

### Resource Function Signature
```ruby
def aws_rds_cluster_instance(name, attributes = {})
  # Returns ResourceReference with:
  # - Comprehensive Terraform outputs
  # - Performance characteristics analysis  
  # - Role and tier information
  # - Cost and scaling insights
end
```

## Terraform Resource Mapping

### Generated Terraform JSON Structure
```json
{
  "resource": {
    "aws_rds_cluster_instance": {
      "resource_name": {
        "identifier": "aurora-instance-name",
        "cluster_identifier": "aurora-cluster-name",
        "instance_class": "db.r5.large",
        "promotion_tier": 0,
        "performance_insights_enabled": true,
        "performance_insights_retention_period": 93,
        "monitoring_interval": 60,
        "monitoring_role_arn": "arn:aws:iam::account:role/rds-monitoring-role",
        "preferred_maintenance_window": "sun:04:00-sun:05:00",
        "tags": {
          "Role": "writer",
          "Environment": "production"
        }
      }
    }
  }
}
```

### Available Outputs
Comprehensive output coverage including:
- Instance identifiers and ARN
- Cluster association information
- Network endpoint details
- Performance and monitoring configuration
- Instance characteristics and status
- Database parameter configuration

## Design Patterns

### Instance Classification System
```ruby
def instance_family
  case instance_class
  when /^db\.t3/ then "t3"
  when /^db\.t4g/ then "t4g"
  when /^db\.r5/ then "r5"
  when /^db\.r6g/ then "r6g"
  when /^db\.r6i/ then "r6i"
  when /^db\.x2g/ then "x2g"
  when "serverless" then "serverless"
  end
end
```

### Role-Based Configuration
```ruby
def role_description
  case promotion_tier
  when 0 then "Primary writer instance"
  when 1 then "Primary failover target"
  else "Reader instance (tier #{promotion_tier})"
  end
end

def can_be_writer?
  promotion_tier == 0
end
```

### Performance Characteristics Analysis
```ruby
def performance_characteristics
  {
    vcpus: estimated_vcpus,
    memory_gb: estimated_memory_gb,
    instance_family: instance_family,
    is_burstable: is_burstable?,
    is_memory_optimized: is_memory_optimized?,
    is_graviton: is_graviton?
  }
end
```

### Cost Estimation System
```ruby
def estimated_monthly_cost
  return "Variable based on Aurora Capacity Units" if is_serverless?
  
  hourly_rate = calculate_hourly_rate(instance_class)
  monthly_cost = hourly_rate * 730
  "~$#{monthly_cost.round(2)}/month"
end
```

### Pre-configured Instance Templates
```ruby
module AuroraInstanceConfigs
  def self.production_writer
    # Returns production-optimized writer configuration
  end
  
  def self.graviton_writer
    # Returns Graviton2-based cost-optimized configuration
  end
  
  def self.multi_az_deployment
    # Returns multi-AZ deployment pattern
  end
end
```

## Integration Patterns

### Cluster Relationship Management
- Required cluster_identifier for cluster association
- Engine and version inheritance from parent cluster
- Coordinated backup and maintenance window scheduling
- Automatic cluster membership registration

### Parameter Group Integration
- Instance-level parameter groups through db_parameter_group_name
- Parameter validation against engine family
- Performance tuning through parameter optimization
- Engine-specific parameter support

### Monitoring Integration
- CloudWatch enhanced monitoring configuration
- Performance Insights with configurable retention
- Custom metrics and alarm integration
- Role-based monitoring strategies

### Network and Security Integration
- VPC placement through cluster subnet group
- Security group inheritance from cluster
- Availability zone distribution for high availability
- Cross-AZ failover coordination

## Operational Considerations

### High Availability Architecture
- **Promotion Tiers**: 0-15 priority system for failover order
- **Multi-AZ Deployment**: Instance distribution across availability zones
- **Failover Management**: Automatic promotion based on tier hierarchy
- **Reader Endpoint**: Load balancing across reader instances

### Instance Role Management
- **Writer Instances**: Tier 0 for primary write operations
- **Primary Failover**: Tier 1 for immediate failover capability
- **Reader Instances**: Tier 2+ for read scaling and secondary failover
- **Role Flexibility**: Dynamic role assignment through promotion

### Performance Optimization
- **Instance Sizing**: Memory and CPU optimization by workload
- **Burstable Performance**: T3/T4g for variable workloads
- **Memory Optimized**: R5/R6 series for consistent high performance
- **Graviton2 Processors**: ARM-based cost optimization

### Cost Management
- **Instance Type Selection**: Balanced performance vs. cost
- **Graviton2 Adoption**: ~20% cost savings with ARM architecture
- **Right-sizing**: Monitoring-driven instance optimization
- **Auto-scaling**: Reader instance scaling based on load

## Error Handling

### Validation Errors
```ruby
# Conflicting identifier specifications
raise Dry::Struct::Error, "Cannot specify both 'identifier' and 'identifier_prefix'"

# Monitoring configuration errors
raise Dry::Struct::Error, "monitoring_role_arn is required when monitoring_interval > 0"

# Performance Insights configuration errors  
raise Dry::Struct::Error, "performance_insights_retention_period must be at least 7 days when Performance Insights is enabled"

# Promotion tier validation
raise Dry::Struct::Error, "promotion_tier must be between 0 and 15"

# Serverless limitations
raise Dry::Struct::Error, "Enhanced monitoring is not supported for serverless instances"
```

### Runtime Validation
- AWS service-level validation for instance configuration
- Cluster membership validation
- Instance class availability by region
- Parameter group compatibility validation

## Testing Considerations

### Unit Testing
- Dry::Struct validation for all attribute combinations
- Instance classification and role determination testing
- Performance characteristics calculation testing
- Cost estimation accuracy testing

### Integration Testing
- Cluster association and dependency testing
- Cross-AZ deployment validation
- Monitoring configuration testing
- Parameter group integration testing

### Performance Testing
- Instance performance validation
- Failover testing and timing
- Load balancing effectiveness
- Monitoring data accuracy

## Performance Characteristics

### Instance Provisioning
- Fast instance creation within existing cluster
- Automatic cluster membership registration
- Parameter group application
- Monitoring configuration activation

### Scaling Capabilities
- **Vertical Scaling**: Instance class modification
- **Horizontal Scaling**: Reader instance addition/removal
- **Cross-AZ Scaling**: Multi-region read replica support
- **Automated Scaling**: Auto Scaling Group integration

### Monitoring Performance
- Real-time performance metrics through CloudWatch
- Performance Insights for query-level analysis
- Enhanced monitoring for OS-level metrics
- Custom metrics for application-specific monitoring

## Advanced Features

### Graviton2 Processor Support
```ruby
def is_graviton?
  instance_class.include?("t4g") || 
  instance_class.include?("r6g") || 
  instance_class.include?("x2g")
end
```

### Performance Insights Integration
```ruby
def has_performance_insights?
  performance_insights_enabled
end

def supports_performance_insights?
  !is_serverless?
end
```

### Multi-tier Failover Architecture
```ruby
def is_likely_reader?
  promotion_tier > 0
end

def failover_priority
  15 - promotion_tier  # Higher number = higher priority
end
```

### Cost Optimization Features
```ruby
def estimated_vcpus
  # Detailed vCPU calculation by instance class
end

def estimated_memory_gb  
  # Detailed memory calculation by instance class
end
```

## Future Extensibility

### Enhanced Instance Management
- Intelligent instance sizing recommendations
- Automated right-sizing based on performance metrics
- Predictive scaling for reader instances
- Cross-region read replica automation

### Advanced Monitoring
- Machine learning-based performance insights
- Automated anomaly detection
- Predictive maintenance scheduling
- Cost optimization recommendations

### Operational Enhancements
- Blue/green deployment support for instances
- Automated failover testing
- Instance lifecycle management
- Configuration drift detection

### Performance Optimization
- Query-level performance analysis
- Automatic parameter tuning
- Workload-specific instance recommendations
- Multi-dimensional cost optimization

### Security Enhancements
- Instance-level encryption key management
- Fine-grained access control
- Security compliance monitoring
- Audit trail automation