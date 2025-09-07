# AWS Cognito User Pool - Technical Implementation Guide

## Overview

The `aws_cognito_user_pool` resource provides type-safe creation and management of AWS Cognito User Pools with comprehensive validation for authentication, authorization, and identity management scenarios.

## Architecture Integration

### Authentication Patterns

```ruby
template :user_authentication do
  # Basic email authentication
  user_pool = aws_cognito_user_pool(:main_pool, 
    UserPoolTemplates.basic_email_auth("MainUserPool")
  )
  
  # Web client for authentication
  user_pool_client = aws_cognito_user_pool_client(:web_client, {
    user_pool_id: user_pool.id,
    client_name: "WebClient",
    generate_secret: false,
    allowed_oauth_flows: ["code"],
    allowed_oauth_scopes: ["email", "openid", "profile"],
    callback_urls: ["https://app.example.com/callback"]
  })
end
```

### Enterprise Security Template

```ruby
template :enterprise_auth do
  # High-security user pool with MFA and advanced security
  user_pool = aws_cognito_user_pool(:enterprise_pool, {
    name: "EnterpriseUserPool",
    username_attributes: ["email"],
    auto_verified_attributes: ["email"],
    
    # Enforce MFA
    mfa_configuration: "ON",
    software_token_mfa_configuration: { enabled: true },
    
    # Advanced security features
    user_pool_add_ons: {
      advanced_security_mode: "ENFORCED"
    },
    
    # Strong password policy
    password_policy: {
      minimum_length: 14,
      require_lowercase: true,
      require_uppercase: true, 
      require_numbers: true,
      require_symbols: true,
      temporary_password_validity_days: 1
    },
    
    # Device management
    device_configuration: {
      challenge_required_on_new_device: true,
      device_only_remembered_on_user_prompt: false
    },
    
    # Account recovery
    account_recovery_setting: {
      recovery_mechanisms: [
        { name: "verified_email", priority: 1 }
      ]
    }
  })
end
```

### Mobile App Authentication

```ruby
template :mobile_auth do
  # SMS-based authentication for mobile apps
  sns_role = aws_iam_role(:cognito_sms_role, {
    assume_role_policy: TrustPolicies.service("cognito-idp.amazonaws.com"),
    managed_policy_arns: [
      "arn:aws:iam::aws:policy/service-role/AmazonCognitoSMSRole"
    ]
  })
  
  user_pool = aws_cognito_user_pool(:mobile_pool, {
    name: "MobileUserPool",
    username_attributes: ["phone_number"],
    auto_verified_attributes: ["phone_number"],
    
    # SMS configuration
    sms_configuration: {
      external_id: "mobile-app-external",
      sns_caller_arn: sns_role.arn
    },
    
    # MFA via SMS
    mfa_configuration: "OPTIONAL",
    sms_authentication_message: "Your verification code: {####}",
    
    # Custom verification messages
    verification_message_template: {
      sms_message: "Welcome! Your verification code is {####}",
      default_email_option: "CONFIRM_WITH_CODE"
    }
  })
end
```

## Type-Safe Configuration

### Password Policy Validation
```ruby
# Compile-time type checking with runtime validation
password_policy = CognitoUserPoolPasswordPolicy.new({
  minimum_length: 12,        # Must be 6-99
  require_lowercase: true,
  require_uppercase: true,
  require_numbers: true,
  require_symbols: false,
  temporary_password_validity_days: 7  # Must be 0-365
})

# Raises Dry::Struct::Error if invalid
user_pool = aws_cognito_user_pool(:validated_pool, {
  password_policy: password_policy
})
```

### Schema Attribute Configuration
```ruby
# Custom user attributes with validation
user_pool = aws_cognito_user_pool(:custom_attrs_pool, {
  schema: [
    CognitoUserPoolSchemaAttribute.new({
      attribute_data_type: "String",
      name: "department",
      mutable: true,
      required: false,
      string_attribute_constraints: {
        min_length: "1",
        max_length: "100"
      }
    }),
    CognitoUserPoolSchemaAttribute.new({
      attribute_data_type: "Number",
      name: "employee_id", 
      mutable: false,
      required: true,
      number_attribute_constraints: {
        min_value: "1000",
        max_value: "999999"
      }
    })
  ]
})
```

## Lambda Integration Patterns

### Complete Custom Auth Flow
```ruby
template :custom_auth_flow do
  # Lambda functions for custom authentication
  pre_signup_lambda = aws_lambda_function(:pre_signup, { ... })
  define_auth_lambda = aws_lambda_function(:define_auth, { ... })
  create_auth_lambda = aws_lambda_function(:create_auth, { ... })
  verify_auth_lambda = aws_lambda_function(:verify_auth, { ... })
  
  user_pool = aws_cognito_user_pool(:custom_auth_pool, {
    name: "CustomAuthPool",
    lambda_config: {
      pre_sign_up: pre_signup_lambda.arn,
      define_auth_challenge: define_auth_lambda.arn,
      create_auth_challenge: create_auth_lambda.arn,
      verify_auth_challenge_response: verify_auth_lambda.arn,
      pre_authentication: pre_auth_lambda.arn,
      post_authentication: post_auth_lambda.arn,
      kms_key_id: kms_key.id  # Encrypt lambda environment variables
    }
  })
  
  # Grant Cognito permission to invoke lambdas
  [pre_signup_lambda, define_auth_lambda, create_auth_lambda, verify_auth_lambda].each do |func|
    aws_lambda_permission(:"#{func.name}_cognito_permission", {
      statement_id: "AllowCognitoInvoke",
      action: "lambda:InvokeFunction", 
      function_name: func.function_name,
      principal: "cognito-idp.amazonaws.com",
      source_arn: user_pool.arn
    })
  end
end
```

## Email Configuration Patterns

### SES Integration
```ruby
template :ses_email_config do
  # Verified domain in SES
  ses_domain = aws_ses_domain_identity(:app_domain, {
    domain: "auth.myapp.com"
  })
  
  # SES sending identity
  ses_identity_policy = aws_ses_identity_policy(:cognito_policy, {
    identity: ses_domain.domain,
    name: "CognitoEmailPolicy", 
    policy: {
      Version: "2012-10-17",
      Statement: [{
        Effect: "Allow",
        Principal: { Service: "cognito-idp.amazonaws.com" },
        Action: ["ses:SendEmail", "ses:SendRawEmail"],
        Resource: "*"
      }]
    }
  })
  
  user_pool = aws_cognito_user_pool(:ses_pool, {
    name: "SESUserPool",
    email_configuration: {
      email_sending_account: "DEVELOPER",
      source_arn: "arn:aws:ses:us-east-1:#{data.aws_caller_identity.current.account_id}:identity/auth.myapp.com",
      from_email_address: "noreply@auth.myapp.com",
      reply_to_email_address: "support@myapp.com"
    },
    verification_message_template: {
      default_email_option: "CONFIRM_WITH_LINK",
      email_subject: "Verify your MyApp account",
      email_message_by_link: "Please click the link to verify: {##Click Here##}"
    }
  })
end
```

## Security Best Practices Implementation

### Comprehensive Security Template
```ruby
# Maximum security configuration
def self.maximum_security_pool(pool_name)
  {
    name: pool_name,
    username_attributes: ["email"],
    auto_verified_attributes: ["email"],
    
    # Force MFA
    mfa_configuration: "ON",
    software_token_mfa_configuration: { enabled: true },
    
    # Advanced security with enforcement
    user_pool_add_ons: {
      advanced_security_mode: "ENFORCED" 
    },
    
    # Strict password requirements
    password_policy: {
      minimum_length: 16,
      require_lowercase: true,
      require_uppercase: true,
      require_numbers: true, 
      require_symbols: true,
      temporary_password_validity_days: 1
    },
    
    # Device security
    device_configuration: {
      challenge_required_on_new_device: true,
      device_only_remembered_on_user_prompt: false
    },
    
    # Strict admin control
    admin_create_user_config: {
      allow_admin_create_user_only: true,
      unused_account_validity_days: 7
    },
    
    # Account recovery via admin only (highest security)
    account_recovery_setting: {
      recovery_mechanisms: [
        { name: "admin_only", priority: 1 }
      ]
    },
    
    # Require verification before attribute updates
    user_attribute_update_settings: {
      attributes_require_verification_before_update: ["email"]
    },
    
    # Deletion protection
    deletion_protection: "ACTIVE"
  }
end
```

## Cross-Resource Integration

### Complete Authentication Architecture
```ruby
template :complete_auth_architecture do
  # Core user pool
  user_pool = aws_cognito_user_pool(:main_pool, 
    UserPoolTemplates.enterprise_security("MainPool")
  )
  
  # Web application client
  web_client = aws_cognito_user_pool_client(:web_client, {
    user_pool_id: user_pool.id,
    client_name: "WebClient",
    generate_secret: false,
    allowed_oauth_flows: ["code"],
    allowed_oauth_scopes: ["email", "openid", "profile"],
    callback_urls: ["https://app.example.com/callback"],
    logout_urls: ["https://app.example.com/logout"],
    prevent_user_existence_errors: "ENABLED"
  })
  
  # Mobile client with secret
  mobile_client = aws_cognito_user_pool_client(:mobile_client, {
    user_pool_id: user_pool.id,
    client_name: "MobileClient", 
    generate_secret: true,
    allowed_oauth_flows: ["code"],
    allowed_oauth_scopes: ["email", "openid", "profile"],
    supported_identity_providers: ["COGNITO"],
    prevent_user_existence_errors: "ENABLED"
  })
  
  # Custom domain for hosted UI
  domain = aws_cognito_user_pool_domain(:custom_domain, {
    domain: "auth.myapp.com",
    user_pool_id: user_pool.id,
    certificate_arn: acm_certificate.arn
  })
  
  # Admin user group
  admin_group = aws_cognito_user_group(:admins, {
    name: "Administrators",
    user_pool_id: user_pool.id,
    description: "Application administrators",
    precedence: 1,
    role_arn: admin_role.arn
  })
  
  # Identity pool for AWS resource access
  identity_pool = aws_cognito_identity_pool(:main_identity_pool, {
    identity_pool_name: "MainIdentityPool",
    allow_unauthenticated_identities: false,
    cognito_identity_providers: [{
      client_id: web_client.id,
      provider_name: user_pool.endpoint
    }]
  })
end
```

## Computed Properties Usage

```ruby
user_pool = aws_cognito_user_pool(:dynamic_pool, pool_config)

# Conditional resource creation based on auth method
if user_pool.computed_properties[:uses_email_auth]
  # Create SES configuration for email
  email_configuration_resources
end

if user_pool.computed_properties[:mfa_enabled] 
  # Create additional MFA-related resources
  mfa_configuration_resources
end

# Route53 record only if using custom domain
if user_pool.outputs[:custom_domain]
  aws_route53_record(:auth_domain_record, {
    zone_id: hosted_zone.zone_id,
    name: "auth.myapp.com",
    type: "A",
    alias: {
      name: user_pool.outputs[:domain],
      zone_id: cognito_zone_id,
      evaluate_target_health: false
    }
  })
end
```

## Error Handling and Validation

### Custom Validation Rules
```ruby
# The CognitoUserPoolAttributes struct includes built-in validation:

begin
  user_pool_attrs = CognitoUserPoolAttributes.new({
    username_attributes: ["email"],
    alias_attributes: ["email"]  # This will raise an error
  })
rescue Dry::Struct::Error => e
  puts e.message  # "Cannot specify the same attribute in both username_attributes and alias_attributes"
end

# Account recovery mechanism validation
begin
  user_pool_attrs = CognitoUserPoolAttributes.new({
    account_recovery_setting: {
      recovery_mechanisms: [
        { name: "verified_email", priority: 1 },
        { name: "verified_phone_number", priority: 1 }  # Duplicate priority error
      ]
    }
  })
rescue Dry::Struct::Error => e
  puts e.message  # "Account recovery mechanisms must have unique priorities"
end
```

## Performance and Scalability Considerations

1. **Template-Level State Isolation**: Each user pool template creates separate Terraform state
2. **Resource Dependencies**: Proper dependency management between user pool, clients, and domains  
3. **Lambda Cold Starts**: Consider provisioned concurrency for auth Lambda triggers
4. **Advanced Security**: Monitor CloudWatch metrics for risk-based authentication
5. **Device Memory**: Balance security vs. user experience in device remembering
6. **Rate Limiting**: Advanced security mode provides automatic rate limiting
7. **Multi-Region**: Use separate user pools per region for geo-distributed applications

This implementation provides enterprise-grade identity management with complete type safety, comprehensive validation, and flexible architectural patterns for any authentication scenario.