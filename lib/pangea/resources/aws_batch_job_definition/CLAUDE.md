# AWS Batch Job Definition Implementation

## Overview

This implementation provides a comprehensive, type-safe interface for AWS Batch job definitions with extensive validation for container properties, platform capabilities, resource requirements, and workload-specific configurations.

## Architecture

### Type System
- **BatchJobDefinitionAttributes**: Main dry-struct with comprehensive job definition validation
- **Container Properties Validation**: Deep validation of container configuration, resources, and environment
- **Multi-node Support**: Complete validation for multi-node parallel jobs
- **Platform Capability Validation**: EC2 vs Fargate capability checking
- **Template System**: Pre-built configurations for common workload patterns

### Validation Layers

1. **Name Validation**: AWS naming requirements (1-128 chars, alphanumeric + hyphens/underscores)
2. **Job Type Validation**: Container vs multi-node job validation
3. **Container Properties Validation**: Image, resources, environment, and volume validation
4. **Platform Capabilities Validation**: EC2/Fargate compatibility checking
5. **Resource Requirements Validation**: GPU and custom resource validation
6. **Retry/Timeout Validation**: Limits and duration validation

## Job Definition Types

### Container Jobs

Container jobs are single-container workloads that run on either EC2 or Fargate:

```ruby
{
  type: "container",
  container_properties: {
    image: "required_container_image",
    vcpus: 1,                    # Optional, defaults vary by platform
    memory: 512,                 # Optional, defaults vary by platform
    job_role_arn: "...",         # Optional IAM role for job
    execution_role_arn: "...",   # Required for Fargate
    environment: [...],          # Optional environment variables
    mount_points: [...],         # Optional volume mounts
    volumes: [...],              # Optional volume definitions
    resource_requirements: [...] # Optional GPU/custom resources
  }
}
```

### Multi-node Jobs

Multi-node jobs enable distributed parallel processing across multiple compute nodes:

```ruby
{
  type: "multinode",
  node_properties: {
    main_node: 0,              # Index of the main node
    num_nodes: 4,              # Total number of nodes
    node_range_properties: [   # Configuration per node range
      {
        target_nodes: "0:3",   # Node range specification
        container: {           # Container config for this range
          image: "...",
          vcpus: 2,
          memory: 2048
        }
      }
    ]
  }
}
```

## Container Properties Validation

### Core Properties Validation

```ruby
def self.validate_container_properties(properties)
  # Required image validation
  unless properties[:image] && properties[:image].is_a?(String) && !properties[:image].empty?
    raise Dry::Struct::Error, "Container properties must include a non-empty 'image' field"
  end
  
  # Resource validation
  if properties[:vcpus]
    unless properties[:vcpus].is_a?(Integer) && properties[:vcpus] > 0
      raise Dry::Struct::Error, "vCPUs must be a positive integer"
    end
  end
  
  if properties[:memory]
    unless properties[:memory].is_a?(Integer) && properties[:memory] > 0
      raise Dry::Struct::Error, "Memory must be a positive integer (MB)"
    end
  end
  
  # IAM role ARN validation
  if properties[:job_role_arn] && !properties[:job_role_arn].match?(/^arn:aws:iam::/)
    raise Dry::Struct::Error, "Job role ARN must be a valid IAM role ARN"
  end
  
  true
end
```

### Environment Variables Validation

```ruby
def self.validate_environment_variables(env_vars)
  unless env_vars.is_a?(Array)
    raise Dry::Struct::Error, "Environment variables must be an array"
  end
  
  env_vars.each_with_index do |env_var, index|
    unless env_var.is_a?(Hash) && env_var[:name] && env_var.key?(:value)
      raise Dry::Struct::Error, "Environment variable #{index} must have 'name' and 'value' fields"
    end
  end
  
  true
end
```

### Volume and Mount Point Validation

```ruby
def self.validate_mount_points(mount_points)
  unless mount_points.is_a?(Array)
    raise Dry::Struct::Error, "Mount points must be an array"
  end
  
  mount_points.each_with_index do |mount_point, index|
    required_fields = %i[source_volume container_path]
    required_fields.each do |field|
      unless mount_point[field] && mount_point[field].is_a?(String) && !mount_point[field].empty?
        raise Dry::Struct::Error, "Mount point #{index} must include non-empty '#{field}'"
      end
    end
  end
  
  true
end

def self.validate_volumes(volumes)
  unless volumes.is_a?(Array)
    raise Dry::Struct::Error, "Volumes must be an array"
  end
  
  volumes.each_with_index do |volume, index|
    unless volume.is_a?(Hash) && volume[:name] && volume[:name].is_a?(String)
      raise Dry::Struct::Error, "Volume #{index} must have a 'name' field"
    end
  end
  
  true
end
```

## Platform Capabilities System

### Platform Validation

```ruby
def self.validate_platform_capabilities(capabilities)
  unless capabilities.is_a?(Array)
    raise Dry::Struct::Error, "Platform capabilities must be an array"
  end
  
  valid_capabilities = %w[EC2 FARGATE]
  capabilities.each do |capability|
    unless valid_capabilities.include?(capability)
      raise Dry::Struct::Error, "Invalid platform capability '#{capability}'. Valid: #{valid_capabilities.join(', ')}"
    end
  end
  
  true
end
```

### Platform-Specific Features

**EC2 Platform**:
- Supports GPU resources
- Supports privileged containers
- Supports custom instance types
- Supports host volumes
- No execution role required

**Fargate Platform**:
- Serverless container execution
- Requires execution role
- Limited resource configurations
- Network configuration required
- No GPU support
- No privileged containers

### Platform Compatibility Checking

```ruby
def supports_ec2?
  platform_capabilities.nil? || platform_capabilities.include?("EC2")
end

def supports_fargate?
  platform_capabilities&.include?("FARGATE")
end
```

## Multi-node Job Validation

### Node Properties Structure

```ruby
def self.validate_node_properties(properties)
  # Main node validation
  unless properties[:main_node] && properties[:main_node].is_a?(Integer) && properties[:main_node] >= 0
    raise Dry::Struct::Error, "Node properties must include a non-negative main_node index"
  end
  
  # Number of nodes validation
  unless properties[:num_nodes] && properties[:num_nodes].is_a?(Integer) && properties[:num_nodes] > 0
    raise Dry::Struct::Error, "Node properties must include a positive num_nodes value"
  end
  
  # Node range properties validation
  unless properties[:node_range_properties] && properties[:node_range_properties].is_a?(Array)
    raise Dry::Struct::Error, "Node properties must include node_range_properties array"
  end
  
  # Validate each node range
  properties[:node_range_properties].each_with_index do |node_range, index|
    unless node_range[:target_nodes] && node_range[:target_nodes].is_a?(String)
      raise Dry::Struct::Error, "Node range property #{index} must include target_nodes string"
    end
    
    # Validate container properties for this node range
    if node_range[:container] 
      validate_container_properties(node_range[:container])
    end
  end
  
  true
end
```

### Node Range Specification

Node ranges use string format to specify which nodes get which configuration:

- `"0"` - Single node (node 0)
- `"0:3"` - Range of nodes (nodes 0, 1, 2, 3)
- `"1:2"` - Partial range (nodes 1, 2)

## Template System Architecture

### Template Categories

**Basic Templates**:
- `simple_container_job`: Basic container job with standard configuration
- `fargate_container_job`: Fargate-optimized container job
- `gpu_container_job`: GPU-accelerated container job
- `multinode_job`: Multi-node parallel job

**Workload-Specific Templates**:
- `data_processing_job`: Data pipeline and ETL workloads
- `ml_training_job`: Machine learning training workloads
- `batch_processing_job`: Background batch processing
- `real_time_job`: Low-latency real-time processing

### Template Implementation Pattern

```ruby
def self.data_processing_job(name, image, options = {})
  simple_container_job(
    name,
    image,
    {
      vcpus: options[:vcpus] || 2,
      memory: options[:memory] || 4096,
      retry_attempts: options[:retry_attempts] || 3,
      timeout_seconds: options[:timeout_seconds] || 3600,
      job_role_arn: options[:job_role_arn],
      platform_capabilities: options[:platform_capabilities],
      tags: (options[:tags] || {}).merge(
        Workload: "data-processing",
        Type: "cpu-intensive"
      )
    }
  )
end
```

### Template Composition

Templates build on each other for code reuse:

```ruby
def self.gpu_container_job(name, image, options = {})
  # Start with simple container job
  job_config = simple_container_job(name, image, options)
  
  # Add GPU-specific configuration
  job_config[:container_properties][:resource_requirements] = [
    {
      type: "GPU",
      value: (options[:gpu_count] || 1).to_s
    }
  ]
  
  # Force EC2 platform for GPU
  job_config[:platform_capabilities] = ["EC2"]
  
  # Add GPU-specific tags
  job_config[:tags] = (job_config[:tags] || {}).merge(Hardware: "gpu")
  
  job_config
end
```

## Resource Requirements System

### GPU Resource Configuration

```ruby
# GPU resource requirement
{
  resource_requirements: [
    {
      type: "GPU",
      value: "2" # Number of GPUs as string
    }
  ]
}
```

### Common Resource Requirements Helper

```ruby
def self.common_resource_requirements(gpu_count = nil)
  requirements = []
  
  if gpu_count
    requirements << {
      type: "GPU",
      value: gpu_count.to_s
    }
  end
  
  requirements
end
```

### Platform Constraints

- **GPU Resources**: Only supported on EC2 platform
- **Custom Resources**: Platform-dependent availability
- **Resource Limits**: Platform-specific maximums

## Retry and Timeout System

### Retry Strategy Validation

```ruby
def self.validate_retry_strategy(retry_strategy)
  unless retry_strategy.is_a?(Hash)
    raise Dry::Struct::Error, "Retry strategy must be a hash"
  end
  
  if retry_strategy[:attempts]
    unless retry_strategy[:attempts].is_a?(Integer) && retry_strategy[:attempts] >= 1 && retry_strategy[:attempts] <= 10
      raise Dry::Struct::Error, "Retry attempts must be between 1 and 10"
    end
  end
  
  true
end
```

### Timeout Configuration

```ruby
def self.validate_timeout(timeout)
  unless timeout.is_a?(Hash)
    raise Dry::Struct::Error, "Timeout must be a hash"
  end
  
  if timeout[:attempt_duration_seconds]
    unless timeout[:attempt_duration_seconds].is_a?(Integer) && timeout[:attempt_duration_seconds] >= 60
      raise Dry::Struct::Error, "Timeout duration must be at least 60 seconds"
    end
  end
  
  true
end
```

### Workload-Specific Retry/Timeout Patterns

**Data Processing**: 
- Retry: 3-5 attempts (fault-tolerant)
- Timeout: 1-2 hours (predictable processing time)

**ML Training**:
- Retry: 1-2 attempts (expensive to retry)
- Timeout: 4-24 hours (long-running training)

**Real-time Processing**:
- Retry: 1 attempt (latency-sensitive)
- Timeout: 1-5 minutes (quick response required)

**Batch Processing**:
- Retry: 5-10 attempts (highly fault-tolerant)
- Timeout: 2-8 hours (long-running background tasks)

## Volume and Storage Management

### EFS Volume Configuration

```ruby
def self.efs_volume(volume_name, file_system_id, options = {})
  {
    name: volume_name,
    efs_volume_configuration: {
      file_system_id: file_system_id,
      root_directory: options[:root_directory] || "/",
      transit_encryption: options[:transit_encryption] || "ENABLED",
      authorization_config: options[:authorization_config]
    }.compact
  }
end
```

### Host Volume Configuration

```ruby
def self.host_volume(volume_name, host_path)
  {
    name: volume_name,
    host: {
      source_path: host_path
    }
  }
end
```

### Mount Point Configuration

```ruby
def self.standard_mount_point(volume_name, container_path, read_only = false)
  {
    source_volume: volume_name,
    container_path: container_path,
    read_only: read_only
  }
end
```

### Storage Patterns

**Shared Data Processing**:
- Use EFS volumes for shared datasets
- Mount as read-write for processing jobs
- Enable transit encryption for security

**Temporary Storage**:
- Use host volumes for temporary files
- Mount `/tmp` for scratch space
- Clean up after job completion

**Model Storage**:
- Use EFS for shared model files
- Mount as read-only for inference jobs
- Use access points for security

## Fargate-Specific Configuration

### Required Configuration

```ruby
{
  platform_capabilities: ["FARGATE"],
  container_properties: {
    execution_role_arn: "arn:aws:iam::...", # Required
    network_configuration: {
      assign_public_ip: "DISABLED"         # Usually disabled
    },
    fargate_platform_configuration: {
      platform_version: "LATEST"          # Platform version
    }
  }
}
```

### Fargate Constraints

- **vCPU/Memory Combinations**: Must use valid Fargate combinations
- **No GPU Support**: GPU resources not available
- **No Privileged Containers**: Security restrictions
- **Network Configuration**: Must specify network settings
- **Execution Role**: Required for container image pulls

### Fargate vCPU/Memory Combinations

Valid Fargate configurations:
- 0.25 vCPU: 512, 1024, 2048 MB
- 0.5 vCPU: 1024-4096 MB (1GB increments)
- 1 vCPU: 2048-8192 MB (1GB increments)
- 2 vCPU: 4096-16384 MB (1GB increments)
- 4 vCPU: 8192-30720 MB (1GB increments)

## Environment Variable Management

### Standard Environment Variables

```ruby
def self.standard_environment_variables(options = {})
  base_vars = [
    { name: "AWS_DEFAULT_REGION", value: options[:region] || "us-east-1" },
    { name: "BATCH_JOB_ID", value: "${AWS_BATCH_JOB_ID}" },
    { name: "BATCH_JOB_ATTEMPT", value: "${AWS_BATCH_JOB_ATTEMPT}" }
  ]
  
  # Add custom environment variables
  if options[:custom_vars]
    base_vars.concat(options[:custom_vars])
  end
  
  base_vars
end
```

### AWS Batch Variable Substitution

AWS Batch provides built-in environment variables:
- `${AWS_BATCH_JOB_ID}`: Unique job identifier
- `${AWS_BATCH_JOB_ATTEMPT}`: Current attempt number
- `${AWS_BATCH_JOB_QUEUE}`: Job queue name
- `${AWS_BATCH_COMPUTE_ENVIRONMENT}`: Compute environment name

## Security Considerations

### IAM Role Requirements

**Job Role** (optional):
- Permissions for job execution
- Access to AWS services (S3, DynamoDB, etc.)
- Used by application code

**Execution Role** (required for Fargate):
- Permissions to pull container images
- Write to CloudWatch Logs
- Used by AWS Batch service

### Container Security

**Privileged Containers**:
```ruby
{
  privileged: true,              # Full system access
  readonly_root_filesystem: true # Immutable filesystem
}
```

**User Configuration**:
```ruby
{
  user: "1000:1000"  # Run as specific user:group
}
```

**Network Security**:
- Use private subnets for Fargate jobs
- Configure security groups appropriately
- Disable public IP assignment

## Performance Optimization

### Resource Sizing

**CPU-Intensive Workloads**:
- Higher vCPU allocation
- Standard memory ratios
- Consider compute-optimized instances

**Memory-Intensive Workloads**:
- Higher memory allocation
- Lower vCPU ratios
- Consider memory-optimized instances

**GPU Workloads**:
- Appropriate CPU/memory for GPU utilization
- Multiple GPUs for parallel training
- GPU-optimized container images

### Container Image Optimization

**Image Size**:
- Use minimal base images (Alpine, distroless)
- Multi-stage builds to reduce size
- Remove unnecessary dependencies

**Layer Optimization**:
- Order Dockerfile commands by change frequency
- Combine RUN commands to reduce layers
- Use .dockerignore to exclude unnecessary files

**Registry Strategy**:
- Use Amazon ECR for best performance
- Enable image scanning for security
- Use lifecycle policies for cleanup

## Error Handling and Debugging

### Common Validation Errors

**Name Validation Errors**:
```ruby
# Too long
"this-job-definition-name-is-way-too-long-for-aws-batch-and-exceeds-the-128-character-limit-that-is-enforced"
# Error: "Job definition name must be between 1 and 128 characters"

# Invalid characters
"invalid@job-name!"
# Error: "Job definition name can only contain letters, numbers, hyphens, and underscores"
```

**Container Properties Errors**:
```ruby
# Missing image
{
  container_properties: {
    vcpus: 2,
    memory: 2048
    # Missing required 'image' field
  }
}
# Error: "Container properties must include a non-empty 'image' field"

# Invalid resources
{
  container_properties: {
    image: "my-app:latest",
    vcpus: 0,    # Invalid
    memory: -1   # Invalid
  }
}
# Error: "vCPUs must be a positive integer"
```

**Platform Capability Errors**:
```ruby
# Invalid platform
{
  platform_capabilities: ["INVALID_PLATFORM"]
}
# Error: "Invalid platform capability 'INVALID_PLATFORM'. Valid: EC2, FARGATE"

# GPU on Fargate (not supported)
{
  platform_capabilities: ["FARGATE"],
  container_properties: {
    resource_requirements: [
      { type: "GPU", value: "1" }
    ]
  }
}
# Terraform will fail - GPU not supported on Fargate
```

### Debugging Strategies

**Configuration Testing**:
```ruby
begin
  config = Types::BatchJobDefinitionAttributes.new(attributes)
  puts "Job definition valid: #{config.job_definition_name}"
  puts "Platform support: EC2=#{config.supports_ec2?}, Fargate=#{config.supports_fargate?}"
rescue Dry::Struct::Error => e
  puts "Validation error: #{e.message}"
end
```

**Resource Analysis**:
```ruby
# Analyze job definition configuration
config = Types::BatchJobDefinitionAttributes.new(attributes)

puts "Job: #{config.job_definition_name}"
puts "Type: #{config.is_container_job? ? 'Container' : 'Multi-node'}"
puts "Memory: #{config.estimated_memory_mb} MB" if config.estimated_memory_mb
puts "vCPUs: #{config.estimated_vcpus}" if config.estimated_vcpus
puts "Retry strategy: #{config.has_retry_strategy? ? 'Enabled' : 'Disabled'}"
puts "Timeout: #{config.has_timeout? ? 'Configured' : 'None'}"
```

**Template Testing**:
```ruby
# Test template generation
begin
  template_config = Types::BatchJobDefinitionAttributes.ml_training_job(
    "test-ml-job",
    "tensorflow:latest-gpu",
    {
      vcpus: 8,
      memory: 32768,
      gpu_count: 2
    }
  )
  
  validated = Types::BatchJobDefinitionAttributes.new(template_config)
  puts "Template generated successfully: #{validated.job_definition_name}"
rescue => e
  puts "Template error: #{e.message}"
end
```