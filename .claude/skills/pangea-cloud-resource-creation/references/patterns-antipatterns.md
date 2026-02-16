# Patterns, Anti-Patterns, and Testing

## Common Patterns

### Nested Blocks

```ruby
# In resource.rb
if attrs.health_check
  health_check do
    protocol attrs.health_check[:protocol]
    port attrs.health_check[:port]
    interval attrs.health_check[:interval] if attrs.health_check[:interval]
  end
end
```

### Array of Nested Blocks

```ruby
# In resource.rb
attrs.rules.each do |rule|
  rule_block do
    direction rule[:direction]
    protocol rule[:protocol]
    port rule[:port] if rule[:port]
  end
end
```

### Conditional Optional Fields

```ruby
# In resource.rb
description attrs.description if attrs.description
location attrs.location if attrs.location

# DON'T: if attrs.optional_field.nil? ... (wrong)
# DO: if attrs.optional_field ... (correct)
```

### Computed Properties

```ruby
# In types.rb
class ServerAttributes < Dry::Struct
  attribute :server_type, HetznerServerType

  def is_arm?
    server_type.start_with?('cax')
  end

  def cpu_type
    is_arm? ? 'arm64' : 'x86_64'
  end
end

# In resource.rb
resource(:hcloud_server, name) do
  server_type attrs.server_type
  cpu_architecture attrs.cpu_type  # Use computed property
end
```

## Anti-Patterns

| Anti-Pattern | Problem | Fix |
|--------------|---------|-----|
| Missing `transform_keys` | Symbol/string key errors | Add `transform_keys(&:to_sym)` |
| Hardcoded values in resource | Values should come from attrs | Use `attrs.field` |
| No conditionals for optional | Includes nil in Terraform | `field attrs.val if attrs.val` |
| Missing auto-registration | Resource unavailable | Add `ResourceRegistry.register_module(...)` |
| Tests without synthesizer | Doesn't test Terraform generation | Use `TerraformSynthesizer.new` |

## Testing Strategy

### Run Commands

```bash
cd pkgs/tools/ruby/pangea

# Individual resource
rspec spec/resources/hcloud_volume/synthesis_spec.rb

# All provider resources
rspec spec/resources/hcloud_*
```

### Validate Types in IRB

```ruby
require 'pangea/resources/hcloud_volume/types'

# Valid input
attrs = Pangea::Resources::Hetzner::Types::VolumeAttributes.new(
  name: "test",
  size: 100,
  format: "ext4"
)

# Invalid input (should raise error)
attrs = Pangea::Resources::Hetzner::Types::VolumeAttributes.new(
  name: "test",
  size: 5  # Too small, should fail
)
```

## Git Commit Messages

```bash
# Type definitions
git commit -m "feat(pangea): add Hetzner Cloud type definitions (12 types)"

# Batch implementation
git commit -m "feat(pangea): complete Batch 1 - Core Infrastructure (5/5 resources)

Resources implemented:
- hcloud_ssh_key: SSH key management
- hcloud_network: Private VPC networks
- hcloud_firewall: Stateful firewalls
- hcloud_server: Virtual servers
- hcloud_network_subnet: Network subnets

All resources include:
- Dry::Struct type validation
- terraform-synthesizer integration
- RSpec synthesis tests
"

# Completion
git commit -m "docs(pangea): add Provider implementation completion report

100% coverage (XX/XX resources)
All batches complete
"
```

## Completion Checklist

Before marking a resource complete:

- [ ] Type definitions added to types.rb
- [ ] types.rb created with Dry::Struct
- [ ] resource.rb created with resource() function
- [ ] synthesis_spec.rb created with TerraformSynthesizer tests
- [ ] All tests pass
- [ ] Resource auto-registers via ResourceRegistry
- [ ] Tracker updated
- [ ] Committed with descriptive message
