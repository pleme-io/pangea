# Pangea Workflow Examples

## Development Workflow

```bash
# 1. Create/edit template
vim infrastructure/pangea/{product}/{product}_dns.rb

# 2. Test with local state
pangea plan {product}_dns.rb --namespace development

# 3. Apply to development
pangea apply {product}_dns.rb --namespace development

# 4. Verify resources
aws route53 list-hosted-zones
```

## Production Deployment

```bash
# 1. Plan against production
pangea plan {product}_dns.rb --namespace production

# 2. Review plan output carefully

# 3. Apply layer by layer
pangea apply {product}_dns.rb --template route53_zones
pangea apply {product}_dns.rb --template dns_records

# 4. Validate
dig +short {product}.com
```

## Incremental Updates

```bash
# Update single template
vim infrastructure/pangea/{product}/{product}_dns.rb

# Plan only changed template
pangea plan {product}_dns.rb --template dns_records

# Apply only changed template
pangea apply {product}_dns.rb --template dns_records
```

## Nix Run Workflow (Preferred)

```bash
# Apply using nix run handle (PREFERRED)
nix run .#apply-novaskyn-staging-dns

# Apply other products/environments
nix run .#apply-{product}-{environment}-dns
nix run .#apply-{product}-{environment}-networking
```

**Creating New Handles:**
- Add to `flake.nix` when needed
- Pattern: `apply-{product}-{environment}-{template-type}`
- Provides consistent, documented deployment workflow

## Migration from Terraform

**Pattern:** Coexist with existing Terraform, gradually migrate.

**Steps:**
1. Deploy Pangea infrastructure alongside Terraform (different state keys)
2. Import existing resources into Pangea templates (optional)
3. Validate Pangea resources match existing infrastructure
4. Switch DNS/traffic to Pangea-managed resources
5. Decomission old Terraform deployments

**Benefit:** Same S3 backend, different state keys - no conflicts.

## State Management Workflow

### Check State Location
```bash
# Local workspaces
ls ~/.pangea/workspaces/production/dns_records/

# S3 state
aws s3 ls s3://{bucket}/pangea/production/dns_records/
```

### State File Organization
```
s3://{bucket}/pangea/{namespace}/{template_name}/terraform.tfstate
```

### Example State Paths
```
s3://nxs-nova-tfstate-use1/pangea/production/route53_zones/terraform.tfstate
s3://nxs-nova-tfstate-use1/pangea/production/dns_records/terraform.tfstate
s3://nxs-nova-tfstate-use1/pangea/staging/dns_records/terraform.tfstate
```
