# AWS ECS Task Definition Implementation

## Overview

The `aws_ecs_task_definition` resource implements comprehensive container task definitions with deep validation, Fargate compatibility checking, and complex container configuration support.

## Type System Design

### EcsContainerDefinition

A comprehensive container configuration type with:

1. **Core Container Settings**
   - `name`, `image` - Required identifiers
   - `cpu`, `memory`, `memory_reservation` - Resource allocation
   - `essential` - Determines task failure behavior

2. **Networking**
   - `port_mappings` - With protocol and app protocol support
   - `dns_servers`, `dns_search_domains` - DNS configuration
   - `extra_hosts` - Custom host entries

3. **Configuration & Secrets**
   - `environment` - Plain environment variables
   - `secrets` - Parameter Store/Secrets Manager integration
   - `docker_labels` - Container metadata

4. **Logging**
   - `log_configuration` - Multiple driver support (awslogs, fluentd, etc.)
   - `firelens_configuration` - AWS FireLens integration

5. **Storage**
   - `mount_points` - Volume mounts
   - `volumes_from` - Share volumes between containers

6. **Runtime Behavior**
   - `entry_point`, `command` - Execution configuration
   - `working_directory` - Container working directory
   - `user` - User context
   - `privileged`, `readonly_root_filesystem` - Security settings

7. **Advanced Linux Settings**
   - `linux_parameters` - Capabilities, devices, tmpfs
   - `ulimits` - Resource limits
   - `system_controls` - Kernel parameters

### EcsTaskDefinitionAttributes

The main task definition type with:

1. **Task Configuration**
   - `family` - Task family name
   - `container_definitions` - Array of containers (at least one required)
   - `network_mode` - Bridge, host, awsvpc, none

2. **Compatibility & Resources**
   - `requires_compatibilities` - EC2, FARGATE, EXTERNAL
   - `cpu`, `memory` - Task-level allocation (required for Fargate)
   - Validates Fargate CPU/memory combinations

3. **Volumes**
   - Host volumes
   - Docker volumes with drivers
   - EFS volumes with encryption
   - FSx Windows file server volumes

4. **Advanced Features**
   - `placement_constraints` - Container placement rules
   - `proxy_configuration` - App Mesh integration
   - `runtime_platform` - OS and architecture
   - `ephemeral_storage` - Extended temporary storage

## Key Validation Rules

### Fargate Validation

When `requires_compatibilities` includes FARGATE:
- `cpu` and `memory` must be specified
- `network_mode` must be "awsvpc"
- `execution_role_arn` is required
- CPU/memory must be valid Fargate combinations

### Network Mode Validation

For `awsvpc` mode:
- Host ports must equal container ports or be omitted
- This prevents port mapping conflicts

### Container Validation

- At least one container must be marked `essential`
- Memory reservation cannot exceed memory limit
- Image URI format is validated
- Volume references are checked for existence

### Volume Reference Validation

All container mount points must reference defined volumes.

## Container Definition JSON Generation

The implementation converts Ruby container definitions to Terraform-compatible JSON:

```ruby
# Ruby input
container_definitions: [{
  name: "web",
  image: "nginx:latest",
  port_mappings: [{
    container_port: 80
  }]
}]

# JSON output (camelCase)
[{
  "name": "web",
  "image": "nginx:latest",
  "essential": true,
  "portMappings": [{
    "containerPort": 80
  }]
}]
```

Key conversions:
- Snake_case to camelCase (memory_reservation → memoryReservation)
- Optional fields only included if present
- Nested structures properly converted

## Helper Methods

### Compatibility Checks

```ruby
task_def.fargate_compatible?  # Has FARGATE in compatibilities
task_def.uses_efs?           # Has EFS volume configurations
```

### Resource Calculations

```ruby
task_def.total_memory_mb      # Sum of container memory
task_def.estimated_hourly_cost # Fargate pricing estimate
```

### Container Access

```ruby
task_def.main_container  # First essential container
```

## Resource Synthesis

The implementation handles:

1. **JSON Generation** - Container definitions as formatted JSON
2. **Conditional Blocks** - Only synthesize present configurations
3. **Nested Structures** - Properly handle volume configurations
4. **Array Handling** - Multiple volumes, constraints, accelerators

## Outputs

Standard outputs:
- `arn` - Full ARN with revision
- `arn_without_revision` - Stable ARN for references
- `family` - Task family name
- `revision` - Latest revision number
- `id` - Compound family:revision

## Computed Properties

Additional computed values:
- `fargate_compatible` - Launch type check
- `uses_efs` - Storage type detection
- `total_memory_mb` - Resource calculation
- `estimated_hourly_cost` - Cost estimation
- `main_container_name` - Primary container
- `container_names` - All container names
- `essential_container_count` - Critical container count

## Integration Patterns

### With ECS Services

```ruby
task_def = aws_ecs_task_definition(:web, {...})
service = aws_ecs_service(:web_service, {
  task_definition: task_def.arn,
  ...
})
```

### With IAM Roles

```ruby
execution_role = aws_iam_role(:ecs_execution, {...})
task_role = aws_iam_role(:app_task, {...})

task_def = aws_ecs_task_definition(:app, {
  execution_role_arn: execution_role.arn,
  task_role_arn: task_role.arn,
  ...
})
```

## Design Decisions

1. **Separate Container Type** - Reusable across different contexts
2. **JSON Generation** - Handles Terraform's JSON string requirement
3. **Comprehensive Validation** - Catches errors at Ruby level
4. **Fargate Focus** - Special handling for Fargate requirements
5. **Helper Methods** - Simplify common calculations

## Complex Features

### EFS Volume Configuration

Full support for encrypted EFS with access points:

```ruby
volumes: [{
  name: "shared-data",
  efs_volume_configuration: {
    file_system_id: "fs-12345678",
    transit_encryption: "ENABLED",
    authorization_config: {
      access_point_id: "fsap-12345678",
      iam: "ENABLED"
    }
  }
}]
```

### Proxy Configuration for App Mesh

Complete App Mesh sidecar support:

```ruby
proxy_configuration: {
  type: "APPMESH",
  container_name: "envoy",
  properties: [
    { name: "ProxyIngressPort", value: "15000" },
    { name: "ProxyEgressPort", value: "15001" }
  ]
}
```

### Linux Parameters

Advanced container settings:

```ruby
linux_parameters: {
  capabilities: {
    add: ["SYS_ADMIN"],
    drop: ["NET_ADMIN"]
  },
  init_process_enabled: true,
  shared_memory_size: 256
}
```

## Testing Considerations

Key test scenarios:
1. Fargate CPU/memory combination validation
2. Network mode and port mapping rules
3. Essential container requirements
4. Volume reference integrity
5. Container definition JSON formatting
6. Cost calculation accuracy

## Future Enhancements

Potential improvements:
1. Container image tag validation
2. Log group auto-creation
3. Sidecar pattern helpers
4. Blue/green deployment support
5. Container insights integration