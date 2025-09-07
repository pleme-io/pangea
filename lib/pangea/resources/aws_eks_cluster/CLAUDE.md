# AWS EKS Cluster Implementation

## Overview

The `aws_eks_cluster` resource implements type-safe creation of Amazon EKS clusters with comprehensive validation for Kubernetes versions, network configuration, security settings, and logging options.

## Type System Design

### Core Types

1. **EksClusterAttributes**: Main attributes structure with validation
   - Enforces IAM role ARN format
   - Validates Kubernetes versions against supported list
   - Ensures VPC configuration requirements

2. **VpcConfig**: Network configuration with security constraints
   - Minimum 2 subnets for multi-AZ deployment
   - At least one endpoint (public or private) must be enabled
   - CIDR validation for public access ranges

3. **EncryptionConfig**: Envelope encryption for Kubernetes secrets
   - KMS key ARN format validation
   - Currently supports only "secrets" resource type

4. **KubernetesNetworkConfig**: Service networking configuration
   - RFC1918 private IP range validation for service CIDR
   - IP family support (IPv4/IPv6)

5. **ClusterLogging**: Control plane logging configuration
   - Validates against supported log types
   - Structured format for Terraform compatibility

## Validation Rules

### Network Validation
- Minimum 2 subnets in different availability zones
- Either public or private endpoint must be enabled
- Public access CIDRs must be valid CIDR notation

### Version Validation
- Kubernetes versions validated against supported list (1.24-1.29)
- Default version set to 1.28 for stability

### IAM Validation
- Role ARN must match AWS IAM role format
- Format: `arn:aws:iam::ACCOUNT_ID:role/ROLE_NAME`

### Encryption Validation
- KMS key ARN format validation
- Only "secrets" resource type currently supported

## Terraform Synthesis

The resource generates proper Terraform JSON structure:

```hcl
resource "aws_eks_cluster" "example" {
  name     = "example-cluster"
  role_arn = "arn:aws:iam::123456789012:role/eks-cluster-role"
  version  = "1.28"

  vpc_config {
    subnet_ids              = ["subnet-12345", "subnet-67890"]
    endpoint_private_access = true
    endpoint_public_access  = true
    public_access_cidrs     = ["10.0.0.0/8"]
  }

  enabled_cluster_log_types = ["api", "audit"]

  encryption_config {
    resources = ["secrets"]
    provider {
      key_arn = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"
    }
  }
}
```

## Resource Outputs

The resource provides comprehensive outputs for integration:

- **Cluster Identity**: ID, ARN, name, endpoint
- **Security**: Certificate authority data, role ARN
- **Network**: VPC configuration details
- **Version Info**: Kubernetes version, platform version
- **Status**: Cluster status and creation timestamp

## Computed Properties

Properties derived from configuration:
- `encryption_enabled`: Whether encryption is configured
- `logging_enabled`: Whether any logging is enabled
- `private_endpoint`: Private endpoint accessibility
- `public_endpoint`: Public endpoint accessibility
- `log_types`: List of enabled log types

## Integration Patterns

### With Node Groups
```ruby
cluster = aws_eks_cluster(:main, {...})
node_group = aws_eks_node_group(:workers, {
  cluster_name: cluster.name,
  # ...
})
```

### With Add-ons
```ruby
cluster = aws_eks_cluster(:main, {...})
vpc_cni = aws_eks_addon(:vpc_cni, {
  cluster_name: cluster.name,
  addon_name: "vpc-cni"
})
```

### With Fargate
```ruby
cluster = aws_eks_cluster(:main, {...})
fargate = aws_eks_fargate_profile(:serverless, {
  cluster_name: cluster.name,
  # ...
})
```

## Security Considerations

1. **Endpoint Access**: 
   - Private endpoints for production workloads
   - Restrict public access CIDRs to known ranges

2. **Encryption**:
   - Always enable encryption for production clusters
   - Use customer-managed KMS keys

3. **Logging**:
   - Enable audit logs for compliance
   - API logs for troubleshooting

4. **Network Isolation**:
   - Use private subnets for cluster deployment
   - Configure security groups for least privilege

## Performance Optimization

1. **Version Selection**:
   - Use latest stable version for new features
   - Consider compatibility with workloads

2. **Network Configuration**:
   - Proper CIDR sizing for service network
   - Sufficient subnet capacity for pods

3. **Logging**:
   - Enable only necessary log types
   - Configure log retention appropriately

## Common Issues and Solutions

1. **Subnet Requirements**:
   - Issue: "Insufficient subnets"
   - Solution: Provide at least 2 subnets in different AZs

2. **IAM Role**:
   - Issue: "Invalid role ARN"
   - Solution: Ensure role has proper trust policy for EKS

3. **Network Conflicts**:
   - Issue: "Service CIDR overlap"
   - Solution: Choose non-overlapping CIDR ranges

## Testing Considerations

1. **Unit Tests**:
   - Validate type constraints
   - Test validation logic
   - Verify output structure

2. **Integration Tests**:
   - Test with actual AWS resources
   - Validate cluster creation
   - Verify network connectivity

## Future Enhancements

1. **IPv6 Support**:
   - Full dual-stack networking
   - IPv6-only clusters

2. **Additional Encryption**:
   - Support for more resource types
   - Multiple encryption configurations

3. **Advanced Networking**:
   - Custom DNS configuration
   - Service mesh integration