# AWS EKS Node Group Implementation

## Overview

The `aws_eks_node_group` resource implements type-safe creation of EKS managed node groups with comprehensive validation for instance types, AMI types, scaling configurations, and Kubernetes-specific settings like labels and taints.

## Type System Design

### Core Types

1. **EksNodeGroupAttributes**: Main attributes structure with validation
   - Enforces IAM role ARN format
   - Validates instance type compatibility with AMI types
   - Ensures proper scaling configuration relationships

2. **ScalingConfig**: Auto-scaling configuration with constraints
   - Validates min <= desired <= max relationship
   - Ensures non-negative values
   - Provides sensible defaults

3. **UpdateConfig**: Rolling update configuration
   - Mutually exclusive max_unavailable options
   - Percentage validation (1-100)
   - Supports both absolute and percentage-based updates

4. **RemoteAccess**: SSH access configuration
   - Optional SSH key pair
   - Security group validation for access control

5. **LaunchTemplate**: Custom launch template reference
   - Mutually exclusive ID/name validation
   - Optional version specification

6. **Taint**: Kubernetes taint configuration
   - Effect validation against Kubernetes spec
   - Optional value field
   - Proper key/effect requirements

## Validation Rules

### Instance Type Validation
- ARM AMI types require ARM-compatible instances (a1, t4g, m6g, etc.)
- GPU AMI types require GPU instances (p3, p4, g4dn, etc.)
- Instance types must be valid EC2 instance types

### Scaling Validation
- min_size <= desired_size <= max_size
- All values must be non-negative
- min_size can be 0 for scale-to-zero scenarios

### AMI Type Validation
- Validates against supported AMI types
- Includes Amazon Linux 2, Bottlerocket variants
- GPU and ARM variants properly validated

### Update Configuration
- Only one of max_unavailable or max_unavailable_percentage
- Percentage must be between 1-100
- Absolute value must be >= 1

## Terraform Synthesis

The resource generates proper Terraform JSON structure:

```hcl
resource "aws_eks_node_group" "example" {
  cluster_name    = "my-cluster"
  node_group_name = "example-workers"
  node_role_arn   = "arn:aws:iam::123456789012:role/eks-node-role"
  subnet_ids      = ["subnet-12345", "subnet-67890"]

  scaling_config {
    desired_size = 3
    max_size     = 5
    min_size     = 1
  }

  instance_types = ["m5.large", "m5a.large"]
  capacity_type  = "SPOT"
  
  labels = {
    workload = "general"
    lifecycle = "spot"
  }
  
  taint {
    key    = "spot"
    value  = "true"
    effect = "NO_SCHEDULE"
  }
}
```

## Resource Outputs

The resource provides comprehensive outputs:

- **Identity**: ID, ARN, name
- **Configuration**: Instance types, capacity type, disk size
- **Scaling**: Current configuration and status
- **Kubernetes**: Labels, taints, version
- **Networking**: Subnets, remote access config
- **Lifecycle**: Status, version, update config

## Computed Properties

Properties derived from configuration:
- `spot_instances`: Whether using spot capacity
- `custom_ami`: Whether using custom AMI
- `has_remote_access`: SSH access configured
- `has_taints`: Kubernetes taints present
- `has_labels`: Kubernetes labels present
- `ami_type`: Current AMI type
- `desired_size`: Current desired capacity

## Integration Patterns

### With EKS Cluster
```ruby
cluster = aws_eks_cluster(:main, {...})
node_group = aws_eks_node_group(:workers, {
  cluster_name: cluster.name,
  # ...
})
```

### With Launch Templates
```ruby
template = aws_launch_template(:custom, {...})
node_group = aws_eks_node_group(:custom_workers, {
  launch_template: {
    id: template.id,
    version: "$Latest"
  }
})
```

### With Auto Scaling
```ruby
# Node group handles its own auto-scaling
# Can be integrated with Cluster Autoscaler
node_group = aws_eks_node_group(:auto_scaled, {
  scaling_config: {
    min_size: 0,
    max_size: 100,
    desired_size: 3
  }
})
```

## Instance Type Strategies

### Spot Instance Diversification
- Multiple instance types increase spot availability
- Mix instance families (m5, m5a, m5n)
- Include different sizes for flexibility

### GPU Workloads
- Use GPU-optimized AMI types
- Select appropriate GPU instances
- Apply proper taints for scheduling

### ARM Migration
- Use ARM AMI types (AL2_ARM_64)
- Select Graviton instances (t4g, m6g)
- Often 20-40% cost savings

## Kubernetes Integration

### Labels
- Applied to all nodes in group
- Used for pod scheduling
- Examples: environment, workload type, team

### Taints
- Prevent pod scheduling by default
- Require tolerations on pods
- Common: spot instances, GPU nodes, specialized workloads

### Node Selectors
- Work with labels for pod placement
- Enable workload segregation
- Support multi-tenant clusters

## Security Considerations

1. **IAM Roles**:
   - Least privilege for node role
   - Required AWS managed policies
   - Additional policies as needed

2. **Network Security**:
   - Private subnet deployment
   - Security group restrictions
   - No SSH access in production

3. **Kubernetes Security**:
   - Pod security policies
   - Network policies
   - Admission controllers

## Performance Optimization

1. **Instance Selection**:
   - Latest generation instances
   - Appropriate sizing for workloads
   - Network-optimized instances if needed

2. **Scaling Configuration**:
   - Appropriate min/max for workload
   - Update configuration for safe rollouts
   - Integration with metrics

3. **AMI Selection**:
   - Bottlerocket for security/performance
   - GPU AMIs only when needed
   - Custom AMIs for specific requirements

## Common Issues and Solutions

1. **Instance Type Availability**:
   - Issue: "Insufficient capacity"
   - Solution: Diversify instance types

2. **Scaling Delays**:
   - Issue: "Slow scale-up"
   - Solution: Pre-warm with higher min_size

3. **Pod Scheduling**:
   - Issue: "Pods pending"
   - Solution: Check taints/tolerations

## Testing Considerations

1. **Unit Tests**:
   - Validate type constraints
   - Test AMI/instance compatibility
   - Verify scaling relationships

2. **Integration Tests**:
   - Test node group creation
   - Verify node registration
   - Check label/taint application

## Future Enhancements

1. **Windows Support**:
   - Windows AMI types
   - Windows-specific configuration

2. **Custom AMI Validation**:
   - AMI existence checks
   - Compatibility validation

3. **Advanced Scheduling**:
   - Pod disruption budgets
   - Priority classes
   - Affinity rules