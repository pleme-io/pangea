# AWS Cognito User Pool Client - Technical Implementation Guide

## Overview

The `aws_cognito_user_pool_client` resource provides type-safe creation and management of AWS Cognito User Pool Clients with comprehensive validation for OAuth 2.0 flows, authentication methods, and application integration patterns.

## Architecture Integration

### Multi-Client Authentication Architecture

```ruby
template :multi_client_auth do
  # Core user pool
  user_pool = aws_cognito_user_pool(:main_pool, 
    UserPoolTemplates.enterprise_security("MainPool")
  )
  
  # Web application client (confidential)
  web_client = aws_cognito_user_pool_client(:web_client, {
    name: "WebAppClient",
    user_pool_id: user_pool.id,
    generate_secret: true,
    allowed_oauth_flows: ["code"],
    allowed_oauth_flows_user_pool_client: true,
    allowed_oauth_scopes: ["email", "openid", "profile"],
    callback_urls: ["https://app.example.com/auth/callback"],
    logout_urls: ["https://app.example.com/auth/logout"],
    explicit_auth_flows: [
      "ALLOW_USER_SRP_AUTH",
      "ALLOW_REFRESH_TOKEN_AUTH"
    ],
    prevent_user_existence_errors: "ENABLED"
  })
  
  # Mobile application client (public) 
  mobile_client = aws_cognito_user_pool_client(:mobile_client, {
    name: "MobileAppClient",
    user_pool_id: user_pool.id,
    generate_secret: false,  # Public client
    explicit_auth_flows: [
      "ALLOW_USER_SRP_AUTH",
      "ALLOW_REFRESH_TOKEN_AUTH",
      "ALLOW_USER_PASSWORD_AUTH"  # Mobile convenience
    ],
    access_token_validity: 60,   # 1 hour
    id_token_validity: 60,       # 1 hour
    refresh_token_validity: 30,  # 30 days
    token_validity_units: {
      access_token: "minutes",
      id_token: "minutes",
      refresh_token: "days"
    },
    prevent_user_existence_errors: "ENABLED"
  })
  
  # Admin dashboard client (elevated permissions)
  admin_client = aws_cognito_user_pool_client(:admin_client, {
    name: "AdminDashboardClient",
    user_pool_id: user_pool.id,
    generate_secret: true,
    allowed_oauth_flows: ["code"],
    allowed_oauth_flows_user_pool_client: true,
    allowed_oauth_scopes: [
      "email", "openid", "profile", 
      "aws.cognito.signin.user.admin"
    ],
    callback_urls: ["https://admin.example.com/callback"],
    logout_urls: ["https://admin.example.com/logout"],
    explicit_auth_flows: [
      "ALLOW_USER_SRP_AUTH",
      "ALLOW_ADMIN_USER_PASSWORD_AUTH",
      "ALLOW_REFRESH_TOKEN_AUTH"
    ],
    # Admin attributes access
    read_attributes: [
      "email", "email_verified", "phone_number",
      "phone_number_verified", "name", "family_name", 
      "given_name", "custom:role", "custom:department"
    ],
    write_attributes: [
      "name", "family_name", "given_name", 
      "custom:role", "custom:department"
    ]
  })
end
```

### API-First Architecture with Multiple Clients

```ruby
template :api_first_architecture do
  # API user pool optimized for service access
  api_user_pool = aws_cognito_user_pool(:api_pool, {
    name: "APIUserPool",
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
  
  # Machine-to-machine client for service communication
  m2m_client = aws_cognito_user_pool_client(:m2m_client, {
    name: "ServiceClient",
    user_pool_id: api_user_pool.id,
    generate_secret: true,
    allowed_oauth_flows: ["client_credentials"],
    allowed_oauth_flows_user_pool_client: true,
    allowed_oauth_scopes: [
      "services/read", "services/write", "admin/users"
    ],
    supported_identity_providers: ["COGNITO"],
    access_token_validity: 24,    # 24 hours for service calls
    refresh_token_validity: 90,   # 90 days
    token_validity_units: {
      access_token: "hours",
      refresh_token: "days"
    }
  })
  
  # Frontend SPA client
  spa_client = aws_cognito_user_pool_client(:spa_client, {
    name: "SPAClient", 
    user_pool_id: api_user_pool.id,
    generate_secret: false,  # Public client with PKCE
    allowed_oauth_flows: ["code"],
    allowed_oauth_flows_user_pool_client: true,
    allowed_oauth_scopes: ["email", "openid", "profile", "api/read"],
    callback_urls: [
      "https://app.example.com/auth/callback",
      "http://localhost:3000/auth/callback"  # Development
    ],
    logout_urls: [
      "https://app.example.com/",
      "http://localhost:3000/"
    ],
    explicit_auth_flows: [
      "ALLOW_USER_SRP_AUTH",
      "ALLOW_REFRESH_TOKEN_AUTH"
    ],
    # Short-lived tokens for SPA security
    access_token_validity: 15,   # 15 minutes
    id_token_validity: 15,       # 15 minutes
    refresh_token_validity: 7,   # 7 days
    token_validity_units: {
      access_token: "minutes",
      id_token: "minutes", 
      refresh_token: "days"
    }
  })
  
  # Mobile API client
  mobile_api_client = aws_cognito_user_pool_client(:mobile_api_client, {
    name: "MobileAPIClient",
    user_pool_id: api_user_pool.id,
    generate_secret: false,
    explicit_auth_flows: [
      "ALLOW_USER_SRP_AUTH",
      "ALLOW_REFRESH_TOKEN_AUTH"
    ],
    # Mobile-optimized token validity
    access_token_validity: 60,   # 1 hour
    id_token_validity: 60,       # 1 hour  
    refresh_token_validity: 30,  # 30 days
    token_validity_units: {
      access_token: "minutes",
      id_token: "minutes",
      refresh_token: "days"
    },
    # Mobile-specific attributes
    read_attributes: [
      "email", "email_verified", "phone_number",
      "name", "picture", "custom:app_preferences"
    ],
    write_attributes: [
      "name", "picture", "custom:app_preferences"
    ]
  })
end
```

## Type-Safe Client Configuration

### OAuth Flow Validation
```ruby
# Compile-time and runtime validation
begin
  client_attrs = CognitoUserPoolClientAttributes.new({
    name: "TestClient",
    user_pool_id: "us-east-1_example",
    allowed_oauth_flows: ["code"],
    # This will raise an error - OAuth flows enabled but flag not set
    allowed_oauth_flows_user_pool_client: false
  })
rescue Dry::Struct::Error => e
  puts e.message  # "allowed_oauth_flows_user_pool_client must be true when allowed_oauth_flows is specified"
end

# Callback URL validation
begin
  client_attrs = CognitoUserPoolClientAttributes.new({
    name: "TestClient",
    user_pool_id: "us-east-1_example", 
    allowed_oauth_flows: ["implicit"],
    allowed_oauth_flows_user_pool_client: true
    # Missing callback_urls will raise error
  })
rescue Dry::Struct::Error => e
  puts e.message  # "callback_urls are required when using implicit OAuth flow"
end
```

### Token Validity Configuration
```ruby
# Type-safe token configuration with validation
token_config = CognitoUserPoolClientTokenValidityUnits.new({
  access_token: "minutes",
  id_token: "hours",
  refresh_token: "days"
})

client = aws_cognito_user_pool_client(:validated_client, {
  name: "ValidatedClient",
  user_pool_id: user_pool.id,
  access_token_validity: 30,      # 30 minutes
  id_token_validity: 2,           # 2 hours
  refresh_token_validity: 30,     # 30 days
  token_validity_units: token_config.to_h
})
```

## Advanced Security Patterns

### Zero Trust Client Configuration
```ruby
template :zero_trust_clients do
  # Maximum security user pool
  secure_pool = aws_cognito_user_pool(:secure_pool, {
    name: "ZeroTrustPool",
    username_attributes: ["email"],
    mfa_configuration: "ON",
    user_pool_add_ons: {
      advanced_security_mode: "ENFORCED"
    },
    device_configuration: {
      challenge_required_on_new_device: true,
      device_only_remembered_on_user_prompt: false
    }
  })
  
  # Ultra-secure client with minimal token validity
  secure_client = aws_cognito_user_pool_client(:secure_client, {
    name: "ZeroTrustClient",
    user_pool_id: secure_pool.id,
    generate_secret: true,
    allowed_oauth_flows: ["code"],
    allowed_oauth_flows_user_pool_client: true,
    allowed_oauth_scopes: ["openid", "email"],  # Minimal scopes
    callback_urls: ["https://secure.example.com/callback"],
    logout_urls: ["https://secure.example.com/logout"],
    explicit_auth_flows: [
      "ALLOW_USER_SRP_AUTH",      # Most secure auth method
      "ALLOW_REFRESH_TOKEN_AUTH"
    ],
    # Minimal token validity
    access_token_validity: 5,    # 5 minutes
    id_token_validity: 5,        # 5 minutes
    refresh_token_validity: 1,   # 1 day
    token_validity_units: {
      access_token: "minutes",
      id_token: "minutes",
      refresh_token: "days"
    },
    auth_session_validity: 3,    # 3 minutes auth session
    prevent_user_existence_errors: "ENABLED"
  })
end
```

### Development vs Production Client Patterns
```ruby
template :environment_specific_clients do
  user_pool = aws_cognito_user_pool(:app_pool, pool_config)
  
  # Conditional client creation based on environment
  if Rails.env.development?
    dev_client = aws_cognito_user_pool_client(:dev_client, 
      UserPoolClientTemplates.development_client("DevClient", user_pool.id)
    )
  else
    # Production clients with strict security
    web_client = aws_cognito_user_pool_client(:web_client, {
      name: "ProductionWebClient",
      user_pool_id: user_pool.id,
      generate_secret: true,
      allowed_oauth_flows: ["code"],
      allowed_oauth_flows_user_pool_client: true,
      allowed_oauth_scopes: ["email", "openid", "profile"],
      callback_urls: ["https://app.example.com/callback"],
      logout_urls: ["https://app.example.com/logout"],
      explicit_auth_flows: [
        "ALLOW_USER_SRP_AUTH",
        "ALLOW_REFRESH_TOKEN_AUTH"
      ],
      prevent_user_existence_errors: "ENABLED"
    })
    
    mobile_client = aws_cognito_user_pool_client(:mobile_client,
      UserPoolClientTemplates.mobile_app_client("ProductionMobileClient", user_pool.id)
    )
  end
end
```

## Analytics Integration

### Pinpoint Analytics Configuration
```ruby
template :analytics_enabled_clients do
  # Pinpoint application for analytics
  pinpoint_app = aws_pinpoint_app(:user_analytics, {
    name: "UserAnalytics"
  })
  
  # IAM role for Cognito to access Pinpoint
  analytics_role = aws_iam_role(:cognito_analytics_role, {
    assume_role_policy: {
      Version: "2012-10-17",
      Statement: [{
        Effect: "Allow",
        Principal: { Service: "cognito-idp.amazonaws.com" },
        Action: "sts:AssumeRole"
      }]
    },
    inline_policies: {
      PinpointAccess: {
        Version: "2012-10-17",
        Statement: [{
          Effect: "Allow",
          Action: [
            "mobiletargeting:PutEvents",
            "mobiletargeting:UpdateEndpoint"
          ],
          Resource: pinpoint_app.arn
        }]
      }
    }
  })
  
  # Client with analytics enabled
  analytics_client = aws_cognito_user_pool_client(:analytics_client, {
    name: "AnalyticsEnabledClient",
    user_pool_id: user_pool.id,
    generate_secret: false,
    allowed_oauth_flows: ["code"],
    allowed_oauth_flows_user_pool_client: true,
    allowed_oauth_scopes: ["email", "openid", "profile"],
    callback_urls: ["https://app.example.com/callback"],
    explicit_auth_flows: [
      "ALLOW_USER_SRP_AUTH",
      "ALLOW_REFRESH_TOKEN_AUTH"
    ],
    # Pinpoint analytics configuration
    analytics_configuration: {
      application_id: pinpoint_app.application_id,
      role_arn: analytics_role.arn,
      user_data_shared: true,
      external_id: "cognito-analytics-external"
    }
  })
end
```

## Cross-Resource Dependencies

### Client Secret Management
```ruby
template :secret_management do
  user_pool = aws_cognito_user_pool(:secure_pool, pool_config)
  
  # Confidential client with secret
  confidential_client = aws_cognito_user_pool_client(:confidential_client, {
    name: "ConfidentialClient",
    user_pool_id: user_pool.id,
    generate_secret: true,
    allowed_oauth_flows: ["code"],
    allowed_oauth_flows_user_pool_client: true,
    callback_urls: ["https://app.example.com/callback"]
  })
  
  # Store client secret in AWS Secrets Manager
  client_secret = aws_secretsmanager_secret(:client_secret, {
    name: "cognito/confidential-client/secret",
    description: "Cognito User Pool Client Secret"
  })
  
  client_secret_version = aws_secretsmanager_secret_version(:client_secret_version, {
    secret_id: client_secret.id,
    secret_string: confidential_client.outputs[:client_secret]
  })
  
  # IAM policy for applications to read the secret
  app_secret_policy = aws_iam_policy(:app_secret_policy, {
    name: "CognitoClientSecretAccess",
    policy: {
      Version: "2012-10-17",
      Statement: [{
        Effect: "Allow",
        Action: ["secretsmanager:GetSecretValue"],
        Resource: client_secret.arn
      }]
    }
  })
end
```

## Computed Properties Usage

```ruby
client = aws_cognito_user_pool_client(:dynamic_client, client_config)

# Conditional resource creation based on client type
if client.computed_properties[:confidential_client]
  # Store client secret securely
  secret_manager_resources(client)
end

if client.computed_properties[:oauth_enabled]
  # Create OAuth-specific resources (domain, etc.)
  oauth_configuration_resources(client)
end

# Different monitoring based on client type
case client.computed_properties[:client_type]
when :oauth_confidential
  # Enhanced monitoring for confidential OAuth clients
  enhanced_monitoring_resources(client)
when :oauth_public
  # Public client monitoring (PKCE validation, etc.)
  public_client_monitoring(client)  
when :native_public
  # Mobile app specific monitoring
  mobile_monitoring_resources(client)
end

# Conditional analytics setup
if client.computed_properties[:analytics_enabled]
  # Additional analytics resources
  extended_analytics_configuration(client)
end
```

## Error Handling and Validation

### Custom Client Validation
```ruby
# Built-in validation catches common configuration errors:

# OAuth flow configuration errors
begin
  invalid_client = CognitoUserPoolClientAttributes.new({
    name: "InvalidClient",
    user_pool_id: "us-east-1_example",
    allowed_oauth_flows: ["code"],
    allowed_oauth_flows_user_pool_client: false
  })
rescue Dry::Struct::Error => e
  puts "OAuth Configuration Error: #{e.message}"
end

# Callback URL validation errors  
begin
  invalid_client = CognitoUserPoolClientAttributes.new({
    name: "InvalidClient", 
    user_pool_id: "us-east-1_example",
    default_redirect_uri: "https://not-in-callbacks.com",
    callback_urls: ["https://app.com/callback"]
  })
rescue Dry::Struct::Error => e
  puts "Callback URL Error: #{e.message}"
end

# Token validity range errors
begin
  invalid_client = CognitoUserPoolClientAttributes.new({
    name: "InvalidClient",
    user_pool_id: "us-east-1_example", 
    access_token_validity: 1  # Below minimum of 5 minutes
  })
rescue Dry::Struct::Error => e
  puts "Token Validity Error: #{e.message}"
end
```

## Performance and Scalability Considerations

1. **Template-Level Isolation**: Each client template creates separate Terraform state
2. **Client Limits**: User pools support up to 1000 clients per pool
3. **Token Management**: Balance security vs. user experience with token validity
4. **OAuth Scopes**: Minimize scopes to reduce token size and improve performance
5. **Analytics Overhead**: Monitor Pinpoint costs when analytics are enabled
6. **Secret Rotation**: Implement regular client secret rotation for confidential clients
7. **Cache Considerations**: Short-lived tokens require more frequent refresh
8. **Multi-Region**: Create separate clients per region for geo-distributed applications

## Testing Strategies

### Development Client Template
```ruby
# Development client with relaxed security for testing
dev_client = aws_cognito_user_pool_client(:test_client, {
  name: "TestClient",
  user_pool_id: user_pool.id,
  generate_secret: false,
  allowed_oauth_flows: ["code", "implicit"],
  allowed_oauth_flows_user_pool_client: true,
  allowed_oauth_scopes: ["email", "openid", "profile", "aws.cognito.signin.user.admin"],
  callback_urls: [
    "http://localhost:3000/callback",
    "http://localhost:8080/callback", 
    "https://oauth.pstmn.io/v1/callback"  # Postman testing
  ],
  logout_urls: [
    "http://localhost:3000/",
    "http://localhost:8080/"
  ],
  explicit_auth_flows: [
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_ADMIN_USER_PASSWORD_AUTH",
    "ALLOW_CUSTOM_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH"
  ]
})
```

This implementation provides comprehensive, type-safe client management with flexible architectural patterns for any OAuth 2.0 and authentication scenario.