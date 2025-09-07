# AWS ACM Certificate Implementation

## Resource Overview

**Resource Type**: `aws_acm_certificate`  
**Terraform Provider**: AWS  
**Purpose**: SSL/TLS certificate management through Amazon Certificate Manager

## Implementation Architecture

### Type Safety Structure

```
AcmCertificateAttributes (dry-struct)
├── domain_name (DomainName) - Primary certificate domain
├── subject_alternative_names (Array<DomainName|WildcardDomainName>) - Additional domains
├── validation_method (AcmValidationMethod) - DNS or EMAIL validation
├── key_algorithm (AcmKeyAlgorithm) - Certificate encryption algorithm
├── certificate_transparency_logging_preference (CertificateTransparencyLogging)
├── validation_options (Array<AcmValidationOption>) - Custom validation settings
├── lifecycle (AcmCertificateLifecycle) - Terraform lifecycle rules
└── tags (AwsTags) - Resource tagging
```

### Validation Logic

**Domain Name Validation**:
```ruby
def self.validate_domain_name(domain)
  # Wildcard validation: Must be *.domain.com format
  if domain.include?('*')
    unless domain.match?(/\A\*\.[a-z0-9.-]+\z/i)
      raise Dry::Struct::Error, "Invalid wildcard domain: #{domain}"
    end
  end
  
  # Length limits: AWS ACM constraints
  if domain.length > 253
    raise Dry::Struct::Error, "Domain name too long: #{domain} (max 253 characters)"
  end
  
  # Label validation: Each part between dots max 64 chars
  labels = domain.gsub(/^\*\./, '').split('.')
  labels.each do |label|
    if label.length > 64
      raise Dry::Struct::Error, "Domain label too long: #{label} (max 64 characters)"
    end
  end
end
```

**Multi-Domain Validation**:
```ruby
# Duplicate domain detection
all_domains = [domain_name, *subject_alternative_names]
if all_domains.uniq.length != all_domains.length
  raise Dry::Struct::Error, "Duplicate domains found in certificate request"
end

# AWS limit enforcement (100 domains max)
if all_domains.length > 100
  raise Dry::Struct::Error, "ACM certificate supports maximum 100 domain names"
end
```

### Resource Synthesis

**Terraform Resource Generation**:
```ruby
resource(:aws_acm_certificate, name) do
  domain_name cert_attrs.domain_name
  
  # Conditional blocks based on attributes
  if cert_attrs.subject_alternative_names&.any?
    subject_alternative_names cert_attrs.subject_alternative_names
  end
  
  validation_method cert_attrs.validation_method
  
  # Advanced options
  if cert_attrs.certificate_transparency_logging_preference
    options do
      certificate_transparency_logging_preference cert_attrs.certificate_transparency_logging_preference
    end
  end
  
  # Validation customization
  if cert_attrs.validation_options&.any?
    cert_attrs.validation_options.each do |validation_option|
      validation_option do
        domain_name validation_option[:domain_name]
        validation_domain validation_option[:validation_domain] if validation_option[:validation_domain]
      end
    end
  end
end
```

### Output Mapping

**Resource Reference Outputs**:
```ruby
outputs: {
  id: "${aws_acm_certificate.#{name}.id}",                           # Certificate ID
  arn: "${aws_acm_certificate.#{name}.arn}",                         # Certificate ARN (for load balancers)
  domain_name: "${aws_acm_certificate.#{name}.domain_name}",         # Primary domain
  domain_validation_options: "${aws_acm_certificate.#{name}.domain_validation_options}", # DNS records needed
  status: "${aws_acm_certificate.#{name}.status}",                   # Certificate status
  validation_emails: "${aws_acm_certificate.#{name}.validation_emails}",               # Email validation addresses
  validation_method: "${aws_acm_certificate.#{name}.validation_method}",               # Validation method used
  subject_alternative_names: "${aws_acm_certificate.#{name}.subject_alternative_names}", # SAN domains
  key_algorithm: "${aws_acm_certificate.#{name}.key_algorithm}",     # Encryption algorithm
  not_after: "${aws_acm_certificate.#{name}.not_after}",             # Expiration date
  not_before: "${aws_acm_certificate.#{name}.not_before}",           # Valid from date
  type: "${aws_acm_certificate.#{name}.type}"                        # Certificate type
}
```

## Security Implementation Details

### Certificate Validation Methods

**DNS Validation (Recommended)**:
- **Automation-Friendly**: No human intervention required
- **Auto-Renewal**: Works indefinitely with maintained DNS records
- **Scalable**: Supports any number of domains
- **Fast**: Usually validates in 5-10 minutes

**Email Validation**:
- **Manual Process**: Requires email confirmation
- **Limited Automation**: Renewal requires manual intervention
- **Standard Addresses**: Uses admin@, administrator@, postmaster@, etc.

### Key Algorithm Security Levels

**RSA Algorithms**:
- `RSA-1024`: Legacy, deprecated
- `RSA-2048`: Standard, widely supported
- `RSA-4096`: High security, larger certificate size

**Elliptic Curve Algorithms (Recommended)**:
- `EC-prime256v1`: NIST P-256, good performance/security balance
- `EC-secp384r1`: NIST P-384, high security (recommended for production)
- `EC-secp521r1`: NIST P-521, maximum security

### Production Security Patterns

**Zero-Downtime Certificate Renewal**:
```ruby
lifecycle: {
  create_before_destroy: true,  # Creates new certificate before destroying old
  prevent_destroy: true         # Prevents accidental deletion
}
```

**Certificate Transparency Logging**:
```ruby
certificate_transparency_logging_preference: "ENABLED"  # Public certificate transparency
```

## Computed Properties

**Certificate Analysis Methods**:
```ruby
def is_wildcard_certificate?
  domain_name.start_with?('*.')
end

def total_domain_count
  1 + (subject_alternative_names&.length || 0)
end

def certificate_scope
  if is_wildcard_certificate?
    "Wildcard certificate for #{domain_name}"
  elsif subject_alternative_names&.any?
    "Multi-domain certificate covering #{total_domain_count} domains"
  else
    "Single domain certificate"
  end
end
```

## AWS Integration Patterns

### Load Balancer SSL Termination

```ruby
# Certificate for load balancer
ssl_cert = aws_acm_certificate(:app_cert, {
  domain_name: "api.example.com",
  validation_method: "DNS"
})

# HTTPS listener using certificate
https_listener = aws_lb_listener(:https, {
  load_balancer_arn: lb.arn,
  port: 443,
  protocol: "HTTPS",
  certificate_arn: ssl_cert.arn,  # Certificate integration
  ssl_policy: "ELBSecurityPolicy-TLS-1-2-2017-01"
})
```

### CloudFront Distribution SSL

```ruby
# Certificate must be in us-east-1 for CloudFront
cloudfront_cert = aws_acm_certificate(:cf_cert, {
  domain_name: "cdn.example.com",
  validation_method: "DNS"
})

cloudfront_distribution = aws_cloudfront_distribution(:cdn, {
  aliases: ["cdn.example.com"],
  viewer_certificate: {
    acm_certificate_arn: cloudfront_cert.arn,
    ssl_support_method: "sni-only",
    minimum_protocol_version: "TLSv1.2_2021"
  }
})
```

### Route53 DNS Validation Integration

```ruby
# Automatic DNS validation record creation
cert.domain_validation_options.each_with_index do |dvo, index|
  aws_route53_record(:"cert_validation_#{index}", {
    zone_id: hosted_zone.zone_id,
    name: dvo[:resource_record_name],
    type: dvo[:resource_record_type],
    ttl: 60,
    records: [dvo[:resource_record_value]]
  })
end
```

## Error Handling & Validation

### Common Validation Errors

1. **Invalid Domain Format**:
   ```
   Domain name validation failed: Invalid characters or format
   ```

2. **Wildcard Misuse**:
   ```
   Invalid wildcard domain: *.*.example.com. Wildcards must be at the start
   ```

3. **Domain Limit Exceeded**:
   ```
   ACM certificate supports maximum 100 domain names (including primary domain)
   ```

4. **Validation Mismatch**:
   ```
   Validation option domain 'test.com' not found in certificate domains
   ```

### Production Validation Checklist

- [ ] Domain names follow proper format
- [ ] Wildcard certificates use correct pattern
- [ ] DNS validation records are accessible
- [ ] Certificate transparency logging enabled
- [ ] Lifecycle rules configured for zero-downtime renewal
- [ ] Tags applied for resource management
- [ ] Key algorithm appropriate for security requirements

## Monitoring & Observability

### Certificate Status Monitoring

Monitor these certificate outputs:
- `status`: Track validation and issuance progress
- `not_after`: Monitor expiration dates
- `pending_renewal`: Track renewal status
- `renewal_eligibility`: Verify auto-renewal capability

### Operational Metrics

- Certificate validation time
- DNS record propagation time
- Certificate usage across load balancers/CloudFront
- Auto-renewal success rate

This implementation provides enterprise-grade SSL/TLS certificate management with comprehensive validation, security controls, and integration capabilities for production AWS environments.