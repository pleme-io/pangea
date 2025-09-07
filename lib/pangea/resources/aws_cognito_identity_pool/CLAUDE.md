# AWS Cognito Identity Pool - Technical Implementation Guide

## Overview

The `aws_cognito_identity_pool` resource provides type-safe creation and management of Cognito Identity Pools with comprehensive validation for federated identity management, AWS resource access, and cross-platform authentication scenarios.

## Architecture Integration

### Complete Federated Identity Architecture

```ruby
template :federated_identity_architecture do
  # Core User Pool for primary authentication
  user_pool = aws_cognito_user_pool(:main_pool, {
    name: "MainUserPool",
    username_attributes: ["email"],
    auto_verified_attributes: ["email"],
    mfa_configuration: "OPTIONAL",
    password_policy: {
      minimum_length: 12,
      require_lowercase: true,
      require_uppercase: true,
      require_numbers: true,
      require_symbols: true
    }
  })
  
  # User pool client for web applications
  web_client = aws_cognito_user_pool_client(:web_client, {
    name: "WebAppClient",
    user_pool_id: user_pool.id,
    generate_secret: false,
    allowed_oauth_flows: ["code"],
    allowed_oauth_flows_user_pool_client: true,
    allowed_oauth_scopes: ["email", "openid", "profile"],
    callback_urls: ["https://app.example.com/auth/callback"]
  })
  
  # SAML identity provider for enterprise SSO
  saml_provider = aws_iam_saml_identity_provider(:company_saml, {
    name: "CompanySAML",
    saml_metadata_document: company_saml_metadata
  })
  
  # OpenID Connect provider for third-party integration
  oidc_provider = aws_iam_openid_connect_identity_provider(:auth0_oidc, {
    url: "https://company.auth0.com",
    client_id_list: [auth0_client_id],
    thumbprint_list: [auth0_thumbprint]
  })
  
  # Comprehensive identity pool with multiple authentication methods
  identity_pool = aws_cognito_identity_pool(:comprehensive_pool, {
    identity_pool_name: "ComprehensiveIdentityPool",
    allow_unauthenticated_identities: false,
    
    # Cognito User Pool authentication
    cognito_identity_providers: [{
      client_id: web_client.id,
      provider_name: user_pool.endpoint,
      server_side_token_check: true
    }],
    
    # Social authentication providers
    supported_login_providers: {
      "accounts.google.com" => google_oauth_client_id,
      "graph.facebook.com" => facebook_app_id,
      "www.amazon.com" => amazon_app_id
    },
    
    # Enterprise SAML federation
    saml_provider_arns: [saml_provider.arn],
    
    # Third-party OIDC providers
    openid_connect_provider_arns: [oidc_provider.arn],
    
    tags: {
      Environment: "production",
      Architecture: "federated-identity",
      SecurityLevel: "high"
    }
  })
  
  # Graduated IAM role permissions based on authentication method
  authenticated_role = create_authenticated_role(identity_pool)
  privileged_role = create_privileged_role(identity_pool)
  
  # Role mapping based on claims
  aws_cognito_identity_pool_roles_attachment(:identity_pool_roles, {
    identity_pool_id: identity_pool.id,
    roles: {
      authenticated: authenticated_role.arn
    },
    role_mappings: {
      "#{user_pool.endpoint}:#{web_client.id}" => {
        type: "Rules",
        ambiguous_role_resolution: "AuthenticatedRole",
        rules_configuration: {
          rules: [
            {
              claim: "custom:role",
              match_type: "Equals",
              value: "admin",
              role_arn: privileged_role.arn
            }
          ]
        }
      }
    }
  })
end
```

### Mobile-First Identity Architecture

```ruby
template :mobile_first_identity do
  # Mobile-optimized user pool
  mobile_user_pool = aws_cognito_user_pool(:mobile_pool, {
    name: "MobileUserPool",
    username_attributes: ["email", "phone_number"],
    auto_verified_attributes: ["email", "phone_number"],
    
    # Mobile-friendly verification
    verification_message_template: {
      default_email_option: "CONFIRM_WITH_CODE",
      sms_message: "Your verification code: {####}"
    },
    
    # Shorter session validity for mobile security
    password_policy: {
      minimum_length: 8,
      temporary_password_validity_days: 1
    }
  })
  
  # Mobile client configuration
  mobile_client = aws_cognito_user_pool_client(:mobile_client, {
    name: "MobileAppClient",
    user_pool_id: mobile_user_pool.id,
    generate_secret: false,  # Public client for mobile
    explicit_auth_flows: [
      "ALLOW_USER_SRP_AUTH",
      "ALLOW_REFRESH_TOKEN_AUTH",
      "ALLOW_USER_PASSWORD_AUTH"  # Convenience for mobile
    ],
    # Short token validity for mobile security
    access_token_validity: 60,   # 1 hour
    id_token_validity: 60,       # 1 hour  
    refresh_token_validity: 30,  # 30 days
    token_validity_units: {
      access_token: "minutes",
      id_token: "minutes",
      refresh_token: "days"
    }
  })
  
  # Identity pool with guest access for mobile onboarding
  mobile_identity_pool = aws_cognito_identity_pool(:mobile_identity_pool, {
    identity_pool_name: "MobileIdentityPool",
    allow_unauthenticated_identities: true,  # Guest users
    
    # Authenticated users via User Pool
    cognito_identity_providers: [{
      client_id: mobile_client.id,
      provider_name: mobile_user_pool.endpoint,
      server_side_token_check: false  # Mobile apps typically client-side
    }],
    
    # Social login for mobile convenience
    supported_login_providers: {
      "accounts.google.com" => google_mobile_client_id,
      "graph.facebook.com" => facebook_mobile_app_id,
      "appleid.apple.com" => apple_sign_in_service_id
    },
    
    tags: {
      Platform: "mobile",
      UserExperience: "guest-friendly"
    }
  })
  
  # Mobile-specific IAM roles with device-based permissions
  mobile_authenticated_role = aws_iam_role(:mobile_authenticated_role, {
    assume_role_policy: cognito_identity_assume_role_policy(mobile_identity_pool.id, "authenticated"),
    inline_policies: {
      MobileUserAccess: {
        Version: "2012-10-17",
        Statement: [
          # User-scoped S3 access
          {
            Effect: "Allow",
            Action: ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"],
            Resource: "arn:aws:s3:::mobile-user-data/${cognito-identity.amazonaws.com:sub}/*"
          },
          # DynamoDB access for user data
          {
            Effect: "Allow",
            Action: ["dynamodb:Query", "dynamodb:GetItem", "dynamodb:PutItem", "dynamodb:UpdateItem"],
            Resource: "arn:aws:dynamodb:us-east-1:*:table/MobileUserData",
            Condition: {
              "ForAllValues:StringEquals": {
                "dynamodb:LeadingKeys" => ["${cognito-identity.amazonaws.com:sub}"]
              }
            }
          },
          # IoT permissions for push notifications
          {
            Effect: "Allow",
            Action: ["iot:Connect", "iot:Subscribe", "iot:Receive"],
            Resource: "*",
            Condition: {
              StringEquals: {
                "iot:Connection.Thing.ThingName" => "${cognito-identity.amazonaws.com:sub}"
              }
            }
          }
        ]
      }
    }
  })
  
  # Guest role with limited access for onboarding
  mobile_guest_role = aws_iam_role(:mobile_guest_role, {
    assume_role_policy: cognito_identity_assume_role_policy(mobile_identity_pool.id, "unauthenticated"),
    inline_policies: {
      GuestAccess: {
        Version: "2012-10-17",
        Statement: [{
          Effect: "Allow",
          Action: ["s3:GetObject"],
          Resource: "arn:aws:s3:::mobile-public-content/*"
        }]
      }
    }
  })
end
```

## Type-Safe Identity Pool Configuration

### Authentication Method Validation
```ruby
# Compile-time and runtime validation prevents configuration errors
begin
  # Invalid configuration - no auth methods with unauthenticated disabled
  invalid_pool = CognitoIdentityPoolAttributes.new({
    identity_pool_name: "InvalidPool",
    allow_unauthenticated_identities: false
    # No authentication methods configured
  })
rescue Dry::Struct::Error => e
  puts e.message  # "At least one authentication method is required when unauthenticated identities are not allowed"
end

# Social provider validation
begin
  invalid_social_config = CognitoIdentityPoolAttributes.new({
    identity_pool_name: "TestPool",
    supported_login_providers: {
      "accounts.google.com" => "invalid-google-id"  # Invalid format
    }
  })
rescue Dry::Struct::Error => e
  puts e.message  # "Invalid Google OAuth client ID format"
end

# Valid configuration with multiple providers
valid_pool = CognitoIdentityPoolAttributes.new({
  identity_pool_name: "ValidPool",
  allow_unauthenticated_identities: false,
  cognito_identity_providers: [{
    client_id: "test-client-id",
    provider_name: "us-east-1_example"
  }],
  supported_login_providers: {
    "accounts.google.com" => "123456789-abcd.apps.googleusercontent.com",
    "graph.facebook.com" => "123456789"
  }
})

puts valid_pool.authentication_methods  # [:cognito_user_pools, :social_providers]
puts valid_pool.social_providers       # [:google, :facebook]
puts valid_pool.security_level         # :medium_high
```

### Advanced Provider Configuration
```ruby
# Enterprise-grade identity pool with comprehensive validation
enterprise_pool = aws_cognito_identity_pool(:enterprise_identity_pool, {
  identity_pool_name: "EnterpriseIdentityPool",
  allow_unauthenticated_identities: false,
  allow_classic_flow: false,  # Disable for better security
  
  # Multi-client Cognito User Pool support
  cognito_identity_providers: [
    {
      client_id: web_client.id,
      provider_name: user_pool.endpoint,
      server_side_token_check: true
    },
    {
      client_id: mobile_client.id,
      provider_name: user_pool.endpoint,
      server_side_token_check: false  # Mobile clients
    }
  ],
  
  # Curated social providers
  supported_login_providers: {
    "accounts.google.com" => workspace_google_client_id,
    "login.microsoftonline.com" => azure_ad_client_id
  },
  
  # Enterprise SAML providers
  saml_provider_arns: [
    active_directory_saml.arn,
    okta_saml_provider.arn
  ],
  
  # Custom authentication for special cases
  developer_provider_name: "enterprise_custom_auth"
})
```

## IAM Role Integration Patterns

### Dynamic Role Assignment Based on Claims
```ruby
template :claim_based_role_assignment do
  identity_pool = aws_cognito_identity_pool(:claim_based_pool, pool_config)
  
  # Base authenticated role
  base_authenticated_role = aws_iam_role(:base_authenticated_role, {
    assume_role_policy: cognito_identity_assume_role_policy(identity_pool.id, "authenticated"),
    managed_policy_arns: [
      "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
    ]
  })
  
  # Admin role with elevated permissions
  admin_role = aws_iam_role(:admin_role, {
    assume_role_policy: cognito_identity_assume_role_policy(identity_pool.id, "authenticated"),
    managed_policy_arns: [
      "arn:aws:iam::aws:policy/AmazonS3FullAccess",
      "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
    ]
  })
  
  # Manager role with intermediate permissions
  manager_role = aws_iam_role(:manager_role, {
    assume_role_policy: cognito_identity_assume_role_policy(identity_pool.id, "authenticated"),
    inline_policies: {
      ManagerAccess: {
        Version: "2012-10-17",
        Statement: [
          {
            Effect: "Allow",
            Action: ["s3:GetObject", "s3:PutObject"],
            Resource: "arn:aws:s3:::manager-bucket/*"
          },
          {
            Effect: "Allow",
            Action: ["dynamodb:Query", "dynamodb:GetItem"],
            Resource: "arn:aws:dynamodb:*:*:table/ManagerData"
          }
        ]
      }
    }
  })
  
  # Role attachment with claim-based mapping
  aws_cognito_identity_pool_roles_attachment(:role_mapping, {
    identity_pool_id: identity_pool.id,
    roles: {
      authenticated: base_authenticated_role.arn
    },
    role_mappings: {
      # User Pool role mapping based on custom attributes
      "#{user_pool.endpoint}:#{user_pool_client.id}" => {
        type: "Rules",
        ambiguous_role_resolution: "AuthenticatedRole",
        rules_configuration: {
          rules: [
            {
              claim: "custom:role",
              match_type: "Equals",
              value: "admin",
              role_arn: admin_role.arn
            },
            {
              claim: "custom:role", 
              match_type: "Equals",
              value: "manager",
              role_arn: manager_role.arn
            }
          ]
        }
      },
      
      # Social provider role mapping
      "accounts.google.com" => {
        type: "Rules",
        ambiguous_role_resolution: "AuthenticatedRole",
        rules_configuration: {
          rules: [{
            claim: "hd",  # Google Hosted Domain
            match_type: "Equals", 
            value: "company.com",
            role_arn: admin_role.arn
          }]
        }
      }
    }
  })
end
```

### Cross-Platform Role Strategy
```ruby
template :cross_platform_roles do
  identity_pool = aws_cognito_identity_pool(:cross_platform_pool, pool_config)
  
  # Web application role with browser-specific permissions
  web_role = aws_iam_role(:web_application_role, {
    assume_role_policy: cognito_identity_assume_role_policy(identity_pool.id, "authenticated"),
    inline_policies: {
      WebAppAccess: {
        Version: "2012-10-17",
        Statement: [
          # CloudFront signed URLs for content delivery
          {
            Effect: "Allow",
            Action: ["cloudfront:CreateInvalidation"],
            Resource: "*",
            Condition: {
              StringEquals: {
                "cloudfront:source-ip" => "${aws:SourceIp}"
              }
            }
          },
          # S3 access with browser-appropriate permissions
          {
            Effect: "Allow", 
            Action: ["s3:GetObject", "s3:PutObject"],
            Resource: "arn:aws:s3:::web-uploads/${cognito-identity.amazonaws.com:sub}/*"
          }
        ]
      }
    }
  })
  
  # Mobile application role with device-specific permissions
  mobile_role = aws_iam_role(:mobile_application_role, {
    assume_role_policy: cognito_identity_assume_role_policy(identity_pool.id, "authenticated"),
    inline_policies: {
      MobileAppAccess: {
        Version: "2012-10-17",
        Statement: [
          # IoT Core for push notifications and device communication
          {
            Effect: "Allow",
            Action: ["iot:Connect", "iot:Subscribe", "iot:Publish", "iot:Receive"],
            Resource: "*",
            Condition: {
              StringEquals: {
                "iot:Connection.Thing.ThingName" => "${cognito-identity.amazonaws.com:sub}"
              }
            }
          },
          # S3 access optimized for mobile bandwidth
          {
            Effect: "Allow",
            Action: ["s3:GetObject"],
            Resource: "arn:aws:s3:::mobile-optimized-content/*"
          }
        ]
      }
    }
  })
  
  # API/Service role for machine-to-machine authentication
  api_role = aws_iam_role(:api_service_role, {
    assume_role_policy: cognito_identity_assume_role_policy(identity_pool.id, "authenticated"),
    managed_policy_arns: [
      "arn:aws:iam::aws:policy/AmazonAPIGatewayInvokeFullAccess"
    ],
    inline_policies: {
      ServiceAccess: {
        Version: "2012-10-17",
        Statement: [
          # DynamoDB access for service operations
          {
            Effect: "Allow",
            Action: ["dynamodb:*"],
            Resource: "arn:aws:dynamodb:*:*:table/ServiceData*"
          }
        ]
      }
    }
  })
end
```

## Computed Properties Usage

```ruby
identity_pool = aws_cognito_identity_pool(:dynamic_pool, pool_config)

# Conditional resource creation based on authentication methods
if identity_pool.computed_properties[:uses_cognito_user_pools]
  # Create User Pool specific monitoring
  cognito_pool_monitoring_resources(identity_pool)
end

if identity_pool.computed_properties[:uses_social_providers]
  # Create social provider analytics
  social_analytics_resources(identity_pool)
  
  # Social provider specific configurations
  identity_pool.computed_properties[:social_providers].each do |provider|
    case provider
    when :google
      google_specific_configuration(identity_pool)
    when :facebook
      facebook_specific_configuration(identity_pool)
    when :amazon
      amazon_specific_configuration(identity_pool)
    end
  end
end

# Security-based conditional logic
case identity_pool.computed_properties[:security_level]
when :low
  # Basic monitoring for low security pools
  basic_monitoring_resources(identity_pool)
when :medium, :medium_high
  # Enhanced monitoring and alerting
  enhanced_monitoring_resources(identity_pool)
when :high
  # Comprehensive security monitoring and compliance logging
  enterprise_security_monitoring(identity_pool)
end

# Create appropriate IAM roles based on authentication methods
auth_methods = identity_pool.computed_properties[:authentication_methods]
if auth_methods.include?(:unauthenticated)
  guest_user_role = create_guest_role(identity_pool)
end

if auth_methods.include?(:cognito_user_pools)
  user_pool_authenticated_role = create_user_pool_role(identity_pool)
end

if auth_methods.include?(:social_providers)
  social_authenticated_role = create_social_role(identity_pool)
end

if auth_methods.include?(:saml_providers) || auth_methods.include?(:oidc_providers)
  enterprise_role = create_enterprise_role(identity_pool)
end
```

## Advanced Security Patterns

### Zero Trust Identity Pool Architecture
```ruby
template :zero_trust_identity do
  # Maximum security identity pool
  secure_identity_pool = aws_cognito_identity_pool(:secure_identity_pool, {
    identity_pool_name: "ZeroTrustIdentityPool",
    allow_unauthenticated_identities: false,  # No anonymous access
    allow_classic_flow: false,                # Disable legacy flow
    
    # Only trusted authentication methods
    cognito_identity_providers: [{
      client_id: mfa_required_client.id,
      provider_name: mfa_user_pool.endpoint,
      server_side_token_check: true  # Always verify tokens server-side
    }],
    
    # Enterprise-grade SAML only
    saml_provider_arns: [enterprise_saml_provider.arn],
    
    tags: {
      SecurityLevel: "maximum",
      Compliance: "required",
      Environment: "production"
    }
  })
  
  # Restrictive IAM role with comprehensive conditions
  zero_trust_role = aws_iam_role(:zero_trust_role, {
    assume_role_policy: {
      Version: "2012-10-17",
      Statement: [{
        Effect: "Allow",
        Principal: { Federated: "cognito-identity.amazonaws.com" },
        Action: "sts:AssumeRoleWithWebIdentity",
        Condition: {
          StringEquals: {
            "cognito-identity.amazonaws.com:aud" => secure_identity_pool.id
          },
          "ForAnyValue:StringLike": {
            "cognito-identity.amazonaws.com:amr" => "authenticated"
          },
          # Additional security conditions
          DateGreaterThan: {
            "aws:TokenIssueTime" => "${aws:RequestTime - 3600}"  # Token must be recent
          },
          IpAddress: {
            "aws:SourceIp" => corporate_ip_ranges  # Restrict by IP
          }
        }
      }]
    },
    inline_policies: {
      ZeroTrustAccess: {
        Version: "2012-10-17",
        Statement: [
          # Minimum viable permissions with extensive conditions
          {
            Effect: "Allow",
            Action: ["s3:GetObject"],
            Resource: "arn:aws:s3:::secure-bucket/${cognito-identity.amazonaws.com:sub}/*",
            Condition: {
              StringEquals: {
                "s3:x-amz-server-side-encryption" => "AES256"
              },
              DateLessThan: {
                "aws:TokenIssueTime" => "${aws:RequestTime + 900}"  # 15-minute token window
              }
            }
          }
        ]
      }
    }
  })
end
```

## Error Handling and Operational Excellence

### Comprehensive Error Handling
```ruby
# Identity pool configuration validation
begin
  enterprise_identity_pool = CognitoIdentityPoolAttributes.new({
    identity_pool_name: "EnterprisePool",
    allow_unauthenticated_identities: false,
    supported_login_providers: {
      "accounts.google.com" => "invalid-google-client-id"
    }
  })
rescue Dry::Struct::Error => e
  handle_configuration_error(e)
  # Log error, notify operators, use fallback configuration
end

# Runtime identity pool health monitoring
template :identity_pool_monitoring do
  identity_pool = aws_cognito_identity_pool(:monitored_pool, pool_config)
  
  # CloudWatch custom metrics for identity pool operations
  aws_cloudwatch_metric_alarm(:identity_pool_errors, {
    alarm_name: "IdentityPool-HighErrorRate",
    alarm_description: "High error rate in Cognito Identity Pool",
    metric_name: "Errors",
    namespace: "AWS/CognitoIdentity",
    statistic: "Sum",
    period: 300,
    evaluation_periods: 2,
    threshold: 10,
    comparison_operator: "GreaterThanThreshold",
    dimensions: {
      IdentityPoolId: identity_pool.id
    },
    alarm_actions: [sns_alert_topic.arn]
  })
  
  # Monitor successful authentications
  aws_cloudwatch_metric_alarm(:identity_pool_auth_success, {
    alarm_name: "IdentityPool-LowAuthSuccess",
    alarm_description: "Low authentication success rate",
    metric_name: "SuccessfulRequestCount",
    namespace: "AWS/CognitoIdentity",
    statistic: "Sum", 
    period: 900,
    evaluation_periods: 1,
    threshold: 5,
    comparison_operator: "LessThanThreshold",
    dimensions: {
      IdentityPoolId: identity_pool.id
    },
    treat_missing_data: "breaching"
  })
end
```

## Performance and Scalability Considerations

1. **Template-Level State Isolation**: Each identity pool template creates separate Terraform state
2. **Provider Limits**: Identity pools support specific limits per provider type
3. **Token Caching**: Implement proper token caching strategies in applications
4. **Role Session Duration**: Balance security vs. user experience with session duration
5. **Cross-Region Considerations**: Identity pools are regional resources
6. **Monitoring Overhead**: Comprehensive monitoring can incur CloudWatch costs
7. **IAM Policy Complexity**: Complex role mappings can affect performance
8. **Multi-Pool Strategy**: Consider separate pools for different application components

This implementation provides enterprise-grade federated identity management with complete type safety, comprehensive validation, and flexible architectural patterns for any authentication and authorization scenario.