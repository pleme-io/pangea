# AwsVpcEndpointService Implementation Documentation

## Overview

This directory contains the implementation for the `aws_vpc_endpoint_service` resource function, providing type-safe creation and management of AWS VPC Endpoint Service resources through terraform-synthesizer integration.

VPC endpoint services enable you to expose your own application services (running behind Network Load Balancers or Gateway Load Balancers) to other VPCs through AWS PrivateLink, creating secure, private connectivity without internet routing.

## Implementation Architecture

### Core Components

#### 1. Resource Function (`resource.rb`)
The main `aws_vpc_endpoint_service` function that:
- Accepts a symbol name and attributes hash
- Validates attributes using dry-struct types  
- Generates terraform resource blocks via terraform-synthesizer
- Returns ResourceReference with computed outputs and properties
- Maps all AWS VPC endpoint service parameters to terraform syntax

#### 2. Type Definitions (`types.rb`)
VpcEndpointServiceAttributes dry-struct defining:
- **Required attributes**: `acceptance_required` (Boolean)
- **Optional attributes**: Load balancer ARNs, IP types, DNS configuration, principals, tags
- **Custom validations**: Load balancer requirement, ARN format, mutual exclusions
- **Computed properties**: Service capabilities and configuration status

#### 3. Documentation
- **CLAUDE.md** (this file): Implementation details for developers
- **README.md**: User-facing documentation with comprehensive examples

## Technical Implementation Details

### AWS VPC Endpoint Service Overview
AWS VPC endpoint services allow you to:
- Expose services behind Network Load Balancers (NLBs) or Gateway Load Balancers (GWLBs)
- Enable other VPCs to connect privately through VPC endpoints
- Control access through acceptance requirements and allowed principals
- Provide custom DNS names for your services
- Support both IPv4 and IPv6 connectivity

### Key Features and Constraints
- **Load Balancer Requirement**: Must specify either NLB or GWLB ARNs (but not both)
- **Regional Service**: Resources are region-specific
- **State Management**: Services have states (Available, Pending, Failed, etc.)
- **DNS Integration**: Optional private DNS name configuration with domain verification
- **Access Control**: Configurable acceptance requirements and principal allowlists

### Type Validation Logic

```ruby
class VpcEndpointServiceAttributes < Dry::Struct
  # Core validation ensures exactly one load balancer type is specified
  def self.new(attributes = {})
    attrs = super(attributes)
    
    # Must have at least one load balancer type
    if attrs.network_load_balancer_arns.empty? && attrs.gateway_load_balancer_arns.empty?
      raise Dry::Struct::Error, "Must specify either 'network_load_balancer_arns' or 'gateway_load_balancer_arns'"
    end
    
    # Cannot have both load balancer types
    if attrs.network_load_balancer_arns.any? && attrs.gateway_load_balancer_arns.any?
      raise Dry::Struct::Error, "Cannot specify both 'network_load_balancer_arns' and 'gateway_load_balancer_arns'"
    end
    
    # Validate ARN formats
    all_arns = attrs.network_load_balancer_arns + attrs.gateway_load_balancer_arns
    all_arns.each do |arn|
      unless arn.match?(/^arn:aws:elasticloadbalancing:/)
        raise Dry::Struct::Error, "Invalid load balancer ARN format: #{arn}"
      end
    end
    
    attrs
  end
end
```

### Terraform Synthesis

The resource function generates terraform JSON through terraform-synthesizer:

```ruby
resource(:aws_vpc_endpoint_service, name) do
  # Required parameter
  acceptance_required attrs.acceptance_required
  
  # Conditional load balancer configuration
  if attrs.network_load_balancer_arns.any?
    network_load_balancer_arns attrs.network_load_balancer_arns
  end
  
  if attrs.gateway_load_balancer_arns.any?
    gateway_load_balancer_arns attrs.gateway_load_balancer_arns
  end
  
  # Optional configurations
  if attrs.supported_ip_address_types.any?
    supported_ip_address_types attrs.supported_ip_address_types
  end
  
  if attrs.private_dns_name
    private_dns_name attrs.private_dns_name
  end
  
  # Nested configuration blocks
  if attrs.private_dns_name_configuration.any?
    private_dns_name_configuration do
      attrs.private_dns_name_configuration.each do |key, value|
        public_send(key, value)
      end
    end
  end
end
```

### ResourceReference Return Value

The function returns a ResourceReference providing:

#### Terraform Outputs
- `id`: Unique service identifier
- `arn`: Service ARN for IAM policies
- `service_name`: Service name for VPC endpoint creation (most important output)
- `service_type`: Interface or Gateway service type
- `state`: Current service state (Available, Pending, etc.)
- `availability_zones`: AZs where service is available
- `base_endpoint_dns_names`: DNS names for VPC endpoints
- `manages_vpc_endpoints`: Whether service manages endpoint lifecycle
- `private_dns_name_configuration`: DNS configuration details

#### Computed Properties
- `requires_acceptance?`: Whether manual acceptance is required
- `uses_network_load_balancers?`: Whether using NLBs
- `uses_gateway_load_balancers?`: Whether using GWLBs
- `has_private_dns?`: Whether private DNS is configured
- `has_allowed_principals?`: Whether access is restricted
- `load_balancer_type`: `:network`, `:gateway`, or `:none`
- `supports_ipv6?`: Whether IPv6 is supported
- `supports_ipv4?`: Whether IPv4 is supported

## Integration Patterns

### 1. Basic NLB Service Exposure
```ruby
template :api_service do
  # Create service endpoint for API behind NLB
  api_endpoint_service = aws_vpc_endpoint_service(:api_service, {
    acceptance_required: false,
    network_load_balancer_arns: [nlb_ref.arn],
    tags: { Name: "api-service", Environment: "prod" }
  })
  
  # Output service name for consumer VPC endpoint creation
  output :api_service_name do
    value api_endpoint_service.service_name
  end
end
```

### 2. Gateway Load Balancer Security Service
```ruby
template :security_inspection do
  # Expose traffic inspection service via GWLB
  inspection_service = aws_vpc_endpoint_service(:inspection, {
    acceptance_required: true,  # Require manual approval
    gateway_load_balancer_arns: [gwlb_ref.arn],
    allowed_principals: ["arn:aws:iam::123456789012:root"],
    tags: { Purpose: "security-inspection" }
  })
end
```

### 3. Cross-Account Service Sharing
```ruby
template :shared_service do
  # Service accessible by specific external accounts
  shared_service = aws_vpc_endpoint_service(:shared_data_api, {
    acceptance_required: false,
    network_load_balancer_arns: [data_api_nlb.arn],
    allowed_principals: [
      "arn:aws:iam::111122223333:root",  # Partner account
      "arn:aws:iam::444455556666:root"   # Customer account
    ],
    private_dns_name: "data-api.shared.company.com",
    supported_ip_address_types: ["ipv4", "ipv6"]
  })
end
```

## Error Handling and Validation

### Common Validation Errors

1. **Missing Load Balancer Configuration**
   ```
   Dry::Struct::Error: Must specify either 'network_load_balancer_arns' or 'gateway_load_balancer_arns'
   ```
   Solution: Specify exactly one type of load balancer ARN array

2. **Conflicting Load Balancer Types**
   ```
   Dry::Struct::Error: Cannot specify both 'network_load_balancer_arns' and 'gateway_load_balancer_arns'
   ```
   Solution: Use only NLB or GWLB ARNs, not both

3. **Invalid ARN Format**
   ```
   Dry::Struct::Error: Invalid load balancer ARN format: invalid-arn
   ```
   Solution: Ensure ARNs follow AWS ELB ARN format

4. **Invalid Principal ARN**
   ```
   Dry::Struct::Error: Invalid principal ARN format: invalid-principal
   ```
   Solution: Use proper IAM ARN format for principals

### Terraform-Level Errors
- Load balancer not found: Ensure LB exists and is active
- DNS name conflicts: Verify private DNS name availability
- Permission denied: Ensure IAM permissions for VPC endpoint service operations

## Testing Strategy

### Unit Tests
```ruby
RSpec.describe Pangea::Resources::AWS do
  describe "#aws_vpc_endpoint_service" do
    it "creates service with NLB" do
      service = aws_vpc_endpoint_service(:test, {
        acceptance_required: false,
        network_load_balancer_arns: ["arn:aws:elasticloadbalancing:us-east-1:123:loadbalancer/net/test/abc123"]
      })
      
      expect(service.uses_network_load_balancers?).to be true
      expect(service.load_balancer_type).to eq :network
    end
    
    it "validates load balancer requirement" do
      expect {
        aws_vpc_endpoint_service(:invalid, {
          acceptance_required: false
        })
      }.to raise_error(Dry::Struct::Error, /Must specify either/)
    end
  end
end
```

### Integration Tests
- Test with actual AWS resources in development environment
- Verify service creation and VPC endpoint connectivity
- Test DNS name resolution and traffic routing

## Security Best Practices

### Access Control
- Use `acceptance_required: true` for sensitive services
- Restrict access with `allowed_principals` for specific accounts/users
- Apply least-privilege IAM policies for service management

### Network Security
- Configure security groups on load balancer targets appropriately
- Use private DNS names to avoid exposing internal service details
- Monitor VPC endpoint connections through CloudWatch

### Operational Security
- Tag resources consistently for access control and auditing
- Use separate services for different security domains
- Implement proper backup and disaster recovery for critical services

## Performance Considerations

### Load Balancer Optimization
- Use multiple NLBs across AZs for high availability
- Configure appropriate health checks with reasonable timeouts
- Size load balancers based on expected VPC endpoint traffic

### DNS Configuration
- Use private DNS names for better client experience
- Consider DNS caching implications for failover scenarios
- Verify DNS resolution from consumer VPCs

## Cost Optimization

### Usage-Based Pricing
- VPC endpoint services incur charges based on:
  - Hourly charges per VPC endpoint
  - Data processing charges per GB
  - No additional charges for the service itself

### Optimization Strategies
- Use automatic acceptance to reduce operational overhead
- Monitor data transfer patterns to optimize load balancer placement
- Consolidate services where appropriate to reduce endpoint count

## Future Enhancements

### Potential Improvements
1. **Enhanced DNS Integration**: Automatic Route 53 record management
2. **Health Check Integration**: Automated health check configuration
3. **Multi-Region Support**: Cross-region service exposure patterns
4. **Cost Monitoring**: Built-in cost estimation and tracking
5. **Security Hardening**: Automated security group and NACL configuration
6. **Compliance Support**: Built-in compliance policy validation

### Architecture Extensions
This resource serves as the foundation for higher-level architecture functions like:
- `microservices_platform_architecture`: Automatic service exposure
- `api_gateway_architecture`: API service exposure patterns
- `security_inspection_architecture`: GWLB-based inspection services
