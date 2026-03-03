---
name: pangea-cloud-resource-creation
description: Creates cloud provider resources for Pangea using Dry::Struct types, terraform-synthesizer integration, and RSpec tests. Use when adding support for new cloud providers (AWS, Hetzner, Cloudflare, GCP, Azure, DigitalOcean, etc.) to Pangea. Covers type definitions, resource functions, synthesis specs, tracker creation, and batch implementation patterns. Apply when implementing resources from provider documentation, adding new cloud integrations, or standardizing resource creation workflows.
metadata:
  version: "1.0.0"
  last_verified: "2025-12-27"
  research_version: "2025-12-27"
  domain_keywords:
    - "terraform"
    - "cloud-providers"
    - "infrastructure-as-code"
    - "resource-synthesis"
    - "ruby-infrastructure"
    - "dry-struct"
---

# Pangea Cloud Provider Resource Creation

## Overview

Standardized pattern for adding cloud provider resources to Pangea. Production-tested with Cloudflare (29 resources) and Hetzner Cloud (25 resources).

**Location**: `pkgs/tools/ruby/pangea/`

## Core Pattern

Each cloud provider resource requires **exactly three files**:

| File | Location | Purpose |
|------|----------|---------|
| `types.rb` | `lib/pangea/resources/{resource}/types.rb` | Dry::Struct attribute validation |
| `resource.rb` | `lib/pangea/resources/{resource}/resource.rb` | terraform-synthesizer + ResourceReference |
| `synthesis_spec.rb` | `spec/resources/{resource}/synthesis_spec.rb` | RSpec tests for Terraform JSON |

**Critical**: All three files must follow exact patterns. Deviations break synthesis or testing.

## File Structure

```
pkgs/tools/ruby/pangea/
├── lib/pangea/resources/
│   ├── types.rb                           # Central type definitions for ALL providers
│   ├── {resource_name}/
│   │   ├── types.rb                       # Resource-specific Dry::Struct
│   │   └── resource.rb                    # Resource function
├── spec/resources/
│   └── {resource_name}/
│       └── synthesis_spec.rb              # Synthesis tests
```

## Implementation Workflow

### Phase 1: Planning

1. **Research** - Review Terraform provider documentation
2. **Create Tracker** - `PROVIDER_IMPLEMENTATION.json` with batches
3. **Design Types** - Add provider types to central `types.rb`

### Phase 2: Resource Implementation

For each resource, create the three required files:

1. **types.rb** - Dry::Struct with `transform_keys(&:to_sym)`
2. **resource.rb** - Resource function with conditionals for optional fields
3. **synthesis_spec.rb** - Tests with `TerraformSynthesizer.new`

### Phase 3: Batch Execution

1. Implement all types first
2. Complete each batch (all 3 files per resource)
3. Update tracker: `bin/tracker update resource_name all`
4. Commit with batch completion message

## Quick Reference

### Attribute Patterns (types.rb)

| Pattern | Syntax |
|---------|--------|
| Required | `attribute :name, Type` |
| Optional with default | `attribute :name, Type.default(value)` |
| Optional no default | `attribute :name, Type.optional.default(nil)` |
| Arrays | `attribute :items, Array.of(Type).default([].freeze)` |
| Hashes | `attribute :labels, Hash.default({}.freeze)` |

### Resource Patterns (resource.rb)

| Pattern | Syntax |
|---------|--------|
| Required field | `field_name attrs.field` |
| Optional field | `field_name attrs.field if attrs.field` |
| Default field | `field_name attrs.field` (always include) |
| Nested block | `block_name do ... end` inside conditional |
| Array blocks | `attrs.items.each do \|item\| ... end` |

### Test Requirements (synthesis_spec.rb)

- Basic resource with defaults
- Resource with all options
- Nested blocks/arrays
- Resource references (interpolation)
- Resource composition (parent-child)

## Decision Table

| Scenario | Action |
|----------|--------|
| Add new cloud provider | Create tracker, implement all batches |
| Add single resource | Create 3 files, update tracker |
| Review implementation | Check against anti-patterns |
| Debug synthesis | Run individual spec, check conditionals |
| Type validation error | Check `transform_keys`, attribute syntax |

## Anti-Patterns (Quick Check)

| Issue | Fix |
|-------|-----|
| Missing `transform_keys(&:to_sym)` | Add to Dry::Struct class |
| Hardcoded values in resource | Use `attrs.field` |
| Optional without conditional | Add `if attrs.field` |
| Missing auto-registration | Add `ResourceRegistry.register_module(...)` |
| Tests without synthesizer | Use `TerraformSynthesizer.new` |

## Testing

```bash
cd pkgs/tools/ruby/pangea

# Single resource
rspec spec/resources/hcloud_volume/synthesis_spec.rb

# All provider resources
rspec spec/resources/hcloud_*
```

## When to Use This Skill

- Adding new cloud provider to Pangea
- Implementing resources from Terraform provider docs
- Creating resource tracker for new provider
- Reviewing resource implementation quality
- User asks: "add support for {cloud provider}"
- User asks: "implement {terraform resource}"

## Success Criteria

- 100% resource coverage for target provider
- All resources follow three-file pattern
- All tests use terraform-synthesizer
- ResourceReference enables composition
- Tracker shows 100% completion

## Detailed References

| Reference | Content |
|-----------|---------|
| [{baseDir}/references/resource-templates.md](references/resource-templates.md) | Full templates for types.rb, resource.rb, synthesis_spec.rb |
| [{baseDir}/references/type-system.md](references/type-system.md) | Type definitions, categories, tracker JSON template |
| [{baseDir}/references/hetzner-volume-example.md](references/hetzner-volume-example.md) | Complete end-to-end implementation example |
| [{baseDir}/references/tracker-cli.md](references/tracker-cli.md) | Tracker CLI script implementation |
| [{baseDir}/references/patterns-antipatterns.md](references/patterns-antipatterns.md) | Common patterns, anti-patterns, testing, git workflow |

## Related Resources

- **Hetzner Implementation**: 25 resources (100% complete)
- **Cloudflare Implementation**: 29 resources (100% complete)
- **Type System**: `lib/pangea/resources/types.rb`
- **Synthesizer**: `lib/terraform-synthesizer.rb`
- **Testing Skill**: `.claude/skills/pangea-rspec-resource-testing.md`
