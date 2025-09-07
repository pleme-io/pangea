# AWS Redshift Subnet Group - Technical Documentation

## Architecture Overview

AWS Redshift Subnet Groups define the VPC subnets where Redshift clusters can be deployed. They provide network isolation and enable multi-AZ deployments for high availability.

### Key Concepts

1. **VPC Integration**: Clusters deployed in VPC for network isolation
2. **Multi-AZ Support**: Subnets across availability zones for HA
3. **Network Segmentation**: Separate subnet groups for different environments
4. **Cluster Placement**: Controls where cluster nodes are deployed

## Implementation Details

### Type Safety with Dry::Struct

The `RedshiftSubnetGroupAttributes` class provides validation:

```ruby
# Name validation
- Must start with lowercase letter
- Only lowercase letters, numbers, hyphens
- Maximum 255 characters

# Subnet validation
- Minimum 1 subnet required
- Recommends 2+ subnets for HA
- Each subnet must be valid ID

# High availability validation
- Warns if less than 2 subnets (no multi-AZ)
- Checks for production readiness
```

### Resource Outputs

The resource returns:
- `id` - Subnet group ID
- `name` - Subnet group name
- `arn` - Subnet group ARN

### Computed Properties

1. **multi_az_capable?** - Has 2+ subnets for multi-AZ
2. **has_redundancy?** - Has 3+ subnets for extra redundancy
3. **subnet_count** - Total number of subnets
4. **estimated_az_count** - Estimated AZs covered
5. **production_grade?** - Suitable for production use

## Best Practices

### 1. High Availability Design

```ruby
# Production HA setup
aws_redshift_subnet_group(:ha_subnets, {
  name: "redshift-ha-subnets",
  subnet_ids: [
    private_subnet_az1_ref.id,
    private_subnet_az2_ref.id,
    private_subnet_az3_ref.id
  ],
  description: "Multi-AZ subnet group for HA Redshift",
  tags: {
    HighAvailability: "true",
    FailoverEnabled: "true"
  }
})
```

### 2. Network Isolation

```ruby
# Separate subnet groups by environment
[:prod, :staging, :dev].each do |env|
  aws_redshift_subnet_group(:"#{env}_isolated", {
    name: "redshift-#{env}-isolated",
    subnet_ids: send(:"#{env}_private_subnet_ids"),
    tags: {
      Environment: env.to_s,
      NetworkSegmentation: "enforced"
    }
  })
end
```

### 3. Compliance Requirements

```ruby
# PCI compliant subnet group
aws_redshift_subnet_group(:pci_compliant, {
  name: "redshift-pci-subnets",
  subnet_ids: pci_private_subnet_ids,
  description: "PCI DSS compliant subnet group",
  tags: {
    Compliance: "PCI-DSS",
    DataClassification: "sensitive",
    AuditRequired: "true"
  }
})
```

## Common Patterns

### 1. Multi-Region DR Setup

```ruby
# Primary region
primary_subnet_group = aws_redshift_subnet_group(:primary_region, {
  name: "redshift-primary-subnets",
  subnet_ids: us_east_1_subnet_ids,
  tags: { Region: "primary", Role: "active" }
})

# DR region
dr_subnet_group = aws_redshift_subnet_group(:dr_region, {
  name: "redshift-dr-subnets",
  subnet_ids: us_west_2_subnet_ids,
  tags: { Region: "dr", Role: "standby" }
})
```

### 2. Workload Segregation

```ruby
workload_subnets = {
  etl: { subnets: etl_subnet_ids, isolation: "high" },
  analytics: { subnets: analytics_subnet_ids, isolation: "medium" },
  reporting: { subnets: reporting_subnet_ids, isolation: "low" }
}

workload_subnets.each do |workload, config|
  aws_redshift_subnet_group(:"#{workload}_segregated", {
    name: "redshift-#{workload}-segregated",
    subnet_ids: config[:subnets],
    tags: {
      Workload: workload.to_s,
      IsolationLevel: config[:isolation]
    }
  })
end
```

### 3. Cost-Optimized Development

```ruby
# Minimal dev setup
aws_redshift_subnet_group(:dev_minimal, {
  name: "redshift-dev-minimal",
  subnet_ids: dev_subnet_ids.first(2), # Only 2 AZs for cost
  description: "Cost-optimized dev subnet group",
  tags: {
    Environment: "development",
    CostOptimized: "true"
  }
})
```

## Integration Examples

### With VPC Architecture

```ruby
# VPC with dedicated Redshift subnets
vpc_ref = aws_vpc(:analytics_vpc, {
  cidr_block: "10.0.0.0/16"
})

# Create dedicated Redshift subnets
redshift_subnets = ["a", "b", "c"].map do |az|
  aws_subnet(:"redshift_subnet_#{az}", {
    vpc_id: vpc_ref.id,
    cidr_block: "10.0.#{100 + az.ord - 97}.0/24",
    availability_zone: "us-east-1#{az}",
    tags: { Type: "redshift" }
  })
end

# Create subnet group
aws_redshift_subnet_group(:dedicated_redshift, {
  name: "dedicated-redshift-subnets",
  subnet_ids: redshift_subnets.map(&:id),
  description: "Dedicated subnets for Redshift clusters"
})
```

### With Security Architecture

```ruby
# Subnet group with security controls
subnet_group_ref = aws_redshift_subnet_group(:secure_subnets, {
  name: "secure-redshift-subnets",
  subnet_ids: private_subnet_ids
})

# Restrictive security group
security_group_ref = aws_security_group(:redshift_sg, {
  name: "redshift-security-group",
  vpc_id: vpc_ref.id,
  ingress: [{
    from_port: 5439,
    to_port: 5439,
    protocol: "tcp",
    cidr_blocks: ["10.0.0.0/16"] # Only VPC internal
  }]
})

# Secure Redshift cluster
aws_redshift_cluster(:secure_warehouse, {
  cluster_identifier: "secure-warehouse",
  cluster_subnet_group_name: subnet_group_ref.outputs[:name],
  vpc_security_group_ids: [security_group_ref.id],
  encrypted: true
})
```

## Troubleshooting

### Common Issues

1. **Subnet Availability**
   - Ensure subnets are in different AZs
   - Verify subnets have available IP addresses
   - Check subnet route tables for connectivity

2. **Multi-AZ Failures**
   - Minimum 2 subnets required for multi-AZ
   - Subnets must be in different AZs
   - All subnets must be in same VPC

3. **Network Connectivity**
   - Verify subnet has route to internet (for public clusters)
   - Check NAT gateway for private subnets
   - Ensure security groups allow Redshift traffic

## Network Architecture Considerations

### Subnet Planning

```ruby
# Calculate subnet sizing for Redshift
# Each node needs 1 IP, plus overhead
def calculate_subnet_size(max_nodes)
  overhead = 5 # AWS reserved IPs
  required_ips = max_nodes + overhead
  
  # Find minimum subnet size
  cidr_bits = (Math.log2(required_ips).ceil + 1)
  subnet_size = 32 - cidr_bits
  
  "/#{subnet_size}"
end

# Example: 16-node cluster needs /27 subnet minimum
```

### AZ Distribution

```ruby
# Ensure even distribution across AZs
def validate_az_distribution(subnet_ids)
  # In practice, would query actual AZs
  az_count = subnet_ids.length
  
  if az_count < 2
    "Warning: Single AZ deployment"
  elsif az_count == 2
    "Standard: Dual AZ deployment"
  else
    "Optimal: Multi-AZ deployment (#{az_count} AZs)"
  end
end
```