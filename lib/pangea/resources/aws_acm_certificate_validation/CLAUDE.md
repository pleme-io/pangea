# AWS ACM Certificate Validation Implementation

## Resource Overview

**Resource Type**: `aws_acm_certificate_validation`  
**Terraform Provider**: AWS  
**Purpose**: Orchestrate certificate validation completion and dependency management

## Implementation Architecture

### Type Safety Structure

```
AcmCertificateValidationAttributes (dry-struct)
├── certificate_arn (CertificateArn) - ARN of certificate to validate
├── validation_record_fqdns (Array<String>) - DNS validation record names
└── timeouts (AcmCertificateValidationTimeouts) - Validation timeout configuration
```

### Validation Logic

**Certificate ARN Validation**:
```ruby
CertificateArn = String.constrained(
  format: /\Aarn:aws:acm:[a-z0-9-]+:\d{12}:certificate\/[a-f0-9-]{36}\z/
)

def self.validate_certificate_arn(arn)
  unless arn.match?(/\Aarn:aws:acm:[a-z0-9-]+:\d{12}:certificate\/[a-f0-9-]{36}\z/)
    raise Dry::Struct::Error, "Invalid ACM certificate ARN format: #{arn}"
  end
end
```

**FQDN Validation**:
```ruby
def self.validate_fqdn(fqdn)
  # RFC-compliant FQDN validation
  unless fqdn.match?(/\A[a-zA-Z0-9]([a-zA-Z0-9\-]*[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9\-]*[a-zA-Z0-9])?)*\.?\z/)
    raise Dry::Struct::Error, "Invalid FQDN format: #{fqdn}"
  end
  
  # AWS DNS name length limit
  if fqdn.length > 253
    raise Dry::Struct::Error, "FQDN too long: #{fqdn} (max 253 characters)"
  end
end
```

**Timeout Configuration Validation**:
```ruby
AcmCertificateValidationTimeouts = Hash.schema(
  create?: String.constrained(format: /\A\d+[smh]\z/).optional.default('5m'),
  update?: String.constrained(format: /\A\d+[smh]\z/).optional
).constructor { |value|
  if value[:create]
    timeout_value = parse_timeout(value[:create])
    if timeout_value > 600  # 10 minutes max
      raise Dry::Types::ConstraintError, "Certificate validation timeout too long: #{value[:create]} (max 10m)"
    end
  end
  value
}
```

### Resource Synthesis

**Terraform Resource Generation**:
```ruby
resource(:aws_acm_certificate_validation, name) do
  certificate_arn validation_attrs.certificate_arn
  
  # DNS validation FQDNs (for DNS validation method)
  if validation_attrs.validation_record_fqdns&.any?
    validation_record_fqdns validation_attrs.validation_record_fqdns
  end
  
  # Timeout configuration
  if validation_attrs.timeouts
    timeouts do
      create validation_attrs.timeouts[:create] if validation_attrs.timeouts[:create]
      update validation_attrs.timeouts[:update] if validation_attrs.timeouts[:update]
    end
  end
end
```

### Output Mapping

**Resource Reference Outputs**:
```ruby
outputs: {
  id: "${aws_acm_certificate_validation.#{name}.id}",                     # Validation resource ID
  certificate_arn: "${aws_acm_certificate_validation.#{name}.certificate_arn}"  # Validated certificate ARN
}
```

## Validation Orchestration Details

### DNS Validation Workflow

**Complete DNS Validation Process**:
```ruby
# 1. Certificate creation
cert = aws_acm_certificate(:cert, {
  domain_name: "example.com",
  validation_method: "DNS"
})

# 2. DNS validation records creation
cert.domain_validation_options.each_with_index do |dvo, index|
  aws_route53_record(:"validation_#{index}", {
    zone_id: zone.zone_id,
    name: dvo[:resource_record_name],     # "_validation.example.com"
    type: dvo[:resource_record_type],     # "CNAME"
    ttl: 60,
    records: [dvo[:resource_record_value]]
  })
end

# 3. Certificate validation orchestration
validation = aws_acm_certificate_validation(:validation, {
  certificate_arn: cert.arn,
  validation_record_fqdns: cert.domain_validation_options.map { |dvo|
    dvo[:resource_record_name]
  },
  timeouts: { create: "10m" }
})
```

### Email Validation Workflow

**Email Validation Process**:
```ruby
# 1. Certificate creation with email validation
email_cert = aws_acm_certificate(:email_cert, {
  domain_name: "secure.example.com",
  validation_method: "EMAIL"
})

# 2. Certificate validation wait (manual email confirmation required)
validation = aws_acm_certificate_validation(:email_validation, {
  certificate_arn: email_cert.arn,
  timeouts: { 
    create: "2h"  # Extended timeout for manual process
  }
})

# Validation emails sent to:
# - admin@secure.example.com
# - administrator@secure.example.com  
# - postmaster@secure.example.com
# - webmaster@secure.example.com
# - hostmaster@secure.example.com
```

## Computed Properties

**Validation Analysis Methods**:
```ruby
def validation_method
  validation_record_fqdns&.any? ? 'DNS' : 'EMAIL'
end

def validation_record_count
  validation_record_fqdns&.length || 0
end

def estimated_validation_time
  case validation_method
  when 'DNS' then '5-10 minutes (after DNS records propagate)'
  when 'EMAIL' then '1-2 hours (after email confirmation)'
  else 'Unknown'
  end
end

def certificate_region
  certificate_arn.split(':')[3]  # Extract region from ARN
end

def certificate_account_id
  certificate_arn.split(':')[4]  # Extract account ID from ARN
end
```

## AWS Integration Patterns

### Load Balancer SSL Termination

```ruby
# Certificate validation dependency chain
template :ssl_load_balancer do
  # 1. Certificate
  cert = aws_acm_certificate(:cert, {
    domain_name: "api.example.com",
    validation_method: "DNS"
  })
  
  # 2. DNS validation records
  cert.domain_validation_options.each_with_index do |dvo, index|
    aws_route53_record(:"validation_#{index}", {
      zone_id: zone.zone_id,
      name: dvo[:resource_record_name],
      type: dvo[:resource_record_type],
      ttl: 60,
      records: [dvo[:resource_record_value]]
    })
  end
  
  # 3. Certificate validation
  cert_validation = aws_acm_certificate_validation(:validation, {
    certificate_arn: cert.arn,
    validation_record_fqdns: cert.domain_validation_options.map { |dvo|
      dvo[:resource_record_name]
    }
  })
  
  # 4. Load balancer (depends on validated certificate)
  lb = aws_lb(:app_lb, {
    name: "app-lb",
    load_balancer_type: "application",
    subnets: [subnet1.id, subnet2.id]
  })
  
  # 5. HTTPS listener using validated certificate
  https_listener = aws_lb_listener(:https, {
    load_balancer_arn: lb.arn,
    port: 443,
    protocol: "HTTPS",
    certificate_arn: cert_validation.certificate_arn,  # Validated certificate dependency
    ssl_policy: "ELBSecurityPolicy-TLS-1-2-2017-01"
  })
end
```

### CloudFront Distribution SSL

```ruby
# CloudFront requires certificate in us-east-1
template :cloudfront_ssl do
  # Certificate in us-east-1 (required for CloudFront)
  provider :aws, region: "us-east-1", alias: "us_east_1"
  
  cf_cert = aws_acm_certificate(:cf_cert, {
    domain_name: "cdn.example.com",
    validation_method: "DNS",
    provider: "aws.us_east_1"
  })
  
  # DNS validation records (can be in any region)
  provider :aws, region: "us-west-2", alias: "main"
  
  cf_cert.domain_validation_options.each_with_index do |dvo, index|
    aws_route53_record(:"cf_validation_#{index}", {
      zone_id: zone.zone_id,
      name: dvo[:resource_record_name],
      type: dvo[:resource_record_type],
      ttl: 60,
      records: [dvo[:resource_record_value]],
      provider: "aws.main"
    })
  end
  
  # Certificate validation in us-east-1
  cf_cert_validation = aws_acm_certificate_validation(:cf_validation, {
    certificate_arn: cf_cert.arn,
    validation_record_fqdns: cf_cert.domain_validation_options.map { |dvo|
      dvo[:resource_record_name]
    },
    provider: "aws.us_east_1"
  })
  
  # CloudFront distribution using validated certificate
  cloudfront = aws_cloudfront_distribution(:cdn, {
    aliases: ["cdn.example.com"],
    viewer_certificate: {
      acm_certificate_arn: cf_cert_validation.certificate_arn,
      ssl_support_method: "sni-only",
      minimum_protocol_version: "TLSv1.2_2021"
    },
    provider: "aws.us_east_1"
  })
end
```

### Multi-Domain Certificate Validation

```ruby
# Complex multi-domain validation
template :multi_domain_validation do
  multi_cert = aws_acm_certificate(:multi_cert, {
    domain_name: "app.example.com",
    subject_alternative_names: [
      "api.app.example.com",
      "cdn.app.example.com",
      "admin.app.example.com"
    ],
    validation_method: "DNS"
  })
  
  # Create validation records for each domain
  multi_cert.domain_validation_options.each_with_index do |dvo, index|
    aws_route53_record(:"multi_validation_#{index}", {
      zone_id: zone.zone_id,
      name: dvo[:resource_record_name],
      type: dvo[:resource_record_type], 
      ttl: 60,
      records: [dvo[:resource_record_value]],
      allow_overwrite: true  # Handle potential record conflicts
    })
  end
  
  # Validation with extended timeout for multiple domains
  multi_validation = aws_acm_certificate_validation(:multi_validation, {
    certificate_arn: multi_cert.arn,
    validation_record_fqdns: multi_cert.domain_validation_options.map { |dvo|
      dvo[:resource_record_name]
    },
    timeouts: {
      create: "15m"  # Extended for multiple domain propagation
    }
  })
end
```

## Error Handling & Troubleshooting

### Common Validation Failures

1. **DNS Record Propagation Issues**:
   ```
   Error: Certificate validation failed - DNS records not found
   ```
   - **Cause**: DNS records not propagated globally
   - **Solution**: Verify DNS records exist and propagated
   - **Check**: `dig _validation.domain.com CNAME`

2. **Incorrect DNS Record Values**:
   ```
   Error: Domain validation failed for domain.com
   ```
   - **Cause**: DNS record values don't match ACM requirements
   - **Solution**: Use exact values from `domain_validation_options`
   - **Verify**: Record name, type, and value match exactly

3. **Timeout Exceeded**:
   ```
   Error: Certificate validation timed out
   ```
   - **Cause**: Validation taking longer than configured timeout
   - **Solution**: Increase timeout or check validation requirements
   - **Typical**: DNS validation: 5-10min, Email validation: 1-2hr

4. **Cross-Region Certificate Issues**:
   ```
   Error: Certificate not found in region
   ```
   - **Cause**: Certificate created in wrong region for service
   - **Solution**: Ensure certificate in correct region (us-east-1 for CloudFront)

### Production Validation Patterns

**Robust DNS Validation Setup**:
```ruby
# Production-ready validation with error handling
template :production_cert_validation do
  prod_cert = aws_acm_certificate(:prod_cert, {
    domain_name: "api.production.com",
    subject_alternative_names: ["www.production.com"],
    validation_method: "DNS",
    lifecycle: {
      create_before_destroy: true  # Zero-downtime certificate renewal
    }
  })
  
  # DNS validation with conflict resolution
  validation_records = prod_cert.domain_validation_options.map.with_index do |dvo, index|
    aws_route53_record(:"prod_validation_#{index}", {
      zone_id: zone.zone_id,
      name: dvo[:resource_record_name],
      type: dvo[:resource_record_type],
      ttl: 60,
      records: [dvo[:resource_record_value]],
      allow_overwrite: true,  # Handle record conflicts during renewal
      lifecycle: {
        create_before_destroy: true
      }
    })
  end
  
  # Certificate validation with production timeout
  cert_validation = aws_acm_certificate_validation(:prod_validation, {
    certificate_arn: prod_cert.arn,
    validation_record_fqdns: prod_cert.domain_validation_options.map { |dvo|
      dvo[:resource_record_name]
    },
    timeouts: {
      create: "10m"  # Allow extra time for DNS propagation
    }
  })
  
  # Dependent resources use validated certificate
  https_listener = aws_lb_listener(:https, {
    # ... listener configuration ...
    certificate_arn: cert_validation.certificate_arn  # Ensures certificate is validated
  })
end
```

### Monitoring & Observability

**Certificate Validation Status Tracking**:
```ruby
# Outputs for monitoring certificate validation
output :certificate_validation_status do
  value "completed"
  description "Certificate validation completed successfully"
end

output :validated_domains do
  value cert.domain_name
  description "Domains covered by validated certificate"
end

output :dns_validation_records do
  value cert.domain_validation_options
  description "DNS records used for validation (keep in place for auto-renewal)"
end
```

**Operational Checks**:
- Monitor certificate validation completion time
- Track DNS record creation and propagation
- Verify certificate status before dependent resource creation
- Alert on validation failures or timeouts

This implementation ensures reliable certificate validation orchestration with proper dependency management, comprehensive error handling, and production-ready patterns for SSL/TLS certificate workflows in AWS infrastructure.