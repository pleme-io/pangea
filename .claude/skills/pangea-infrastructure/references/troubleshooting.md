# Pangea Troubleshooting Guide

## Template Compilation Errors

```bash
# View compiled Terraform JSON
pangea plan {file}.rb --show-compiled

# Check for syntax errors in Ruby
ruby -c {file}.rb
```

**Common Issues:**
- Missing `end` blocks in Ruby DSL
- Incorrect resource type names
- Using HCL syntax instead of Ruby DSL

## State Lock Issues

```bash
# Check DynamoDB lock table
aws dynamodb scan --table-name {lock-table}

# Force unlock (last resort)
cd ~/.pangea/workspaces/{namespace}/{template}/
terraform force-unlock {lock-id}
```

**Prevention:**
- Never run concurrent applies on same template
- Use DynamoDB locking for all namespaces
- Check for stale locks after failed applies

## Cross-Template Reference Errors

```bash
# Verify remote state exists
aws s3 ls s3://{bucket}/pangea/{namespace}/{template}/

# Check output values
cd ~/.pangea/workspaces/{namespace}/{template}/
terraform output
```

**Common Causes:**
- Dependency template not applied yet
- Wrong state key in remote_state config
- Missing outputs in dependency template

## Provider Configuration Errors

```bash
# Verify AWS credentials
aws sts get-caller-identity

# Check region configuration
aws configure list
```

## Resource Already Exists

**Symptom:** `Error: creating X: EntityAlreadyExists`

**Solutions:**
1. Import existing resource: `terraform import {resource_type}.{name} {id}`
2. Delete existing resource manually (if safe)
3. Use different resource name

## State Drift Detection

```bash
# Refresh and compare
pangea plan {file}.rb --template {template}

# Force state refresh
cd ~/.pangea/workspaces/{namespace}/{template}/
terraform refresh
```

## Debugging Workflow

1. **Check compilation:** `pangea plan {file}.rb --show-compiled`
2. **Validate syntax:** `ruby -c {file}.rb`
3. **Check state:** `aws s3 ls s3://{bucket}/pangea/{namespace}/{template}/`
4. **Check locks:** `aws dynamodb scan --table-name {lock-table}`
5. **Check provider:** `aws sts get-caller-identity`
