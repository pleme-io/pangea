# Pangea Backend Configuration Guide

## Overview

Pangea uses a `pangea.yml` configuration file to define namespaces and their backend configurations. When you run Pangea commands, it automatically initializes the backend infrastructure if needed.

## Configuration File Structure

The `pangea.yml` file has the following structure:

```yaml
# Default namespace used when --namespace is not specified
default_namespace: development

namespaces:
  # Each namespace defines a separate backend configuration
  namespace_name:
    description: "Description of this namespace"
    state:
      type: local|s3 # Backend type
      config: # Backend-specific configuration
        # Configuration fields depend on backend type
```

## Backend Types

### Local Backend

For development and testing, use local file storage:

```yaml
namespaces:
  development:
    description: "Local development environment"
    state:
      type: local
      config:
        path: "./terraform.tfstate" # Path to state file
```

### S3 Backend

For production environments, use S3 with DynamoDB for state locking:

```yaml
namespaces:
  production:
    description: "Production environment"
    state:
      type: s3
      config:
        bucket: "my-terraform-state" # S3 bucket name
        key: "pangea/prod/terraform.tfstate" # State file key
        region: "us-east-1" # AWS region
        dynamodb_table: "terraform-locks" # DynamoDB table for locking
        encrypt: true # Enable encryption
        kms_key_id: "arn:aws:kms:..." # Optional: KMS key for encryption
```

## Backend Initialization

When you run `pangea apply` or `pangea plan`, Pangea will:

1. **For Local Backend:**

   - Create the directory structure if it doesn't exist
   - Create lock files for state protection

2. **For S3 Backend:**
   - Create the S3 bucket if it doesn't exist
   - Enable versioning on the bucket for safety
   - Enable encryption if specified
   - Create the DynamoDB table for state locking if specified

## Example Configuration

Here's a complete example with multiple environments:

```yaml
default_namespace: development

namespaces:
  # Local development
  development:
    description: "Local development environment"
    state:
      type: local
      config:
        path: "./terraform.tfstate"
    tags:
      environment: development

  # Staging with S3
  staging:
    description: "Staging environment"
    state:
      type: s3
      config:
        bucket: "mycompany-terraform-state-staging"
        key: "pangea/staging/terraform.tfstate"
        region: "us-east-1"
        dynamodb_table: "terraform-state-lock-staging"
        encrypt: true
    tags:
      environment: staging

  # Production with enhanced security
  production:
    description: "Production environment"
    state:
      type: s3
      config:
        bucket: "mycompany-terraform-state-prod"
        key: "pangea/production/terraform.tfstate"
        region: "us-east-1"
        dynamodb_table: "terraform-state-lock-prod"
        encrypt: true
        kms_key_id: "arn:aws:kms:us-east-1:123456789012:key/..."
    tags:
      environment: production
```

## Usage

1. Create a `pangea.yml` file in your project root
2. Define your namespaces and backend configurations
3. Run Pangea commands:

```bash
# Use default namespace
pangea plan infrastructure.rb

# Use specific namespace
pangea apply infrastructure.rb --namespace production

# Target specific template
pangea apply infrastructure.rb --template web_server --namespace staging
```

## Template-Level State Isolation

Each template within a namespace gets its own state file:

- For S3: `s3://bucket/key/template_name/terraform.tfstate`
- For Local: `./path/template_name/terraform.tfstate`

This provides:

- Complete state isolation between templates
- Parallel development without conflicts
- Granular deployment and rollback capabilities
- Reduced blast radius for changes

## Best Practices

1. **Use local backend for development** - Fast iteration, no AWS costs
2. **Use S3 backend for shared environments** - Team collaboration, state locking
3. **Enable encryption for production** - Security compliance
4. **Use separate AWS accounts** - Security isolation between environments
5. **Set meaningful descriptions** - Help team members understand namespace purpose
6. **Use tags** - Track costs, ownership, and compliance

## Troubleshooting

### S3 Backend Issues

- Ensure AWS credentials are configured (`aws configure`)
- Verify the AWS account has permissions to create S3 buckets and DynamoDB tables
- Check the region is valid and accessible

### Local Backend Issues

- Ensure the path is writable
- Avoid using relative paths that might change based on working directory

### State Locking

- For S3: DynamoDB table is used for locking
- For Local: `.lock` files are created alongside state files
- If a lock is stuck, check for stale processes or failed runs

