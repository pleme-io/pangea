# AWS EKS Fargate Profile Implementation

## Overview

The `aws_eks_fargate_profile` resource implements type-safe creation of EKS Fargate profiles with comprehensive validation for selectors, namespaces, labels, and IAM roles.

## Type System Design

### Core Types

1. **EksFargateProfileAttributes**: Main attributes structure
   - Enforces IAM role ARN format
   - Validates selector count (1-5)
   - Optional subnet specification

2. **FargateSelector**: Pod selector configuration
   - Required namespace field
   - Optional label matching
   - Kubernetes naming validation

## Validation Rules

### Selector Validation
- Minimum 1, maximum 5 selectors per profile
- Namespace is required for each selector
- Labels are optional but validated if present
- No duplicate namespace-only selectors

### Namespace Validation
- Cannot be empty or whitespace
- Standard Kubernetes namespace rules apply
- Must be unique if no labels specified

### Label Validation
- Keys must follow Kubernetes label format
- Cannot have empty keys or values
- Standard DNS subdomain rules

### IAM Role Validation
- Must be valid IAM role ARN format
- Must have proper trust policy for Fargate

## Terraform Synthesis

The resource generates proper Terraform JSON structure:

```hcl
resource "aws_eks_fargate_profile" "example" {
  cluster_name           = "my-cluster"
  fargate_profile_name   = "example-profile"
  pod_execution_role_arn = "arn:aws:iam::123456789012:role/fargate-pod-execution"
  
  subnet_ids = ["subnet-12345", "subnet-67890"]
  
  selector {
    namespace = "production"
    labels = {
      compute = "fargate"
      tier    = "web"
    }
  }
  
  selector {
    namespace = "kube-system"
    labels = {
      k8s-app = "kube-dns"
    }
  }
}
```

## Resource Outputs

The resource provides outputs for integration:

- **Identity**: ID, ARN, profile name
- **Configuration**: Cluster name, role ARN
- **Network**: Subnet IDs used
- **Status**: Profile operational status
- **Tags**: All tags including inherited

## Computed Properties

Properties for profile analysis:
- `namespaces`: Unique namespace list
- `has_labels`: Whether labels are used
- `selector_count`: Number of selectors
- `selectors`: Normalized selector data

## Selector Matching Logic

### How Fargate Selects Pods

1. **Namespace Match**: Pod namespace must match selector
2. **Label Match**: All selector labels must match pod labels
3. **First Match Wins**: First matching selector applies
4. **No Match**: Pod runs on EC2 nodes

### Examples

**Selector**:
```ruby
{
  namespace: "production",
  labels: { tier: "web", compute: "fargate" }
}
```

**Matching Pod**:
```yaml
metadata:
  namespace: production
  labels:
    tier: web
    compute: fargate
    app: nginx  # Extra labels are OK
```

**Non-Matching Pod**:
```yaml
metadata:
  namespace: production
  labels:
    tier: web  # Missing compute: fargate
```

## Design Patterns

### Environment Isolation
```ruby
# Separate profiles for environments
environments = ["dev", "staging", "prod"]
environments.each do |env|
  aws_eks_fargate_profile(:"fargate_#{env}", {
    cluster_name: cluster.name,
    pod_execution_role_arn: role.arn,
    selectors: [{ namespace: env }]
  })
end
```

### Workload Segregation
```ruby
# Different profiles for workload types
workload_profiles = {
  web: { namespace: "frontend", labels: { tier: "web" } },
  api: { namespace: "backend", labels: { tier: "api" } },
  jobs: { namespace: "jobs", labels: { type: "batch" } }
}

workload_profiles.each do |name, selector|
  aws_eks_fargate_profile(:"fargate_#{name}", {
    cluster_name: cluster.name,
    pod_execution_role_arn: role.arn,
    selectors: [selector]
  })
end
```

## Performance Considerations

### Pod Startup Time
- Initial image pulls can be slow
- No image cache like EC2 nodes
- Consider smaller images

### Networking
- Pod gets dedicated ENI
- IP allocation from subnet
- Security group per pod

### Resource Allocation
- CPU/memory automatically allocated
- No overprovisioning
- Billed per resource-second

## Security Considerations

1. **IAM Role**:
   - Least privilege execution role
   - No access to instance metadata
   - Separate from node IAM roles

2. **Network Isolation**:
   - Dedicated ENI per pod
   - Security group per pod
   - No shared networking

3. **Compute Isolation**:
   - Dedicated compute resources
   - No container breakout risk
   - AWS-managed security patches

## Cost Optimization

1. **Profile Strategy**:
   - Group similar workloads
   - Minimize profile count
   - Use labels effectively

2. **Workload Selection**:
   - Variable/bursty workloads
   - Short-lived jobs
   - Development environments

3. **Resource Efficiency**:
   - Right-size pod requests
   - Avoid overprovisioning
   - Monitor actual usage

## Common Issues and Solutions

1. **Pod Not Scheduling**:
   - Issue: "No Fargate profile matches"
   - Solution: Check namespace and labels

2. **Subnet Capacity**:
   - Issue: "InsufficientFreeAddresses"
   - Solution: Use larger subnet CIDR

3. **IAM Permissions**:
   - Issue: "AccessDenied"
   - Solution: Verify execution role

## Testing Considerations

1. **Unit Tests**:
   - Validate selector structure
   - Test label validation
   - Verify namespace uniqueness

2. **Integration Tests**:
   - Test profile creation
   - Verify pod scheduling
   - Check network connectivity

## Limitations and Workarounds

### No DaemonSets
- **Limitation**: Fargate doesn't support DaemonSets
- **Workaround**: Use sidecar containers or init containers

### No Host Access
- **Limitation**: No hostNetwork, hostPID, hostIPC
- **Workaround**: Use EC2 nodes for system workloads

### Storage Limitations
- **Limitation**: Only ephemeral storage
- **Workaround**: Use EFS or external storage

## Future Enhancements

1. **Enhanced Validation**:
   - Subnet availability checks
   - Label format validation
   - Namespace existence checks

2. **Cost Estimation**:
   - Profile cost prediction
   - Workload analysis tools
   - Optimization suggestions

3. **Advanced Features**:
   - Windows container support
   - GPU support (future)
   - Custom compute configurations