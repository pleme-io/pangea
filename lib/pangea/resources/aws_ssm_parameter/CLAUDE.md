# AWS Systems Manager Parameter Implementation

## Overview

The `aws_ssm_parameter` resource provides type-safe AWS Systems Manager Parameter Store management with comprehensive validation for all parameter types (String, StringList, SecureString), tier management, and configuration patterns for common use cases.

## Key Features

### 1. Parameter Type Safety
- **String Parameters**: Plain text configuration values with optional validation patterns
- **StringList Parameters**: Comma-separated lists with automatic parsing and validation
- **SecureString Parameters**: KMS-encrypted parameters with key management and validation

### 2. Tier Management
- **Standard Tier**: Free tier with 4KB limit, suitable for most configuration parameters
- **Advanced Tier**: Paid tier with 8KB limit and enhanced features for large configurations
- **Automatic Tier Selection**: Helper configurations automatically select appropriate tier

### 3. Hierarchical Organization
- **Path Structure**: Support for hierarchical parameter organization (e.g., `/app/env/config`)
- **Path Analysis**: Computed properties for path manipulation and organization
- **Namespace Management**: Consistent parameter naming patterns across applications

### 4. Security Integration
- **KMS Integration**: Support for customer-managed and AWS-managed KMS keys
- **Encryption Validation**: Automatic validation of KMS key formats and constraints
- **Access Control**: Integration with IAM for fine-grained parameter access

## Type Safety Implementation

### Core Validation
```ruby
def self.new(attributes = {})
  attrs = super(attributes)
  
  # SecureString validation
  if attrs.type == "SecureString"
    if attrs.key_id && !attrs.key_id.match?(/\A(alias\/[a-zA-Z0-9\/_-]+|arn:aws:kms:[a-z0-9-]+:\d{12}:key\/[a-f0-9-]{36}|[a-f0-9-]{36})\z/)
      raise Dry::Struct::Error, "key_id must be a valid KMS key ID, ARN, or alias"
    end
  elsif attrs.key_id
    raise Dry::Struct::Error, "key_id can only be specified for SecureString parameters"
  end
  
  # ... additional validations
end
```

### Parameter Name Validation
- **Character Set**: Only alphanumeric characters and `/_.-` symbols allowed
- **Length Limits**: Maximum 2048 characters for parameter names
- **Hierarchical Structure**: Support for path-like organization with validation

### Value Size Validation
```ruby
max_value_size = attrs.tier == "Advanced" ? 8192 : 4096
if attrs.value.bytesize > max_value_size
  raise Dry::Struct::Error, "Parameter value cannot exceed #{max_value_size} bytes for #{attrs.tier} tier"
end
```

### Pattern Validation
```ruby
if attrs.allowed_pattern
  begin
    Regexp.new(attrs.allowed_pattern)
  rescue RegexpError => e
    raise Dry::Struct::Error, "Invalid allowed_pattern regular expression: #{e.message}"
  end
end
```

## Resource Synthesis

### Basic Parameter Configuration
```ruby
resource(:aws_ssm_parameter, name) do
  parameter_name parameter_attrs.name
  type parameter_attrs.type
  value parameter_attrs.value

  # Optional attributes
  description parameter_attrs.description if parameter_attrs.description
  key_id parameter_attrs.key_id if parameter_attrs.key_id
  tier parameter_attrs.tier
  allowed_pattern parameter_attrs.allowed_pattern if parameter_attrs.allowed_pattern
  data_type parameter_attrs.data_type if parameter_attrs.data_type
  overwrite parameter_attrs.overwrite
end
```

### Tag Synthesis
```ruby
if parameter_attrs.tags.any?
  tags do
    parameter_attrs.tags.each do |key, value|
      public_send(key, value)
    end
  end
end
```

## Helper Configurations

### String Parameter Pattern
```ruby
def self.string_parameter(name, value, description: nil)
  {
    name: name,
    type: "String",
    value: value,
    description: description,
    tier: "Standard"
  }.compact
end
```

### Secure Parameter Pattern
```ruby
def self.secure_parameter(name, value, key_id: nil, description: nil)
  {
    name: name,
    type: "SecureString",
    value: value,
    key_id: key_id,
    description: description,
    tier: "Standard"
  }.compact
end
```

### Advanced Tier Auto-Selection
```ruby
def self.app_config_parameter(name, config_json, description: nil)
  {
    name: name,
    type: "String",
    value: config_json,
    description: description,
    data_type: "text",
    tier: config_json.bytesize > 4096 ? "Advanced" : "Standard"
  }.compact
end
```

## Computed Properties

### Parameter Type Detection
```ruby
def is_secure_string?
  type == "SecureString"
end

def is_string_list?
  type == "StringList"
end

def is_string?
  type == "String"
end
```

### Hierarchical Analysis
```ruby
def is_hierarchical?
  name.include?('/')
end

def parameter_path
  return '/' unless is_hierarchical?
  parts = name.split('/')[0...-1]
  parts.empty? ? '/' : parts.join('/')
end

def parameter_name_only
  return name unless is_hierarchical?
  name.split('/').last
end
```

### StringList Processing
```ruby
def string_list_values
  return [] unless is_string_list?
  value.split(',').map(&:strip)
end
```

### Cost Analysis
```ruby
def estimated_monthly_cost
  if is_advanced_tier?
    "~$0.05/month"
  else
    "Free (Standard tier)"
  end
end
```

## Integration Patterns

### Application Configuration Hierarchy
```ruby
# Create hierarchical parameter structure
app_config = {
  name: aws_ssm_parameter(:app_name, {
    name: "/mycompany/myapp/name",
    type: "String",
    value: "MyApplication"
  }),
  
  version: aws_ssm_parameter(:app_version, {
    name: "/mycompany/myapp/version",
    type: "String", 
    value: "2.1.0"
  }),
  
  database: {
    host: aws_ssm_parameter(:db_host, {
      name: "/mycompany/myapp/database/host",
      type: "String",
      value: db_cluster.outputs[:endpoint]
    }),
    
    password: aws_ssm_parameter(:db_password, {
      name: "/mycompany/myapp/database/password",
      type: "SecureString",
      value: random_password.result,
      key_id: app_kms_key.outputs[:arn]
    })
  }
}
```

### KMS Integration Pattern
```ruby
# Create application-specific KMS key
app_kms_key = aws_kms_key(:app_parameters, {
  description: "KMS key for application parameters",
  deletion_window_in_days: 7
})

# Create secure parameters with custom key
database_params = {
  connection_string: aws_ssm_parameter(:db_connection, {
    name: "/myapp/database/connection_string",
    type: "SecureString",
    value: "postgresql://user:pass@#{db_cluster.outputs[:endpoint]}:5432/myapp",
    key_id: app_kms_key.outputs[:arn],
    description: "Database connection string"
  }),
  
  api_keys: aws_ssm_parameter(:api_keys, {
    name: "/myapp/external/api_keys",
    type: "SecureString", 
    value: JSON.generate({
      stripe: "sk_live_...",
      sendgrid: "SG...."
    }),
    key_id: app_kms_key.outputs[:arn],
    description: "External service API keys"
  })
}
```

### Configuration Management Pattern
```ruby
# Environment-specific configuration
environments = ["development", "staging", "production"]

environments.each do |env|
  # Database configuration
  aws_ssm_parameter(:"db_config_#{env}", {
    name: "/myapp/#{env}/database/config",
    type: "SecureString",
    value: JSON.generate({
      host: "#{env}-db.company.com",
      port: 5432,
      database: "myapp_#{env}",
      pool_size: env == "production" ? 20 : 5
    }),
    description: "Database configuration for #{env} environment"
  })
  
  # Application settings
  aws_ssm_parameter(:"app_config_#{env}", {
    name: "/myapp/#{env}/application/config",
    type: "String",
    value: JSON.generate({
      log_level: env == "production" ? "INFO" : "DEBUG",
      debug_mode: env != "production",
      max_connections: env == "production" ? 1000 : 100
    }),
    description: "Application configuration for #{env} environment"
  })
end
```

## Error Handling

### Parameter Type Validation
- **KMS Key Format**: Validates key IDs, ARNs, and aliases for SecureString parameters
- **Type Constraints**: Prevents KMS key specification for non-SecureString parameters
- **Value Size Limits**: Enforces tier-specific size limits with clear error messages

### Pattern Validation
- **Regular Expression**: Validates allowed_pattern as valid regex with specific error reporting
- **Pattern Matching**: Runtime validation of parameter values against patterns

### Name and Path Validation
- **Character Set**: Enforces allowed characters in parameter names
- **Length Limits**: Validates parameter name length constraints
- **Path Structure**: Validates hierarchical parameter name format

## Output Reference Structure

```ruby
outputs: {
  name: "${aws_ssm_parameter.#{name}.name}",
  arn: "${aws_ssm_parameter.#{name}.arn}",
  type: "${aws_ssm_parameter.#{name}.type}",
  value: "${aws_ssm_parameter.#{name}.value}",
  version: "${aws_ssm_parameter.#{name}.version}",
  tier: "${aws_ssm_parameter.#{name}.tier}",
  data_type: "${aws_ssm_parameter.#{name}.data_type}",
  key_id: "${aws_ssm_parameter.#{name}.key_id}",
  tags_all: "${aws_ssm_parameter.#{name}.tags_all}"
}
```

## Best Practices

### Security
1. **Use SecureString**: For passwords, API keys, and sensitive configuration
2. **Customer-Managed Keys**: Use dedicated KMS keys for application parameters
3. **Least Privilege Access**: Configure IAM policies for parameter access
4. **Parameter Policies**: Use Advanced tier for parameter expiration policies

### Organization
1. **Hierarchical Naming**: Organize parameters with consistent path structures
2. **Environment Separation**: Separate parameters by environment paths
3. **Application Namespaces**: Use application-specific parameter paths
4. **Consistent Patterns**: Establish naming conventions across teams

### Performance
1. **Batch Retrieval**: Use GetParameters API for multiple parameters
2. **Caching Strategy**: Implement application-level parameter caching
3. **Version Management**: Use parameter versions for rollback capabilities
4. **Standard vs Advanced**: Use Standard tier unless Advanced features needed

### Operational Excellence
1. **Parameter Documentation**: Use descriptions for all parameters
2. **Validation Patterns**: Implement allowed_pattern for critical parameters
3. **Cost Monitoring**: Monitor Advanced tier parameter usage
4. **Lifecycle Management**: Implement parameter cleanup and rotation policies