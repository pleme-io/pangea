# AWS Cognito User Pool Domain - Technical Implementation Guide

## Overview

The `aws_cognito_user_pool_domain` resource provides type-safe creation and management of Cognito hosted UI domains with comprehensive validation for custom domains, SSL certificates, and DNS configuration.

## Architecture Integration

### Complete Hosted UI Setup

```ruby
template :hosted_ui_architecture do
  # Core user pool with hosted UI configuration
  user_pool = aws_cognito_user_pool(:hosted_ui_pool, {
    name: "HostedUIPool",
    username_attributes: ["email"],
    auto_verified_attributes: ["email"],
    
    # Hosted UI specific configuration
    verification_message_template: {
      default_email_option: "CONFIRM_WITH_LINK",
      email_subject: "Welcome to MyApp - Verify Your Account",
      email_message_by_link: "Please click {##Verify Email##} to confirm your account."
    }
  })
  
  # Web client optimized for hosted UI
  hosted_ui_client = aws_cognito_user_pool_client(:hosted_ui_client, {
    name: "HostedUIClient",
    user_pool_id: user_pool.id,
    generate_secret: false,
    
    # OAuth configuration for hosted UI
    allowed_oauth_flows: ["code"],
    allowed_oauth_flows_user_pool_client: true,
    allowed_oauth_scopes: ["phone", "email", "openid", "profile"],
    
    # Callback/logout URLs
    callback_urls: [
      "https://app.mycompany.com/auth/callback",
      "https://app.mycompany.com/auth/silent"
    ],
    logout_urls: ["https://app.mycompany.com/"],
    
    supported_identity_providers: ["COGNITO"],
    prevent_user_existence_errors: "ENABLED"
  })
  
  # SSL certificate for custom domain (must be in us-east-1)
  auth_certificate = aws_acm_certificate(:auth_certificate, {
    domain_name: "auth.mycompany.com",
    subject_alternative_names: ["*.auth.mycompany.com"],
    validation_method: "DNS",
    
    tags: {
      Name: "MyCompany Auth Domain Certificate",
      Environment: "production",
      Purpose: "cognito-hosted-ui"
    }
  })
  
  # Certificate validation via Route53
  cert_validation = aws_acm_certificate_validation(:auth_cert_validation, {
    certificate_arn: auth_certificate.arn,
    validation_record_fqdns: validation_records.map(&:fqdn)
  })
  
  # Custom domain with validated certificate
  auth_domain = aws_cognito_user_pool_domain(:auth_domain, {
    domain: "auth.mycompany.com",
    user_pool_id: user_pool.id,
    certificate_arn: cert_validation.certificate_arn
  })
  
  # Route53 alias record pointing to CloudFront
  auth_dns_record = aws_route53_record(:auth_dns, {
    zone_id: company_hosted_zone.zone_id,
    name: "auth.mycompany.com",
    type: "A",
    
    alias: {
      name: auth_domain.outputs[:cloudfront_distribution_arn],
      zone_id: "Z2FDTNDATAQYW2",  # CloudFront hosted zone ID
      evaluate_target_health: false
    },
    
    tags: {
      Name: "Cognito Auth Domain Alias",
      Purpose: "cognito-hosted-ui"
    }
  })
end
```

### Multi-Environment Domain Strategy

```ruby
template :multi_environment_domains do
  # Environment-specific configuration
  environments = {
    development: {
      user_pool_id: dev_user_pool.id,
      use_custom_domain: false,
      domain_prefix: "myapp-dev-auth"
    },
    staging: {
      user_pool_id: staging_user_pool.id,
      use_custom_domain: true,
      custom_domain: "auth-staging.myapp.com",
      certificate_arn: staging_certificate.arn
    },
    production: {
      user_pool_id: prod_user_pool.id,
      use_custom_domain: true,
      custom_domain: "auth.myapp.com", 
      certificate_arn: prod_certificate.arn
    }
  }
  
  environments.each do |env_name, config|
    if config[:use_custom_domain]
      # Custom domain for staging/production
      aws_cognito_user_pool_domain(:"#{env_name}_domain", {
        domain: config[:custom_domain],
        user_pool_id: config[:user_pool_id],
        certificate_arn: config[:certificate_arn]
      })
      
      # DNS record for custom domain
      aws_route53_record(:"#{env_name}_auth_dns", {
        zone_id: hosted_zone.zone_id,
        name: config[:custom_domain],
        type: "A",
        alias: {
          name: "${aws_cognito_user_pool_domain.#{env_name}_domain.cloudfront_distribution_arn}",
          zone_id: "Z2FDTNDATAQYW2",
          evaluate_target_health: false
        }
      })
    else
      # Cognito domain for development
      aws_cognito_user_pool_domain(:"#{env_name}_domain", {
        domain: config[:domain_prefix],
        user_pool_id: config[:user_pool_id]
      })
    end
  end
end
```

## Type-Safe Domain Configuration

### Domain Format Validation
```ruby
# Custom domain validation
begin
  custom_domain_attrs = CognitoUserPoolDomainAttributes.new({
    domain: "auth.myapp.com",
    user_pool_id: user_pool.id
    # Missing certificate_arn for custom domain
  })
rescue Dry::Struct::Error => e
  puts e.message  # "certificate_arn is required for custom domains"
end

# Cognito domain prefix validation
begin
  cognito_domain_attrs = CognitoUserPoolDomainAttributes.new({
    domain: "My-App-Auth",  # Invalid: uppercase and special chars
    user_pool_id: user_pool.id
  })
rescue Dry::Struct::Error => e
  puts e.message  # "Cognito domain prefix must contain only lowercase..."
end

# Certificate region validation
valid_attrs = CognitoUserPoolDomainAttributes.new({
  domain: "auth.myapp.com",
  user_pool_id: user_pool.id,
  certificate_arn: "arn:aws:acm:us-east-1:123456789012:certificate/abc123"
})

puts valid_attrs.certificate_in_us_east_1?  # true
puts valid_attrs.certificate_region  # "us-east-1"
```

### Certificate Management Integration
```ruby
template :certificate_lifecycle_management do
  # Primary certificate
  primary_cert = aws_acm_certificate(:primary_auth_cert, {
    domain_name: "auth.myapp.com",
    validation_method: "DNS",
    
    lifecycle: {
      create_before_destroy: true
    }
  })
  
  # Certificate validation
  primary_validation = aws_acm_certificate_validation(:primary_validation, {
    certificate_arn: primary_cert.arn,
    validation_record_fqdns: dns_validation_records.map(&:fqdn),
    
    timeouts: {
      create: "10m"
    }
  })
  
  # Domain using validated certificate
  auth_domain = aws_cognito_user_pool_domain(:auth_domain, {
    domain: "auth.myapp.com",
    user_pool_id: user_pool.id, 
    certificate_arn: primary_validation.certificate_arn
  })
  
  # Backup certificate for rotation
  backup_cert = aws_acm_certificate(:backup_auth_cert, {
    domain_name: "auth.myapp.com",
    validation_method: "DNS",
    
    tags: {
      Purpose: "certificate-rotation",
      Status: "backup"
    }
  })
end
```

## Advanced Domain Patterns

### Multi-Region Custom Domains
```ruby
template :multi_region_auth_domains do
  # Primary region (us-east-1) with custom domain
  primary_cert = aws_acm_certificate(:primary_cert, {
    domain_name: "auth.myapp.com",
    validation_method: "DNS"
  })
  
  primary_domain = aws_cognito_user_pool_domain(:primary_domain, {
    domain: "auth.myapp.com",
    user_pool_id: primary_user_pool.id,
    certificate_arn: primary_cert.arn
  })
  
  # Failover region (us-west-2) with different subdomain
  # Certificate must still be in us-east-1 for CloudFront
  failover_cert = aws_acm_certificate(:failover_cert, {
    domain_name: "auth-west.myapp.com",
    validation_method: "DNS"
  })
  
  failover_domain = aws_cognito_user_pool_domain(:failover_domain, {
    domain: "auth-west.myapp.com",
    user_pool_id: failover_user_pool.id,
    certificate_arn: failover_cert.arn
  })
  
  # Route53 health checks for failover
  auth_health_check = aws_route53_health_check(:auth_health, {
    fqdn: "auth.myapp.com",
    port: 443,
    type: "HTTPS_STR_MATCH",
    search_string: "Cognito",
    request_interval: "30"
  })
  
  # Primary DNS record with health check
  primary_dns = aws_route53_record(:primary_auth_dns, {
    zone_id: hosted_zone.zone_id,
    name: "auth.myapp.com",
    type: "A",
    set_identifier: "primary",
    failover_routing_policy: {
      type: "PRIMARY"
    },
    health_check_id: auth_health_check.id,
    alias: {
      name: primary_domain.outputs[:cloudfront_distribution_arn],
      zone_id: "Z2FDTNDATAQYW2",
      evaluate_target_health: false
    }
  })
  
  # Failover DNS record
  failover_dns = aws_route53_record(:failover_auth_dns, {
    zone_id: hosted_zone.zone_id,
    name: "auth.myapp.com", 
    type: "A",
    set_identifier: "failover",
    failover_routing_policy: {
      type: "SECONDARY"
    },
    alias: {
      name: failover_domain.outputs[:cloudfront_distribution_arn],
      zone_id: "Z2FDTNDATAQYW2",
      evaluate_target_health: false
    }
  })
end
```

### Development Workflow Integration
```ruby
template :development_domain_workflow do
  # Feature branch domains for testing
  feature_branches = ["feature-oauth", "feature-sso", "feature-mfa"]
  
  feature_branches.each do |branch|
    branch_safe = branch.gsub(/[^a-z0-9]/, '-')
    
    # Cognito domain for feature branch
    branch_domain = aws_cognito_user_pool_domain(:"#{branch_safe.gsub('-', '_')}_domain", {
      domain: "myapp-#{branch_safe}",
      user_pool_id: feature_user_pool.id
    })
    
    # Update client callback URLs to include branch domain
    aws_cognito_user_pool_client(:"#{branch_safe.gsub('-', '_')}_client", {
      name: "#{branch.capitalize}Client",
      user_pool_id: feature_user_pool.id,
      generate_secret: false,
      allowed_oauth_flows: ["code"],
      allowed_oauth_flows_user_pool_client: true,
      allowed_oauth_scopes: ["email", "openid", "profile"],
      callback_urls: [
        "https://#{branch_safe}.dev.myapp.com/auth/callback",
        "http://localhost:3000/auth/callback"
      ],
      logout_urls: [
        "https://#{branch_safe}.dev.myapp.com/",
        "http://localhost:3000/"
      ]
    })
  end
end
```

## Domain Templates Usage

```ruby
template :template_based_domains do
  # Production setup
  prod_domain_config = UserPoolDomainTemplates.production_custom_domain(
    "mycompany.com", 
    prod_user_pool.id, 
    prod_certificate.arn
  )
  prod_domain = aws_cognito_user_pool_domain(:prod_domain, prod_domain_config)
  
  # Staging with conditional custom domain
  staging_domain_config = UserPoolDomainTemplates.staging_domain(
    "mycompany.com",
    staging_user_pool.id,
    staging_certificate&.arn  # May be nil
  )
  staging_domain = aws_cognito_user_pool_domain(:staging_domain, staging_domain_config)
  
  # Development Cognito domain
  dev_domain_config = UserPoolDomainTemplates.development_domain(
    "myapp",
    dev_user_pool.id,
    "dev"
  )
  dev_domain = aws_cognito_user_pool_domain(:dev_domain, dev_domain_config)
  
  # Environment-agnostic approach
  env_domain_config = UserPoolDomainTemplates.environment_domain(
    "mycompany.com",
    deployment_environment,
    user_pool.id,
    environment_certificate&.arn
  )
  env_domain = aws_cognito_user_pool_domain(:env_domain, env_domain_config)
end
```

## Computed Properties Usage

```ruby
domain = aws_cognito_user_pool_domain(:dynamic_domain, domain_config)

# Conditional DNS record creation
if domain.computed_properties[:custom_domain]
  # Create Route53 alias record for custom domain
  aws_route53_record(:domain_alias, {
    zone_id: hosted_zone.zone_id,
    name: domain_config[:domain],
    type: "A",
    alias: {
      name: domain.outputs[:cloudfront_distribution_arn],
      zone_id: "Z2FDTNDATAQYW2",
      evaluate_target_health: false
    }
  })
end

# Certificate validation based on computed properties
if domain.computed_properties[:ssl_required] && !domain.computed_properties[:certificate_in_us_east_1]
  raise "Certificate must be in us-east-1 region for CloudFront distribution"
end

# CloudWatch monitoring based on domain type
if domain.computed_properties[:custom_domain]
  # Monitor CloudFront distribution metrics
  aws_cloudwatch_metric_alarm(:domain_error_rate, {
    alarm_name: "CognitoDomain-ErrorRate",
    comparison_operator: "GreaterThanThreshold",
    evaluation_periods: 2,
    metric_name: "4xxErrorRate",
    namespace: "AWS/CloudFront",
    period: 300,
    statistic: "Average",
    threshold: 5,
    dimensions: {
      DistributionId: domain.outputs[:cloudfront_distribution_arn].split('/').last
    }
  })
end
```

## Security and Monitoring

### Domain Security Monitoring
```ruby
template :domain_security_monitoring do
  auth_domain = aws_cognito_user_pool_domain(:monitored_domain, domain_config)
  
  # CloudWatch alarms for custom domain health
  if auth_domain.computed_properties[:custom_domain]
    # High error rate alarm
    aws_cloudwatch_metric_alarm(:domain_error_alarm, {
      alarm_name: "CognitoDomain-HighErrorRate",
      alarm_description: "High error rate on Cognito custom domain",
      metric_name: "4xxErrorRate",
      namespace: "AWS/CloudFront",
      statistic: "Average",
      period: 300,
      evaluation_periods: 2,
      threshold: 10,
      comparison_operator: "GreaterThanThreshold",
      alarm_actions: [sns_alert_topic.arn]
    })
    
    # Low request count (potential outage)
    aws_cloudwatch_metric_alarm(:domain_requests_alarm, {
      alarm_name: "CognitoDomain-LowRequests",
      alarm_description: "Unusually low requests to Cognito domain",
      metric_name: "Requests",
      namespace: "AWS/CloudFront", 
      statistic: "Sum",
      period: 900,
      evaluation_periods: 2,
      threshold: 10,
      comparison_operator: "LessThanThreshold",
      alarm_actions: [sns_alert_topic.arn],
      treat_missing_data: "breaching"
    })
  end
  
  # Certificate expiration monitoring
  if auth_domain.computed_properties[:certificate_arn_valid]
    aws_cloudwatch_metric_alarm(:cert_expiration_alarm, {
      alarm_name: "CognitoDomain-CertExpiring",
      alarm_description: "SSL certificate expiring soon",
      metric_name: "DaysToExpiry",
      namespace: "AWS/CertificateManager",
      statistic: "Minimum",
      period: 86400,  # Daily check
      evaluation_periods: 1,
      threshold: 30,  # 30 days
      comparison_operator: "LessThanThreshold",
      alarm_actions: [sns_alert_topic.arn]
    })
  end
end
```

## Error Handling and Troubleshooting

### Common Domain Configuration Errors
```ruby
# Validation catches most errors at compile time
begin
  # Invalid custom domain without certificate
  invalid_config = CognitoUserPoolDomainAttributes.new({
    domain: "auth.myapp.com",  # Custom domain
    user_pool_id: user_pool.id
    # Missing certificate_arn
  })
rescue Dry::Struct::Error => e
  puts "Configuration Error: #{e.message}"
  # "certificate_arn is required for custom domains"
end

# Certificate region validation
begin
  wrong_region_config = CognitoUserPoolDomainAttributes.new({
    domain: "auth.myapp.com",
    user_pool_id: user_pool.id,
    certificate_arn: "arn:aws:acm:us-west-2:123456789012:certificate/abc123"
  })
  
  unless wrong_region_config.certificate_in_us_east_1?
    puts "Warning: Certificate not in us-east-1, CloudFront may not work"
  end
rescue Dry::Struct::Error => e
  puts "Certificate Error: #{e.message}"
end
```

### Operational Considerations

1. **Certificate Renewal**: Automated via ACM for AWS-issued certificates
2. **DNS Propagation**: Custom domains may take 10-60 minutes to propagate
3. **CloudFront Distribution**: Created automatically, cannot be customized
4. **Domain Uniqueness**: Cognito domain prefixes must be globally unique
5. **Regional Constraints**: Certificates must be in us-east-1 for CloudFront
6. **Failover Strategy**: Consider multiple domains for high availability
7. **Cost Implications**: Custom domains incur CloudFront charges
8. **Monitoring Requirements**: Set up comprehensive monitoring for production

This implementation provides enterprise-grade domain management with complete type safety, comprehensive validation, and flexible architectural patterns for any hosted UI authentication scenario.