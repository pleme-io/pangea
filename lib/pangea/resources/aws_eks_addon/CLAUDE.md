# AWS EKS Add-on Implementation

## Overview

The `aws_eks_addon` resource implements type-safe management of EKS add-ons with comprehensive validation for add-on names, versions, IAM integration, and configuration options.

## Type System Design

### Core Types

1. **EksAddonAttributes**: Main attributes structure with validation
   - Enforces valid add-on names from supported list
   - Version validation against known versions per add-on
   - IAM role ARN format validation
   - JSON configuration validation

### Add-on Registry

The implementation maintains a comprehensive registry of supported add-ons:

```ruby
SUPPORTED_ADDONS = {
  'vpc-cni' => {
    versions: [...],
    service_account: 'aws-node',
    namespace: 'kube-system',
    description: 'Amazon VPC CNI plugin for Kubernetes'
  },
  # ... other add-ons
}
```

This registry enables:
- Version validation
- Service account mapping
- Namespace identification
- IAM requirement detection

## Validation Rules

### Add-on Name Validation
- Must be from the supported add-ons list
- Case-sensitive matching
- Provides clear error messages for invalid names

### Version Validation
- Optional but validated if provided
- Must match known versions for the add-on
- Defaults to latest if not specified

### Configuration Validation
- Must be valid JSON if provided
- Parsed and validated during type construction
- Supports complex nested configurations

### Conflict Resolution
- Mutually exclusive resolve_conflicts options
- Separate create/update strategies
- Valid options: OVERWRITE, NONE, PRESERVE

## Terraform Synthesis

The resource generates proper Terraform JSON structure:

```hcl
resource "aws_eks_addon" "example" {
  cluster_name             = "my-cluster"
  addon_name               = "vpc-cni"
  addon_version           = "v1.12.6-eksbuild.2"
  service_account_role_arn = "arn:aws:iam::123456789012:role/vpc-cni-role"
  
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "PRESERVE"
  
  configuration_values = jsonencode({
    env = {
      ENABLE_PREFIX_DELEGATION = "true"
    }
  })
  
  preserve = true
}
```

## Resource Outputs

The resource provides comprehensive outputs:

- **Identity**: ID, ARN
- **Version Info**: Current version, timestamps
- **Status**: Add-on operational status
- **Configuration**: Applied configuration values
- **Tags**: All tags including inherited

## Computed Properties

Properties derived from add-on metadata:
- `addon_name`: The add-on identifier
- `service_account`: Associated Kubernetes service account
- `namespace`: Kubernetes namespace for deployment
- `requires_iam_role`: Whether IRSA is required
- `is_*_addon`: Category classification (compute, storage, etc.)
- `addon_description`: Human-readable description

## Add-on Categories

### Networking Add-ons
- **vpc-cni**: Pod networking with AWS VPC integration
- **coredns**: Cluster DNS resolution

### Compute Add-ons
- **kube-proxy**: Service networking proxy

### Storage Add-ons
- **aws-ebs-csi-driver**: EBS volume support
- **aws-efs-csi-driver**: EFS file system support
- **aws-mountpoint-s3-csi-driver**: S3 bucket mounting
- **snapshot-controller**: Volume snapshot management

### Observability Add-ons
- **aws-guardduty-agent**: Security threat detection
- **adot**: OpenTelemetry distribution

## IAM Integration

### IRSA (IAM Roles for Service Accounts)
Add-ons requiring AWS API access use IRSA:

1. **OIDC Provider**: Cluster must have OIDC provider
2. **Trust Policy**: Role trusts OIDC provider with conditions
3. **Service Account**: Kubernetes service account annotation
4. **Pod Identity**: Pods assume role via service account

### Required Policies by Add-on
- **vpc-cni**: AmazonEKS_CNI_Policy
- **ebs-csi**: AmazonEBSCSIDriverPolicy
- **efs-csi**: AmazonEFSCSIDriverPolicy
- **guardduty**: Custom GuardDuty policies
- **s3-csi**: S3 access policies

## Configuration Management

### Configuration Values
- JSON string for add-on-specific settings
- Validated during resource creation
- Applied during add-on installation

### Common Configurations

**VPC CNI**:
```json
{
  "env": {
    "ENABLE_PREFIX_DELEGATION": "true",
    "WARM_PREFIX_TARGET": "1"
  }
}
```

**CoreDNS**:
```json
{
  "computeType": "Fargate",
  "replicaCount": 3,
  "resources": {
    "limits": {
      "cpu": "100m",
      "memory": "150Mi"
    }
  }
}
```

## Conflict Resolution Strategies

### NONE (Default)
- Fails if conflicts exist
- Safest option for production
- Requires manual conflict resolution

### OVERWRITE
- Replaces existing resources
- Use with caution in production
- Helpful for initial setup

### PRESERVE
- Keeps existing resources
- Merges where possible
- Good for incremental updates

## Version Management

### Version Selection
- Latest version if not specified
- Compatibility with cluster version
- Validated against known versions

### Upgrade Considerations
- Test in non-production first
- Review release notes
- Plan for potential disruptions

## Security Considerations

1. **IAM Roles**:
   - Least privilege policies
   - Service account isolation
   - Regular permission audits

2. **Configuration Security**:
   - No secrets in configuration_values
   - Use Kubernetes secrets instead
   - Encrypt sensitive data

3. **Network Security**:
   - VPC CNI security groups
   - Network policies
   - Private endpoint usage

## Performance Optimization

1. **Resource Allocation**:
   - Configure appropriate limits
   - Scale replicas for availability
   - Monitor resource usage

2. **Configuration Tuning**:
   - VPC CNI warm pool settings
   - CoreDNS cache configuration
   - CSI driver performance options

## Common Issues and Solutions

1. **Version Mismatch**:
   - Issue: "Incompatible version"
   - Solution: Check cluster version compatibility

2. **IAM Permissions**:
   - Issue: "AccessDenied"
   - Solution: Verify IRSA configuration

3. **Conflicts**:
   - Issue: "Resource exists"
   - Solution: Use appropriate conflict resolution

## Testing Considerations

1. **Unit Tests**:
   - Validate add-on names
   - Test version constraints
   - Verify JSON parsing

2. **Integration Tests**:
   - Test add-on installation
   - Verify IAM integration
   - Check configuration application

## Future Enhancements

1. **Dynamic Version Discovery**:
   - API-based version listing
   - Automatic compatibility checking

2. **Configuration Schemas**:
   - Add-on specific validation
   - Type-safe configuration builders

3. **Health Monitoring**:
   - Add-on health checks
   - Automated remediation
   - Performance metrics