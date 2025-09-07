# AWS Load Balancer Listener Certificate Implementation

## Overview

The `aws_lb_listener_certificate` resource implements AWS Load Balancer additional certificate attachment management for multi-domain SSL/TLS termination, certificate rotation, and complex SSL certificate scenarios in production environments.

## Architecture

### Type System

```ruby
LoadBalancerListenerCertificateAttributes < Dry::Struct
  - listener_arn: String (ALB/NLB listener ARN with format validation)
  - certificate_arn: String (ACM certificate ARN with format validation)
```

### ARN Validation

**Listener ARN Format:**
```
arn:aws:elasticloadbalancing:{region}:{account}:listener/{load-balancer-type}/{name}/{id}
```

**Certificate ARN Format:**
```
arn:aws:acm:{region}:{account}:certificate/{certificate-id}
```

### Cross-Region Validation

The implementation enforces that certificates and listeners must be in the same AWS region by parsing ARN components and validating region consistency.

## SSL/TLS Architecture Patterns

### Certificate Hierarchy

```
Load Balancer Listener
├── Primary Certificate (defined in listener)
│   └── Primary domain (example.com)
├── Additional Certificate 1 (this resource)
│   └── API domain (api.example.com) 
├── Additional Certificate 2 (this resource)
│   └── Admin domain (admin.example.com)
└── Additional Certificate N (this resource)
    └── Service domain (service.example.com)
```

### SNI (Server Name Indication) Support

AWS Application Load Balancers use SNI to serve different certificates based on the hostname in the TLS handshake:

1. **Client connects** with specific hostname
2. **ALB examines** SNI extension in TLS handshake  
3. **Certificate selection** based on hostname match
4. **TLS session** established with appropriate certificate

## Multi-Domain Certificate Management

### Domain Strategy Patterns

**Wildcard Strategy:**
```ruby
# Primary wildcard certificate covers most subdomains
primary_listener = aws_lb_listener(:https_wildcard, {
  certificate_arn: wildcard_cert.arn  # *.example.com
})

# Specific certificates for special requirements
aws_lb_listener_certificate(:api_specific_cert, {
  listener_arn: primary_listener.arn,
  certificate_arn: api_specific_cert.arn  # api.example.com (higher security)
})
```

**Subdomain Isolation Strategy:**
```ruby
# Each major service gets its own certificate
services = %w[api admin dashboard payments]

service_certificates = services.map do |service|
  aws_lb_listener_certificate(:"#{service}_cert", {
    listener_arn: main_listener.arn,
    certificate_arn: service_certificates[service].arn
  })
end
```

## Production Certificate Rotation

### Zero-Downtime Certificate Updates

```ruby
class CertificateRotationOrchestrator
  def self.rotate_certificate(listener_arn, old_cert_arn, new_cert_arn)
    # Phase 1: Add new certificate alongside old one
    temp_attachment = aws_lb_listener_certificate(:temp_rotation, {
      listener_arn: listener_arn,
      certificate_arn: new_cert_arn
    })
    
    # Phase 2: DNS propagation wait (external to Terraform)
    # Phase 3: Update listener primary certificate (separate resource update)
    # Phase 4: Remove old certificate attachment (cleanup phase)
    
    temp_attachment
  end
  
  def self.emergency_certificate_replacement(listener_arn, emergency_cert_arn)
    # Immediate certificate addition for security incidents
    aws_lb_listener_certificate(:emergency_cert, {
      listener_arn: listener_arn,
      certificate_arn: emergency_cert_arn
    })
  end
end
```

### Staged Certificate Deployment

```ruby
# Environment-specific certificate management
environments = %w[development staging production]

environments.each do |env|
  env_listener = aws_lb_listener(:"#{env}_https", {
    load_balancer_arn: albs[env].arn,
    port: 443,
    protocol: "HTTPS",
    certificate_arn: primary_certs[env].arn
  })
  
  # Environment-specific additional certificates
  additional_domains[env].each do |domain, cert|
    aws_lb_listener_certificate(:"#{env}_#{domain.tr('.', '_')}_cert", {
      listener_arn: env_listener.arn,
      certificate_arn: cert.arn
    })
  end
end
```

## Enterprise Multi-Tenancy

### SaaS Platform Certificate Architecture

```ruby
# Multi-tenant SaaS with customer-specific certificates
class SaaSCertificateManager
  TENANT_TIERS = {
    enterprise: { custom_domain: true, dedicated_cert: true },
    business: { custom_domain: true, dedicated_cert: false },
    standard: { custom_domain: false, dedicated_cert: false }
  }.freeze

  def self.setup_tenant_certificates(listener_arn, tenants)
    tenant_certificates = []
    
    tenants.each do |tenant|
      tier_config = TENANT_TIERS[tenant[:tier]]
      
      if tier_config[:custom_domain] && tier_config[:dedicated_cert]
        # Enterprise tier gets dedicated certificate
        tenant_certificates << aws_lb_listener_certificate(:"#{tenant[:name]}_cert", {
          listener_arn: listener_arn,
          certificate_arn: tenant[:certificate_arn]
        })
      end
    end
    
    tenant_certificates
  end
end

# Usage example
enterprise_tenants = [
  { name: "acme_corp", tier: :enterprise, certificate_arn: acme_cert.arn },
  { name: "globodyne", tier: :enterprise, certificate_arn: globodyne_cert.arn }
]

tenant_certs = SaaSCertificateManager.setup_tenant_certificates(
  saas_listener.arn,
  enterprise_tenants
)
```

### White-Label Application Certificates

```ruby
# White-label application with partner-specific certificates
partners = [
  { name: "partner_a", domain: "app.partner-a.com", cert: partner_a_cert },
  { name: "partner_b", domain: "platform.partner-b.net", cert: partner_b_cert },
  { name: "partner_c", domain: "service.partner-c.org", cert: partner_c_cert }
]

partner_certificates = partners.map do |partner|
  aws_lb_listener_certificate(:"#{partner[:name]}_whitelabel", {
    listener_arn: whitelabel_listener.arn,
    certificate_arn: partner[:cert].arn
  })
end
```

## Compliance and Security Patterns

### Security Domain Isolation

```ruby
# Different certificates for different security zones
security_zones = {
  public: {
    domains: ["www.example.com", "marketing.example.com"],
    cert: public_cert,
    security_level: "standard"
  },
  internal: {
    domains: ["internal.example.com", "employees.example.com"],
    cert: internal_cert,
    security_level: "high"
  },
  compliance: {
    domains: ["payments.example.com", "hipaa.example.com"],
    cert: compliance_cert,
    security_level: "maximum"
  }
}

security_zones.each do |zone, config|
  next if zone == :public  # Primary certificate
  
  aws_lb_listener_certificate(:"#{zone}_security_cert", {
    listener_arn: security_listener.arn,
    certificate_arn: config[:cert].arn
  })
end
```

### PCI DSS Certificate Management

```ruby
# PCI DSS compliant certificate attachment
pci_certificate = aws_lb_listener_certificate(:pci_compliant_cert, {
  listener_arn: pci_alb_listener.arn,
  certificate_arn: pci_dedicated_cert.arn
})

# Additional validation and monitoring would be external to this resource
```

## High Availability Certificate Strategies

### Cross-Region Certificate Deployment

```ruby
# Certificate deployment across multiple regions for DR
regions = %w[us-east-1 us-west-2 eu-west-1]

regional_deployments = regions.map do |region|
  regional_listener = aws_lb_listener(:"https_#{region.tr('-', '_')}", {
    load_balancer_arn: regional_albs[region].arn,
    port: 443,
    protocol: "HTTPS",
    certificate_arn: regional_primary_certs[region].arn
  })
  
  # Cross-region backup certificates
  aws_lb_listener_certificate(:"backup_cert_#{region.tr('-', '_')}", {
    listener_arn: regional_listener.arn,
    certificate_arn: regional_backup_certs[region].arn
  })
end
```

### Certificate Failover Planning

```ruby
# Certificate failover configuration
class CertificateFailover
  def self.setup_failover_certificates(primary_listener_arn)
    # Primary certificate is in listener definition
    
    # Backup certificate for rapid failover
    backup_cert = aws_lb_listener_certificate(:backup_cert, {
      listener_arn: primary_listener_arn,
      certificate_arn: backup_certificate.arn
    })
    
    # Emergency certificate for incident response
    emergency_cert = aws_lb_listener_certificate(:emergency_cert, {
      listener_arn: primary_listener_arn,
      certificate_arn: emergency_certificate.arn
    })
    
    [backup_cert, emergency_cert]
  end
end
```

## Network Load Balancer TLS Support

### NLB Multi-Domain TLS Termination

```ruby
# Network Load Balancer with multiple TLS certificates
nlb_tls_listener = aws_lb_listener(:nlb_secure_tcp, {
  load_balancer_arn: nlb.arn,
  port: 443,
  protocol: "TLS",
  ssl_policy: "ELBSecurityPolicy-TLS-1-2-2017-01",
  certificate_arn: primary_nlb_cert.arn
})

# Additional certificates for NLB multi-domain support
nlb_domain_certs = [
  { domain: "secure-api.example.com", cert: secure_api_cert },
  { domain: "vpn.example.com", cert: vpn_cert }
]

nlb_additional_certs = nlb_domain_certs.map do |domain_cert|
  aws_lb_listener_certificate(:"nlb_#{domain_cert[:domain].tr('.', '_')}", {
    listener_arn: nlb_tls_listener.arn,
    certificate_arn: domain_cert[:cert].arn
  })
end
```

## Certificate Monitoring Integration

### Certificate Expiration Tracking

```ruby
# Certificate management with monitoring tags
monitored_certificate = aws_lb_listener_certificate(:monitored_cert, {
  listener_arn: production_listener.arn,
  certificate_arn: monitored_cert.arn
})

# External monitoring would track certificate expiration
# This resource provides the attachment point
```

## Testing Strategies

### Certificate Validation Testing

```ruby
describe "aws_lb_listener_certificate" do
  it "validates listener ARN format" do
    expect {
      aws_lb_listener_certificate(:test, {
        listener_arn: "invalid-arn",
        certificate_arn: valid_cert_arn
      })
    }.to raise_error(/ARN format/)
  end
  
  it "validates certificate ARN format" do
    expect {
      aws_lb_listener_certificate(:test, {
        listener_arn: valid_listener_arn,
        certificate_arn: "invalid-cert-arn"
      })
    }.to raise_error(/ARN format/)
  end
  
  it "validates region matching" do
    expect {
      aws_lb_listener_certificate(:test, {
        listener_arn: "arn:aws:elasticloadbalancing:us-east-1:123456789012:listener/...",
        certificate_arn: "arn:aws:acm:us-west-2:123456789012:certificate/..."
      })
    }.to raise_error(/region.*must match/)
  end
end
```

### Integration Testing

```ruby
# Test certificate attachment workflow
test_scenario = {
  primary_cert: test_primary_certificate,
  additional_certs: [test_api_cert, test_admin_cert]
}

# Create listener with primary certificate
test_listener = aws_lb_listener(:test_https, {
  certificate_arn: test_scenario[:primary_cert].arn
})

# Attach additional certificates
additional_attachments = test_scenario[:additional_certs].map.with_index do |cert, index|
  aws_lb_listener_certificate(:"test_additional_#{index}", {
    listener_arn: test_listener.arn,
    certificate_arn: cert.arn
  })
end
```

## Error Handling and Validation

### Comprehensive Error Cases

```ruby
# Invalid ARN format
aws_lb_listener_certificate(:invalid_arn, {
  listener_arn: "not-an-arn",
  certificate_arn: "also-not-an-arn"
})
# Raises: ARN format validation errors

# Region mismatch
aws_lb_listener_certificate(:region_mismatch, {
  listener_arn: "arn:aws:elasticloadbalancing:us-east-1:...:listener/...",
  certificate_arn: "arn:aws:acm:eu-west-1:...:certificate/..."
})
# Raises: Certificate region must match listener region

# Wrong resource type ARNs
aws_lb_listener_certificate(:wrong_type, {
  listener_arn: "arn:aws:ec2:us-east-1:...:instance/...",  # Not a listener
  certificate_arn: "arn:aws:s3:us-east-1:...:bucket/..."   # Not a certificate
})
# Raises: ARN format validation errors
```

## Performance Considerations

### Certificate Lookup Optimization

- **SNI Performance**: ALB handles SNI lookup efficiently with multiple certificates
- **Certificate Count**: AWS supports multiple certificates per listener without performance penalty
- **TLS Handshake**: Each domain gets optimized certificate selection
- **Memory Usage**: Certificate attachments have minimal memory overhead

### Scaling Patterns

```ruby
# Efficient certificate management for large numbers of domains
def bulk_certificate_attachment(listener_arn, certificate_mappings)
  certificate_mappings.map.with_index do |(domain, cert_arn), index|
    aws_lb_listener_certificate(:"cert_#{index}", {
      listener_arn: listener_arn,
      certificate_arn: cert_arn
    })
  end
end

# Usage for 100+ domains
domain_certificates = {
  "client1.saas.com" => client1_cert.arn,
  "client2.saas.com" => client2_cert.arn,
  # ... hundreds more
}

bulk_attachments = bulk_certificate_attachment(
  saas_listener.arn,
  domain_certificates
)
```

This implementation provides production-ready AWS Load Balancer certificate attachment management with comprehensive validation, multi-domain support, and enterprise-grade SSL/TLS certificate management capabilities.