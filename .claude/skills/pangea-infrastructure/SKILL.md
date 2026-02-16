---
name: pangea-infrastructure
description: Use when managing AWS infrastructure with Pangea. Automation-first infrastructure tool that compiles Ruby DSL to Terraform JSON with template-level state isolation. Covers Route53 DNS, CloudFront, ALB patterns, S3 backend management, cross-template dependencies, and workflow patterns for staging/production deployments. Apply these patterns when creating DNS records, setting up CloudFront distributions, configuring load balancers, managing S3 state backends, or troubleshooting Pangea infrastructure deployments.
metadata:
  version: "1.0.0"
  last_verified: "2025-12-27"
  research_version: "2025-12-27"
  domain_keywords:
    - "amazon-web-services"
    - "terraform"
    - "ruby-dsl"
    - "infrastructure-as-code"
    - "route53"
    - "amazon-s3-storage"
---

# Pangea Infrastructure Standards

## Quick Reference

| Task | Reference |
|------|-----------|
| Route53, CloudFront, ALB, Cloudflare Tunnel | [{baseDir}/references/resource-patterns.md](references/resource-patterns.md) |
| Troubleshooting & Debugging | [{baseDir}/references/troubleshooting.md](references/troubleshooting.md) |
| Workflow Examples | [{baseDir}/references/workflow-examples.md](references/workflow-examples.md) |
| Kubernetes Integration (cert-manager, IRSA) | [{baseDir}/references/kubernetes-integration.md](references/kubernetes-integration.md) |

## Pre-Development Checklist

**STOP. Verify before ANY Pangea changes:**

1. **Ruby DSL Syntax**: Using `template :name do` blocks (NOT raw Terraform HCL)
2. **Config Hash Pattern**: Centralized `config = {}` at top of each template
3. **Template Isolation**: Each template gets its own workspace and state file
4. **Pangea CLI Only**: Using `pangea plan/apply/destroy` (NOT terraform/tofu directly)
5. **Namespace Usage**: Testing in staging/development before production
6. **Remote State**: Cross-template dependencies use `terraform_remote_state`

**Research existing code in `infrastructure/pangea/{product}/` before creating new templates.**

## Core Concept

Pangea compiles **Ruby DSL to Terraform JSON** with **template-level state isolation**.

**Repository:** `pkgs/tools/ruby/pangea/`
**Product Infrastructure:** `infrastructure/pangea/{product}/`

**Key Advantages:**
- Template-Level State Isolation: Each `template :name` gets its own workspace
- Ruby DSL Power: Better abstraction than HCL for complex logic
- Automation-First: Auto-approval by default, no manual `terraform init`
- Multi-Template Files: Logical grouping while maintaining isolation

## Template Structure

```ruby
# infrastructure/pangea/{product}/{file}.rb

template :template_name do
  # Centralized configuration - ALL values here
  config = {
    region: "us-east-1",
    domain: "example.com",
    environment: "production",
    common_tags: { ManagedBy: "pangea", Environment: "production" }
  }

  provider :aws do
    region config[:region]
  end

  # Resources: resource :type, :name do...end
  resource :aws_route53_zone, :primary_zone do
    name config[:domain]
    tags config[:common_tags]
  end

  # Data sources: data :type, :name do...end
  data :aws_route53_zone, :existing do
    zone_id "Z01234567890"
  end
end
```

**Key Patterns:**
- Centralized `config` hash at top (NO hardcoded values in resources)
- Use `.to_json` for policy documents
- Use `send(:alias)` for Route53 alias blocks (Ruby reserved word)

## Pangea Configuration

**File:** `infrastructure/pangea/pangea.yml`

```yaml
default_namespace: production

namespaces:
  development:
    state:
      type: local
      path: "terraform.tfstate"

  staging:
    state:
      type: s3
      bucket: "nxs-{product}-tfstate-use1"
      key: "pangea/staging/terraform.tfstate"
      region: "us-east-1"
      dynamodb_table: "nxs-{product}-tflock-use1"
      encrypt: true

  production:
    state:
      type: s3
      bucket: "nxs-{product}-tfstate-use1"
      key: "pangea/production/terraform.tfstate"
      region: "us-east-1"
      dynamodb_table: "nxs-{product}-tflock-use1"
      encrypt: true
```

## Template-to-Workspace Mapping

Each `template :name` creates a separate workspace:

| Template | Workspace | State File |
|----------|-----------|------------|
| `:route53_zones` | `~/.pangea/workspaces/production/route53_zones/` | `s3://{bucket}/pangea/production/route53_zones/terraform.tfstate` |
| `:dns_records` | `~/.pangea/workspaces/production/dns_records/` | `s3://{bucket}/pangea/production/dns_records/terraform.tfstate` |

**Benefit:** Complete isolation prevents conflicts, reduces blast radius.

## Product Infrastructure Layout

**Directory:** `infrastructure/pangea/{product}/`

```
infrastructure/pangea/{product}/
├── {product}_networking.rb      # VPC, subnets, routing
├── {product}_dns.rb             # Route53 zones and records
├── {product}_staging_dns.rb     # Staging-specific DNS
├── {product}_security.rb        # Security groups, certificates
├── cert_manager_route53.rb      # cert-manager IAM (K8s TLS)
└── README.md
```

## CLI Commands

### Nix Run (Preferred)

```bash
# Apply using nix run handle
nix run .#apply-novaskyn-staging-dns
nix run .#apply-{product}-{environment}-{template-type}
```

If handle doesn't exist, create it in `flake.nix`.

### Direct Pangea CLI

```bash
cd infrastructure/pangea

# Plan
pangea plan {product}_dns.rb                           # All templates
pangea plan {product}_dns.rb --template dns_records    # Specific template
pangea plan {product}_dns.rb --namespace staging       # Specific namespace
pangea plan {product}_dns.rb --show-compiled           # Debug: show JSON

# Apply (auto-approves by default)
pangea apply {product}_dns.rb --template dns_records
pangea apply {product}_dns.rb --namespace production

# Destroy
pangea destroy {product}_dns.rb --template dns_records
```

### Status Checks

```bash
# View compiled Terraform
pangea plan {product}_dns.rb --show-compiled

# Check local workspace
ls ~/.pangea/workspaces/production/dns_records/

# Check S3 state
aws s3 ls s3://{bucket}/pangea/production/dns_records/
```

## Resource Naming

**Pattern:** `nxs-{product}-{env}-{resource-type}-{region}-{suffix}`

| Resource | Example |
|----------|---------|
| VPC | `nxs-nova-prod-vpc-use1` |
| ALB | `nxs-nova-prod-use1-api-lb-001` |
| S3 | `nxs-nova-prod-us-east-1-frontend-static-{hash}` |
| DynamoDB | `nxs-nova-prod-email-main` |

**Required Tags:**
```ruby
tags do
  Product "{product}"
  Environment "production|staging|development"
  ManagedBy "pangea"
  Component "{component-name}"
end
```

## Cross-Template Dependencies

Use `terraform_remote_state` data sources:

```ruby
template :security_layer do
  data :terraform_remote_state, :foundation do
    backend "s3"
    config do
      bucket "{bucket-name}"
      key "pangea/production/foundation_network/terraform.tfstate"
      region "us-east-1"
    end
  end

  resource :aws_security_group, :app do
    vpc_id "${data.terraform_remote_state.foundation.outputs.vpc_id}"
  end
end
```

## State Management

### S3 Backend Requirements

- S3 bucket with versioning enabled
- DynamoDB table for state locking
- IAM permissions for Terraform access

**Naming:**
- Bucket: `nxs-{product}-tfstate-{region}`
- Lock Table: `nxs-{product}-tflock-{region}`

### State Organization

```
s3://{bucket}/pangea/{namespace}/{template_name}/terraform.tfstate
```

## Anti-Patterns

| DO NOT | INSTEAD |
|--------|---------|
| Use Terraform/OpenTofu directly | Use Pangea CLI exclusively |
| Create monolithic templates | Split by logical layer |
| Hardcode values in resources | Use `config` hash at top |
| Skip namespaces | Use staging for testing |
| Manually edit state files | Use Pangea/Terraform commands |
| Cross-template refs without remote state | Use `terraform_remote_state` |
| Block syntax for arrays (`ingress_rule do`) | Parentheses syntax (`ingress([...])`) |

## AWS Zone ID Constants

| Resource | Zone ID |
|----------|---------|
| CloudFront | `Z2FDTNDATAQYW2` |
| US East 1 ALB | `Z35SXDOTRQ7X7K` |

## References

- Pangea tool: `pkgs/tools/ruby/pangea/`
- NovaSkyn example: `infrastructure/pangea/novaskyn/`
- Lilitu example: `infrastructure/pangea/lilutu/`
- Pangea README: `infrastructure/pangea/README.md`

### Detailed Reference Files

- **Resource Patterns:** [{baseDir}/references/resource-patterns.md](references/resource-patterns.md)
  - Cloudflare Zero Trust Tunnel configuration
  - Route53 DNS patterns (zones + records)
  - CloudFront/ALB alias records
  - Cross-template dependencies

- **Troubleshooting:** [{baseDir}/references/troubleshooting.md](references/troubleshooting.md)
  - Template compilation errors
  - State lock issues
  - Cross-template reference errors
  - Debugging workflow

- **Workflow Examples:** [{baseDir}/references/workflow-examples.md](references/workflow-examples.md)
  - Development workflow
  - Production deployment
  - Incremental updates
  - Terraform migration

- **Kubernetes Integration:** [{baseDir}/references/kubernetes-integration.md](references/kubernetes-integration.md)
  - cert-manager Route53 IAM
  - External DNS integration
  - IRSA patterns
