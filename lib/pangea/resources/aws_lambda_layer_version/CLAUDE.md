# AWS Lambda Layer Version Resource Implementation

## Overview

The `aws_lambda_layer_version` resource implements a type-safe wrapper around Terraform's AWS Lambda layer version resource, enabling code and dependency sharing across Lambda functions.

## Implementation Details

### Type System (types.rb)

The `LambdaLayerVersionAttributes` class enforces:

1. **Layer naming validation**: 1-140 characters, alphanumeric with hyphens and underscores
2. **Code source validation**: Either filename or S3, not both
3. **Architecture limits**: Maximum 2 architectures per layer
4. **Runtime compatibility**: Validates runtime support for architectures
5. **License info limits**: Maximum 512 characters

### Resource Synthesis (resource.rb)

The resource function:
1. Validates all inputs using dry-struct
2. Generates Terraform resource blocks for layers
3. Handles both local files and S3 sources
4. Returns ResourceReference with layer metadata

### Key Features

#### Layer Types
- **Runtime Dependencies**: Language-specific packages
- **AWS SDK**: Updated SDK versions
- **Data Science**: NumPy, Pandas, SciPy, etc.
- **Monitoring**: Observability tools
- **Custom Runtime**: Runtime implementations
- **Shared Resources**: Config files, certificates

#### Compatibility Controls
- **Runtime Specification**: Explicit runtime compatibility
- **Architecture Support**: x86_64 and/or arm64
- **Version Management**: Immutable versions

## Validation Rules

### Layer Name Format
```ruby
# Valid layer names
layer_name: "python-pandas-layer"
layer_name: "nodejs-utils-v2"
layer_name: "shared_config_2023"

# Invalid layer names
layer_name: "my.layer"  # No dots allowed
layer_name: "layer@latest"  # No @ symbol
layer_name: "very-long-name..." # Max 140 chars
```

### Runtime Architecture Compatibility

| Runtime | x86_64 | arm64 |
|---------|---------|--------|
| python3.11 | ✓ | ✓ |
| python3.8 | ✓ | ✓ |
| python3.7 | ✓ | ✗ |
| nodejs18.x | ✓ | ✓ |
| nodejs16.x | ✓ | ✓ |
| nodejs12.x | ✓ | ✗ |
| java17 | ✓ | ✓ |
| java11 | ✓ | ✓ |
| java8 | ✓ | ✗ |
| dotnet6 | ✓ | ✓ |
| go1.x | ✓ | ✗ |
| ruby3.2 | ✓ | ✓ |
| provided.al2 | ✓ | ✓ |

### Layer Size Limits
- **Compressed**: 50MB maximum
- **Uncompressed**: 250MB maximum
- **Total function size**: 250MB (including all layers)

## Common Patterns

### Dependency Layer Pattern
```ruby
aws_lambda_layer_version(:deps, {
  layer_name: "python-dependencies",
  filename: "layers/requirements.zip",
  compatible_runtimes: ["python3.11", "python3.10"],
  description: "Third-party Python packages"
})
```

### Multi-Architecture Pattern
```ruby
aws_lambda_layer_version(:universal, {
  layer_name: "cross-platform-utils",
  filename: "layers/utils.zip",
  compatible_runtimes: ["python3.11"],
  compatible_architectures: ["x86_64", "arm64"],
  description: "Works on both architectures"
})
```

### Versioned S3 Pattern
```ruby
aws_lambda_layer_version(:versioned, {
  layer_name: "ml-model-v2",
  s3_bucket: "models-bucket",
  s3_key: "layers/model-v2.3.0.zip",
  s3_object_version: "abc123xyz",
  compatible_runtimes: ["python3.11"],
  skip_destroy: true
})
```

### AWS SDK Update Pattern
```ruby
aws_lambda_layer_version(:sdk, {
  layer_name: "aws-sdk-latest",
  filename: "layers/aws-sdk.zip",
  compatible_runtimes: ["nodejs16.x", "nodejs18.x"],
  description: "Latest AWS SDK for Node.js"
})
```

## Layer Organization Strategies

### By Runtime
```
layers/
├── python/
│   ├── data-science/
│   ├── web-frameworks/
│   └── aws-integrations/
├── nodejs/
│   ├── express-deps/
│   └── aws-sdk/
└── java/
    └── common-libs/
```

### By Purpose
```
layers/
├── shared-dependencies/
├── monitoring-tools/
├── security-scanning/
└── ml-models/
```

### By Environment
```
layers/
├── development/
│   └── debug-tools/
├── staging/
│   └── test-utilities/
└── production/
    └── optimized-deps/
```

## Layer Content Structure

### Python Layer
```
python/
├── lib/
│   └── python3.11/
│       └── site-packages/
│           ├── pandas/
│           ├── numpy/
│           └── scipy/
└── bin/
    └── (executables)
```

### Node.js Layer
```
nodejs/
├── node_modules/
│   ├── express/
│   ├── axios/
│   └── lodash/
└── package.json
```

### Custom Runtime Layer
```
├── bootstrap
└── runtime/
    └── (runtime files)
```

## Integration with Functions

### Single Layer
```ruby
aws_lambda_function(:app, {
  runtime: "python3.11",
  handler: "app.handler",
  layers: [layer.arn]
})
```

### Multiple Layers
```ruby
aws_lambda_function(:app, {
  runtime: "python3.11",
  handler: "app.handler",
  layers: [
    dependencies_layer.arn,
    monitoring_layer.arn,
    config_layer.arn
  ]
})
```

### With AWS Layers
```ruby
aws_lambda_function(:app, {
  runtime: "python3.11",
  handler: "app.handler",
  layers: [
    custom_layer.arn,
    "arn:aws:lambda:${region}:580247275435:layer:LambdaInsightsExtension:21"
  ]
})
```

## Performance Considerations

### Layer Loading
- Layers are extracted to `/opt` in order
- Later layers can override earlier ones
- Keep frequently used files at top level

### Cold Start Impact
- More layers = slightly longer cold starts
- Large layers increase cold start time
- Use architecture-specific layers when possible

### Memory Usage
- Layers count toward function memory
- Uncompressed size matters at runtime
- Monitor function memory usage

## Security Best Practices

1. **Version Pinning**: Always use specific layer versions
2. **Source Validation**: Use source_code_hash for integrity
3. **Access Control**: Limit layer permissions
4. **License Compliance**: Document licenses properly
5. **Vulnerability Scanning**: Scan layer contents

## Cost Optimization

### Storage Costs
- S3 storage for layer archives
- No additional runtime costs
- Consider lifecycle policies for old versions

### Sharing Benefits
- Reduce individual function sizes
- Faster deployments
- Centralized dependency management

## Troubleshooting

### Common Issues

1. **Import Errors**: Check runtime path configuration
   ```ruby
   environment: {
     variables: {
       PYTHONPATH: "/opt/python",
       NODE_PATH: "/opt/nodejs/node_modules"
     }
   }
   ```

2. **Architecture Mismatch**: Ensure layer and function architectures match

3. **Size Limits**: Check total function + layers size

4. **Runtime Incompatibility**: Verify runtime versions

## Migration Guide

### From Inline Dependencies
```ruby
# Before: Each function includes dependencies
aws_lambda_function(:api, {
  filename: "api-with-deps.zip",  # 50MB
  runtime: "python3.11"
})

# After: Shared layer
layer = aws_lambda_layer_version(:deps, {
  layer_name: "shared-deps",
  filename: "deps-only.zip"  # 45MB
})

aws_lambda_function(:api, {
  filename: "api-code-only.zip",  # 5MB
  runtime: "python3.11",
  layers: [layer.arn]
})
```

### Version Upgrades
```ruby
# Create new version
v2_layer = aws_lambda_layer_version(:deps_v2, {
  layer_name: "dependencies-v2",
  filename: "deps-v2.zip",
  compatible_runtimes: ["python3.11"]
})

# Update functions gradually
aws_lambda_function(:api, {
  layers: [v2_layer.arn]  # Updated
})
```