# AWS RDS Database Instance Implementation Documentation

## Overview

This directory contains the implementation for the `aws_db_instance` resource function, providing type-safe creation and management of AWS Relational Database Service (RDS) instances through terraform-synthesizer integration.

## Implementation Architecture

### Core Components

#### 1. Resource Function (`resource.rb`)
The main `aws_db_instance` function that:
- Accepts a symbol name and attributes hash
- Validates attributes using dry-struct types
- Generates terraform resource blocks via terraform-synthesizer
- Returns ResourceReference with computed outputs and properties

#### 2. Type Definitions (`types.rb`)
DbInstanceAttributes dry-struct defining:
- Required attributes: `engine`, `instance_class`, `allocated_storage`
- Optional attributes: `identifier`, `engine_version`, `db_subnet_group_name`
- Engine-specific validations (Aurora, SQL Server constraints)
- Pre-defined engine configurations

#### 3. Documentation
- **CLAUDE.md** (this file): Implementation details for developers
- **README.md**: User-facing documentation with examples

## Technical Implementation Details

### Supported Database Engines

#### Traditional RDS Engines
- **MySQL**: Versions 5.7, 8.0
- **PostgreSQL**: Versions 11-15
- **MariaDB**: Versions 10.3-10.11
- **Oracle**: SE, SE1, SE2, EE editions
- **SQL Server**: Express, Web, Standard, Enterprise editions

#### Aurora Engines
- **Aurora MySQL**: Compatible with MySQL 5.7, 8.0
- **Aurora PostgreSQL**: Compatible with PostgreSQL 11-15
- Note: Aurora instances require cluster configuration

### Type Validation Logic

```ruby
class DbInstanceAttributes < Dry::Struct
  # Engine validation
  attribute :engine, Types::String.enum(
    "mysql", "postgres", "mariadb", "oracle-se", "oracle-se1", "oracle-se2", 
    "oracle-ee", "sqlserver-ee", "sqlserver-se", "sqlserver-ex", "sqlserver-web",
    "aurora", "aurora-mysql", "aurora-postgresql"
  )
  
  # Storage validation
  attribute :allocated_storage, Types::Integer.constrained(gteq: 20, lteq: 65536)
  attribute :storage_type, Types::String.enum("standard", "gp2", "gp3", "io1", "io2")
  
  # Custom validation
  def self.new(attributes = {})
    attrs = super(attributes)
    
    # Aurora doesn't use allocated_storage
    if attrs.engine.start_with?("aurora") && attrs.allocated_storage
      raise Dry::Struct::Error, "Aurora engines do not support 'allocated_storage'"
    end
    
    # IOPS only for io1/io2
    if attrs.iops && !%w[io1 io2].include?(attrs.storage_type)
      raise Dry::Struct::Error, "IOPS can only be specified for io1 or io2 storage types"
    end
    
    attrs
  end
end
```

### Terraform Synthesis

The resource function generates terraform JSON through terraform-synthesizer:

```ruby
resource(:aws_db_instance, name) do
  identifier db_attrs.identifier if db_attrs.identifier
  
  # Engine configuration
  engine db_attrs.engine
  engine_version db_attrs.engine_version if db_attrs.engine_version
  
  # Instance specifications
  instance_class db_attrs.instance_class
  allocated_storage db_attrs.allocated_storage
  storage_type db_attrs.storage_type
  storage_encrypted db_attrs.storage_encrypted
  
  # Database configuration
  db_name db_attrs.db_name if db_attrs.db_name
  username db_attrs.username if db_attrs.username
  manage_master_user_password db_attrs.manage_master_user_password
  
  # Network configuration
  db_subnet_group_name db_attrs.db_subnet_group_name
  vpc_security_group_ids db_attrs.vpc_security_group_ids
  multi_az db_attrs.multi_az
  
  # Backup configuration
  backup_retention_period db_attrs.backup_retention_period
  backup_window db_attrs.backup_window if db_attrs.backup_window
  maintenance_window db_attrs.maintenance_window if db_attrs.maintenance_window
  
  # Performance insights
  performance_insights_enabled db_attrs.performance_insights_enabled
  
  # Deletion protection
  deletion_protection db_attrs.deletion_protection
  skip_final_snapshot db_attrs.skip_final_snapshot
end
```

### ResourceReference Return Value

The function returns a ResourceReference providing:

#### Terraform Outputs
- `id`: Database instance identifier
- `arn`: Full ARN of the database
- `address`: DNS address of the instance
- `endpoint`: Connection endpoint (address:port)
- `hosted_zone_id`: Route 53 hosted zone ID
- `resource_id`: Resource ID for the instance
- `status`: Current status of the database
- `port`: Database port number

#### Computed Properties
- `engine_family`: Simplified engine family (mysql, postgresql, etc.)
- `is_aurora`: Boolean indicating Aurora engine
- `is_serverless`: Boolean indicating serverless instance
- `requires_subnet_group`: Whether subnet group is required
- `supports_encryption`: Whether encryption is supported
- `estimated_monthly_cost`: Rough cost estimate

## Pre-defined Engine Configurations

The implementation includes helper configurations for common engines:

```ruby
# MySQL with CloudWatch logs
RdsEngineConfigs.mysql(version: "8.0")
# Returns: {
#   engine: "mysql",
#   engine_version: "8.0",
#   enabled_cloudwatch_logs_exports: ["error", "general", "slowquery"]
# }

# PostgreSQL with defaults
RdsEngineConfigs.postgresql(version: "15")

# Aurora MySQL
RdsEngineConfigs.aurora_mysql(version: "8.0.mysql_aurora.3.02.0")

# Aurora PostgreSQL
RdsEngineConfigs.aurora_postgresql(version: "15.2")
```

## Integration Patterns

### 1. Basic RDS Instance
```ruby
template :database do
  # Create subnet group first
  db_subnet_group = aws_db_subnet_group(:main, {
    name: "main-db-subnet-group",
    subnet_ids: [private_subnet_a.id, private_subnet_b.id],
    description: "Subnet group for RDS instances"
  })
  
  # Create security group
  db_sg = aws_security_group(:database, {
    name: "database-sg",
    vpc_id: vpc.id,
    ingress_rules: [{
      from_port: 5432,
      to_port: 5432,
      protocol: "tcp",
      security_group_id: app_sg.id  # Allow from app tier
    }]
  })
  
  # Create PostgreSQL instance
  postgres_db = aws_db_instance(:main, {
    identifier: "main-postgres-db",
    engine: "postgres",
    engine_version: "15.3",
    instance_class: "db.t3.medium",
    allocated_storage: 100,
    storage_type: "gp3",
    storage_encrypted: true,
    
    db_name: "maindb",
    username: "dbadmin",
    manage_master_user_password: true,
    
    db_subnet_group_name: db_subnet_group.name,
    vpc_security_group_ids: [db_sg.id],
    
    backup_retention_period: 7,
    backup_window: "03:00-04:00",
    maintenance_window: "sun:04:00-sun:05:00",
    
    deletion_protection: true,
    
    tags: {
      Name: "main-postgres-db",
      Environment: "production"
    }
  })
end
```

### 2. High-Performance Database
```ruby
template :high_performance_db do
  # High-performance MySQL with provisioned IOPS
  mysql_db = aws_db_instance(:performance, {
    identifier: "high-perf-mysql",
    **RdsEngineConfigs.mysql(version: "8.0.33"),
    instance_class: "db.r5.2xlarge",
    allocated_storage: 1000,
    storage_type: "io2",
    iops: 10000,
    
    multi_az: true,
    performance_insights_enabled: true,
    performance_insights_retention_period: 31,
    
    backup_retention_period: 14,
    
    tags: {
      Purpose: "high-performance",
      Tier: "critical"
    }
  })
end
```

### 3. Development Database
```ruby
template :dev_database do
  # Small development database
  dev_db = aws_db_instance(:dev, {
    identifier_prefix: "dev-db-",
    engine: "postgres",
    instance_class: "db.t3.micro",
    allocated_storage: 20,
    storage_type: "gp2",
    storage_encrypted: false,  # Save cost in dev
    
    db_name: "devdb",
    username: "developer",
    password: "temporary-dev-password",  # Only for dev!
    
    backup_retention_period: 1,
    deletion_protection: false,
    skip_final_snapshot: true,
    
    tags: {
      Environment: "development",
      AutoShutdown: "true"
    }
  })
end
```

## Error Handling and Validation

### Common Validation Errors

#### 1. Engine-Specific Constraints
```ruby
# ERROR: Aurora with allocated_storage
aws_db_instance(:aurora_bad, {
  engine: "aurora-mysql",
  allocated_storage: 100  # Aurora doesn't use this
})
# Raises: Dry::Struct::Error: "Aurora engines do not support 'allocated_storage'"

# ERROR: SQL Server with db_name
aws_db_instance(:sqlserver_bad, {
  engine: "sqlserver-ex",
  db_name: "mydb"  # SQL Server doesn't support this
})
# Raises: Dry::Struct::Error: "SQL Server engines do not support 'db_name'"
```

#### 2. Storage Configuration
```ruby
# ERROR: IOPS without io1/io2
aws_db_instance(:bad_iops, {
  storage_type: "gp3",
  iops: 10000  # Only valid for io1/io2
})
# Raises: Dry::Struct::Error: "IOPS can only be specified for io1 or io2"
```

#### 3. Security Configuration
```ruby
# ERROR: Both password methods
aws_db_instance(:bad_password, {
  password: "mypassword",
  manage_master_user_password: true  # Can't use both
})
# Raises: Dry::Struct::Error: "Cannot specify both 'password' and 'manage_master_user_password'"
```

## Testing Strategy

### Unit Tests
```ruby
RSpec.describe Pangea::Resources::AWS do
  describe "#aws_db_instance" do
    it "creates RDS instance with valid configuration" do
      db_ref = aws_db_instance(:test, {
        engine: "postgres",
        instance_class: "db.t3.micro",
        allocated_storage: 20
      })
      
      expect(db_ref).to be_a(ResourceReference)
      expect(db_ref.type).to eq('aws_db_instance')
      expect(db_ref.engine_family).to eq('postgresql')
    end
    
    it "validates Aurora constraints" do
      expect {
        aws_db_instance(:aurora, {
          engine: "aurora-mysql",
          instance_class: "db.t3.small",
          allocated_storage: 100
        })
      }.to raise_error(Dry::Struct::Error, /Aurora engines do not support/)
    end
    
    it "estimates monthly cost" do
      db_ref = aws_db_instance(:test, {
        engine: "mysql",
        instance_class: "db.t3.medium",
        allocated_storage: 100,
        multi_az: true
      })
      
      expect(db_ref.estimated_monthly_cost).to match(/~\$\d+\.\d+\/month/)
    end
  end
end
```

## Security Best Practices

### 1. Password Management
- Always use `manage_master_user_password: true` in production
- Never hardcode passwords in code
- Use AWS Secrets Manager for password rotation

### 2. Network Security
- Place databases in private subnets
- Use security groups to restrict access
- Enable VPC flow logs for audit

### 3. Encryption
- Always enable `storage_encrypted: true`
- Use customer-managed KMS keys for sensitive data
- Enable encryption in transit

### 4. Backup and Recovery
- Set appropriate `backup_retention_period`
- Test restore procedures regularly
- Enable `deletion_protection` for production

### 5. Monitoring
- Enable Performance Insights
- Export logs to CloudWatch
- Set up alarms for key metrics

## Future Enhancements

### 1. Aurora Cluster Support
- Dedicated `aws_rds_cluster` resource
- Cluster parameter groups
- Aurora Serverless v2 support

### 2. Advanced Features
- Read replica configuration
- Database proxy integration
- Blue/green deployment support

### 3. Compliance Features
- Automated compliance checks
- Encryption validation
- Backup compliance verification

### 4. Cost Optimization
- Reserved instance recommendations
- Storage optimization suggestions
- Right-sizing analysis

This implementation provides comprehensive RDS database instance management within the Pangea resource system, emphasizing security, reliability, and ease of use.