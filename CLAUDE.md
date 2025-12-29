# Pangea Arch

## Core Concept

Pangea is a scalable, automation-first infra management tool that addresses key Terraform/OpenTofu scalability challenges through:

- Template-level state isolation (more granular than industry standard directory-based approaches)
- Config-driven namespace management for multi-env backends
- Ruby DSL compilation to Terraform JSON for enhanced abstraction capabilities
- Automation-first design with auto-approval and automatic initialization
- Non-interactive operation designed explicitly for CI/CD and automation workflows

This approach enables infra management that scales with team size and complexity while reducing operational overhead. Unlike traditional Terraform approaches that rely on directory structures or monolithic state files, Pangea provides template-level granularity that matches how teams actually think about and manage infra components.

## Refactoring Guidelines

**Use `/pangea-refactoring` skill when refactoring code.**

### File Size Limits

- **Hard limit: 200 lines per file**
- Files exceeding this limit should be split using Extract Module or Extract Class patterns

### Refactoring Patterns

When splitting large files:

1. **Extract Module** - For components with multiple concerns, split into focused modules
2. **Extract Class** - When a class has multiple responsibilities, separate into single-responsibility classes
3. **Composition over Inheritance** - Use `attributes_from` with dry-struct for shared attributes

### dry-rb Best Practices

- Use `Dry::Struct.attributes_from` for shared attribute composition
- Define reusable type constraints in `lib/pangea/types/`
- Use inline nested structs for complex configurations
- Apply `transform_keys(&:to_sym)` consistently

### SOLID Principles

- **SRP**: Each file should have one reason to change
- **OCP**: Extend through composition, not modification
- **DIP**: Depend on abstractions (modules), not concrete implementations

### Priority Refactoring Targets

Files exceeding 200 lines should be refactored. Current high-priority targets:

| Category | Pattern |
|----------|---------|
| Components >1000 lines | Split into concern-based modules |
| Types >500 lines | Split into sub-type files |
| CLI commands >400 lines | Extract operation classes |

### Verification

After refactoring:
```bash
# Check file sizes
find lib -name "*.rb" -exec wc -l {} \; | sort -rn | head -20

# Run tests
bundle exec rspec

# Type check (optional)
bundle exec steep check
```

## Testing Guidelines

**Use `/pangea-resource-testing` skill when creating or testing resources.**

- Synthesis tests validate Terraform JSON output
- Each resource requires tests for: basic synthesis, optional attributes, defaults, tags, nested blocks
- Run tests with `nix run .#synthesizer-tests` or `bundle exec rspec`

## Skills Reference

| Skill | Use When |
|-------|----------|
| `/pangea-refactoring` | Splitting large files, extracting modules, reducing duplication, improving types |
| `/pangea-resource-testing` | Creating resources, writing synthesis tests, filling test coverage gaps |