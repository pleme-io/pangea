# AwsVpcEndpoint Implementation Documentation

## Overview

This directory contains the implementation for the `aws_vpc_endpoint` resource function, providing type-safe creation and management of AWS VPC Endpoint resources through terraform-synthesizer integration.

VPC endpoints enable private connectivity to AWS services without requiring an internet gateway, NAT instance, or NAT gateway. They provide a secure, cost-effective way to access AWS services from within a VPC.

## Implementation Architecture

### Core Components

#### 1. Resource Function (`resource.rb`)
The main `aws_vpc_endpoint` function that:
- Accepts a symbol name and attributes hash
- Validates attributes using dry-struct types with comprehensive business logic validation
- Generates terraform resource blocks via terraform-synthesizer
- Returns ResourceReference with computed outputs and properties
- Handles conditional resource configuration based on endpoint type (Gateway vs Interface)

#### 2. Type Definitions (`types.rb`)
VpcEndpointAttributes dry-struct defining:
- **Required attributes**: 
  - `vpc_id`: The VPC where the endpoint will be created
  - `service_name`: AWS service name in format `com.amazonaws.region.service`
- **Optional attributes**:
  - `vpc_endpoint_type`: "Gateway" (default) or "Interface" 
  - `route_table_ids`: For Gateway endpoints only
  - `subnet_ids`: For Interface endpoints only
  - `security_group_ids`: For Interface endpoints only
  - `policy`: JSON policy document for resource-based access control
  - `private_dns_enabled`: Enable private DNS for Interface endpoints (default: true)
  - `auto_accept`: Auto-accept endpoint connections (default: false)
  - `tags`: Resource tags
- **Custom validations**: Enforces AWS VPC endpoint constraints and business logic
- **Computed properties**: Helper methods for endpoint type checking and service parsing

#### 3. Documentation
- **CLAUDE.md** (this file): Implementation details for developers
- **README.md**: User-facing documentation with comprehensive examples

## Technical Implementation Details

### AWS VPC Endpoint Service Overview

VPC endpoints provide two connectivity models:

**Gateway Endpoints**:
- Free service for S3 and DynamoDB
- Route-based connectivity through route table entries
- No ENIs created in subnets
- Cannot be secured with security groups
- Regional service with automatic scaling

**Interface Endpoints**:
- Powered by AWS PrivateLink
- ENI-based connectivity in specified subnets
- Secured with security groups
- Supports private DNS names
- Per-hour + data processing charges
- Available for most AWS services

### Type Validation Logic

```ruby
class VpcEndpointAttributes < Dry::Struct
  # Endpoint type-specific validation
  def self.new(attributes = {})
    attrs = super(attributes)
    
    # Interface endpoint requirements
    if attrs.vpc_endpoint_type == "Interface"
      # Must specify subnets for ENI placement
      if attrs.subnet_ids.nil? || attrs.subnet_ids.empty?
        raise Dry::Struct::Error, "Interface endpoints require 'subnet_ids'"
      end
      
      # Cannot use route table configuration
      if attrs.route_table_ids && !attrs.route_table_ids.empty?
        raise Dry::Struct::Error, "Interface endpoints cannot use 'route_table_ids'"
      end
    end
    
    # Gateway endpoint constraints  
    if attrs.vpc_endpoint_type == "Gateway"
      # Cannot use subnet configuration
      if attrs.subnet_ids && !attrs.subnet_ids.empty?
        raise Dry::Struct::Error, "Gateway endpoints cannot use 'subnet_ids'"
      end
      
      # Cannot use security groups
      if attrs.security_group_ids && !attrs.security_group_ids.empty?
        raise Dry::Struct::Error, "Gateway endpoints do not support 'security_group_ids'"
      end
    end
    
    # Service name format validation
    unless attrs.service_name.match?(/\Acom\.amazonaws\.[a-z0-9-]+\.[a-z0-9-]+\z/)
      raise Dry::Struct::Error, "Invalid 'service_name' format"
    end
    
    attrs
  end
end
```

### Terraform Synthesis

The resource function generates terraform JSON through terraform-synthesizer with conditional logic:

```ruby
resource(:aws_vpc_endpoint, name) do
  # Always required
  vpc_id attrs.vpc_id
  service_name attrs.service_name
  vpc_endpoint_type attrs.vpc_endpoint_type
  
  # Conditional configuration based on endpoint type
  if attrs.route_table_ids && !attrs.route_table_ids.empty?
    route_table_ids attrs.route_table_ids  # Gateway only
  end
  
  if attrs.subnet_ids && !attrs.subnet_ids.empty?
    subnet_ids attrs.subnet_ids  # Interface only
  end
  
  if attrs.security_group_ids && !attrs.security_group_ids.empty?
    security_group_ids attrs.security_group_ids  # Interface only
  end
  
  # Interface endpoint DNS configuration
  if attrs.interface_endpoint?
    private_dns_enabled attrs.private_dns_enabled
  end
  
  # Optional policy and settings
  policy attrs.policy if attrs.policy
  auto_accept attrs.auto_accept
  
  # Resource tagging
  if attrs.tags.any?
    tags do
      attrs.tags.each { |key, value| public_send(key, value) }
    end
  end
end
```

### ResourceReference Return Value

The function returns a ResourceReference providing:

#### Terraform Outputs
- **`id`**: VPC endpoint ID (vpce-xxxxxxxxx)
- **`arn`**: VPC endpoint ARN
- **`cidr_blocks`**: CIDR blocks associated with the endpoint
- **`creation_timestamp`**: Endpoint creation timestamp
- **`dns_entry`**: DNS entries for Interface endpoints
- **`network_interface_ids`**: ENI IDs for Interface endpoints
- **`owner_id`**: AWS account ID that owns the endpoint
- **`policy`**: Attached policy document
- **`prefix_list_id`**: Prefix list ID for Gateway endpoints (used in route tables)
- **`private_dns_enabled`**: Whether private DNS is enabled
- **`requester_managed`**: Whether the endpoint is requester-managed
- **`route_table_ids`**: Associated route table IDs
- **`security_group_ids`**: Associated security group IDs
- **`service_name`**: AWS service name
- **`state`**: Endpoint state (available, pending, failed, etc.)
- **`subnet_ids`**: Associated subnet IDs
- **`tags_all`**: All tags including provider defaults
- **`vpc_endpoint_type`**: Endpoint type (Gateway or Interface)
- **`vpc_id`**: Associated VPC ID

#### Computed Properties
- **`gateway_endpoint?`**: Boolean check for Gateway endpoint type
- **`interface_endpoint?`**: Boolean check for Interface endpoint type  
- **`aws_service`**: Extracted AWS service name (e.g., "s3", "ec2", "ssm")
- **`aws_region`**: Extracted AWS region (e.g., "us-east-1", "eu-west-1")
- **`has_policy?`**: Boolean check for attached policy
- **`connectivity_type`**: Symbol representation (:gateway or :interface)

## Integration Patterns

### 1. Gateway Endpoint Usage
```ruby
template :s3_gateway_access do
  # S3 Gateway endpoint for cost-effective private access
  s3_endpoint = aws_vpc_endpoint(:s3_gateway, {
    vpc_id: ref(:aws_vpc, :main, :id),
    service_name: "com.amazonaws.us-east-1.s3",
    vpc_endpoint_type: "Gateway",
    route_table_ids: [
      ref(:aws_route_table, :private_a, :id),
      ref(:aws_route_table, :private_b, :id)
    ]
  })
  
  # Use prefix list in security group rules
  aws_security_group_rule(:s3_access, {
    security_group_id: ref(:aws_security_group, :app, :id),
    type: "egress",
    from_port: 443,
    to_port: 443,
    protocol: "tcp",
    prefix_list_ids: [s3_endpoint.prefix_list_id]
  })
end
```

### 2. Interface Endpoint with Security
```ruby
template :secure_ssm_access do
  # Security group for SSM endpoints
  ssm_endpoint_sg = aws_security_group(:ssm_endpoint_sg, {
    name: "ssm-endpoint-sg",
    vpc_id: ref(:aws_vpc, :main, :id),
    ingress: [
      {
        from_port: 443,
        to_port: 443,
        protocol: "tcp",
        cidr_blocks: [ref(:aws_vpc, :main, :cidr_block)]
      }
    ]
  })
  
  # SSM Interface endpoints for EC2 management
  %w[ssm ssmmessages ec2messages].each do |service|
    aws_vpc_endpoint(:"#{service}_endpoint", {
      vpc_id: ref(:aws_vpc, :main, :id),
      service_name: "com.amazonaws.us-east-1.#{service}",
      vpc_endpoint_type: "Interface",
      subnet_ids: [
        ref(:aws_subnet, :private_a, :id),
        ref(:aws_subnet, :private_b, :id)
      ],
      security_group_ids: [ssm_endpoint_sg.id],
      private_dns_enabled: true
    })
  end
end
```

### 3. Resource-Based Policy Enforcement
```ruby
template :restricted_s3_endpoint do
  # S3 Interface endpoint with resource-based access control
  s3_interface = aws_vpc_endpoint(:s3_interface_restricted, {
    vpc_id: ref(:aws_vpc, :main, :id),
    service_name: "com.amazonaws.us-east-1.s3",
    vpc_endpoint_type: "Interface",
    subnet_ids: [ref(:aws_subnet, :private_a, :id)],
    security_group_ids: [ref(:aws_security_group, :endpoint_sg, :id)],
    policy: JSON.pretty_generate({
      Version: "2012-10-17",
      Statement: [
        {
          Effect: "Allow",
          Principal: "*",
          Action: ["s3:GetObject", "s3:PutObject"],
          Resource: [
            "arn:aws:s3:::company-secure-bucket",
            "arn:aws:s3:::company-secure-bucket/*"
          ],
          Condition: {
            StringEquals: {
              "aws:PrincipalVpc": ref(:aws_vpc, :main, :id)
            }
          }
        }
      ]
    })
  })
end
```

## Error Handling and Validation

### Common Validation Errors

**Invalid Service Name Format**:
```ruby
# Error: Invalid 'service_name' format. Expected: com.amazonaws.region.service
service_name: "s3"  # ❌ Invalid

service_name: "com.amazonaws.us-east-1.s3"  # ✅ Valid
```

**Interface Endpoint Missing Subnets**:
```ruby
# Error: Interface endpoints require 'subnet_ids' to be specified
vpc_endpoint_type: "Interface"  # ❌ Missing subnet_ids

vpc_endpoint_type: "Interface",  # ✅ Valid
subnet_ids: ["subnet-12345678"]
```

**Gateway Endpoint with Security Groups**:
```ruby
# Error: Gateway endpoints do not support 'security_group_ids'
vpc_endpoint_type: "Gateway",        # ❌ Invalid combination
security_group_ids: ["sg-12345678"]

vpc_endpoint_type: "Gateway",        # ✅ Valid
route_table_ids: ["rtb-12345678"]
```

### Runtime Validation

The implementation performs comprehensive runtime validation:
- Service name format checking with regex patterns
- Endpoint type constraint validation
- Cross-attribute dependency validation
- AWS resource ID format validation

## Testing Strategy

### Unit Tests
```ruby
RSpec.describe Pangea::Resources::AWS do
  describe "#aws_vpc_endpoint" do
    context "Gateway endpoints" do
      it "validates S3 gateway endpoint creation" do
        result = aws_vpc_endpoint(:s3_gateway, {
          vpc_id: "vpc-12345678",
          service_name: "com.amazonaws.us-east-1.s3",
          vpc_endpoint_type: "Gateway",
          route_table_ids: ["rtb-12345678"]
        })
        
        expect(result.gateway_endpoint?).to be true
        expect(result.aws_service).to eq "s3"
        expect(result.aws_region).to eq "us-east-1"
      end
      
      it "rejects security groups for gateway endpoints" do
        expect {
          aws_vpc_endpoint(:invalid, {
            vpc_id: "vpc-12345678",
            service_name: "com.amazonaws.us-east-1.s3",
            vpc_endpoint_type: "Gateway",
            security_group_ids: ["sg-12345678"]
          })
        }.to raise_error(Dry::Struct::Error)
      end
    end
    
    context "Interface endpoints" do
      it "validates EC2 interface endpoint creation" do
        result = aws_vpc_endpoint(:ec2_interface, {
          vpc_id: "vpc-12345678", 
          service_name: "com.amazonaws.us-east-1.ec2",
          vpc_endpoint_type: "Interface",
          subnet_ids: ["subnet-12345678"]
        })
        
        expect(result.interface_endpoint?).to be true
        expect(result.connectivity_type).to eq :interface
      end
      
      it "requires subnets for interface endpoints" do
        expect {
          aws_vpc_endpoint(:invalid, {
            vpc_id: "vpc-12345678",
            service_name: "com.amazonaws.us-east-1.ec2", 
            vpc_endpoint_type: "Interface"
          })
        }.to raise_error(Dry::Struct::Error, /require.*subnet_ids/)
      end
    end
  end
end
```

### Integration Tests
```ruby
RSpec.describe "VPC Endpoint Integration" do
  it "generates correct terraform configuration" do
    template_output = compile_template do
      aws_vpc_endpoint(:test_endpoint, {
        vpc_id: "vpc-12345678",
        service_name: "com.amazonaws.us-east-1.s3",
        vpc_endpoint_type: "Gateway"
      })
    end
    
    expect(template_output).to include_terraform_resource("aws_vpc_endpoint", "test_endpoint")
    expect(template_output.dig("resource", "aws_vpc_endpoint", "test_endpoint", "service_name"))
      .to eq("com.amazonaws.us-east-1.s3")
  end
end
```

## Security Best Practices

### 1. Least Privilege Access Policies
```ruby
# Implement resource-based policies that restrict access
policy: JSON.pretty_generate({
  Version: "2012-10-17",
  Statement: [
    {
      Effect: "Allow",
      Principal: "*",
      Action: ["s3:GetObject"],
      Resource: ["arn:aws:s3:::allowed-bucket/*"],
      Condition: {
        StringEquals: {
          "aws:PrincipalVpc": vpc_id
        }
      }
    }
  ]
})
```

### 2. Security Group Configuration
```ruby
# Create restrictive security groups for Interface endpoints
endpoint_sg = aws_security_group(:endpoint_sg, {
  ingress: [
    {
      from_port: 443,
      to_port: 443,
      protocol: "tcp",
      cidr_blocks: [vpc_cidr_block],  # Only allow VPC traffic
      description: "HTTPS from VPC"
    }
  ],
  egress: []  # No outbound rules needed
})
```

### 3. Network Segmentation
```ruby
# Place Interface endpoints in dedicated subnets
subnet_ids: [
  ref(:aws_subnet, :endpoint_subnet_a, :id),  # Dedicated endpoint subnets
  ref(:aws_subnet, :endpoint_subnet_b, :id)
]
```

## Performance Considerations

### 1. Multi-AZ Deployment
- Deploy Interface endpoints across multiple AZs for high availability
- Consider regional failover patterns for critical services

### 2. Endpoint Selection Strategy
- Use Gateway endpoints for S3/DynamoDB (free and high performance)
- Use Interface endpoints for other services with careful cost analysis
- Monitor data processing charges for Interface endpoints

### 3. DNS Resolution Optimization
- Enable private DNS for Interface endpoints to avoid application changes
- Consider custom DNS configurations for complex networking scenarios

## Cost Optimization Strategies

### 1. Gateway vs Interface Decision Matrix
- **S3/DynamoDB**: Always use Gateway endpoints (free)
- **Other services**: Evaluate Interface endpoint costs vs NAT Gateway costs
- **Multi-service scenarios**: Shared Interface endpoint subnets reduce costs

### 2. Regional Considerations
- Evaluate cross-region data transfer costs
- Consider regional service availability for endpoint services

## Future Enhancements

### Planned Improvements
1. **Enhanced Policy Validation**: JSON schema validation for policy documents
2. **Service Name Auto-completion**: Helper methods for common AWS service names
3. **Cost Estimation**: Integration with AWS pricing APIs for cost estimation
4. **Multi-Region Support**: Enhanced support for cross-region endpoint configurations
5. **Terraform State Integration**: Better handling of endpoint state dependencies

### Architecture Pattern Integration
1. **Network Architecture Functions**: Integration with higher-level network patterns
2. **Security Boundary Patterns**: Automated security group and policy generation
3. **Cost Optimization Patterns**: Automated endpoint type selection based on usage patterns

This implementation provides a comprehensive, type-safe interface to AWS VPC endpoints with extensive validation, security best practices, and cost optimization guidance.
