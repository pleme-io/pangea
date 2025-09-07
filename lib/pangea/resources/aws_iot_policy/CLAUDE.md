# AWS IoT Policy Resource - Claude Documentation

Provides type-safe IoT policy management with comprehensive security analysis, policy validation, and intelligent recommendations for device permission management.

## Security Analysis Features

- **Policy Statement Analysis**: Counts allow/deny statements and identifies security patterns
- **Wildcard Detection**: Identifies overly broad permissions using wildcards
- **Security Level Assessment**: Rates policies as high, medium, or low security
- **IoT Action Analysis**: Categorizes common IoT actions (connect, publish, subscribe, shadow, jobs)
- **Policy Recommendations**: Provides specific guidance for security improvements

## Enterprise Integration Patterns

### Principle of Least Privilege
```ruby
aws_iot_policy(:minimal_device_policy, {
  name: "MinimalDeviceAccess",
  policy: generate_minimal_policy({
    device_id: "${iot:Connection.Thing.ThingName}",
    allowed_topics: ["data", "status"],
    shadow_access: false
  })
})
```

This resource enables enterprise-grade IoT policy management with automated security analysis and compliance recommendations.