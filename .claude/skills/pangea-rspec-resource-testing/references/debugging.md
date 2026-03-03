# Debugging Test Failures

## Step 1: Inspect Actual Terraform Output

```ruby
# Add this to see what terraform-synthesizer actually produces:
result = synthesizer.synthesis
puts JSON.pretty_generate(result)

# Look at the actual structure:
# {
#   "resource": {
#     "cloudflare_record": {
#       "www": {
#         "zone_id": "...",
#         "proxied": false,  # <- Aha! This shouldn't be here
#         ...
#       }
#     }
#   }
# }
```

## Step 2: Check Resource Implementation

When test fails, check resource.rb for how fields are synthesized:
```ruby
# Look for conditional logic:
resource(:cloudflare_record, name) do
  zone_id record_attrs.zone_id
  proxied record_attrs.proxied if record_attrs.proxied  # <- Conditional!
end
```

## Step 3: Check Type Definitions

When validation fails, check types.rb:
```ruby
# Check attribute definition:
attribute :tags, ::Pangea::Resources::Types::CloudflareTags

# Check type definition:
CloudflareTags = Hash.map(String, String)  # <- Expects string keys!
```

## Step 4: Use Selective Test Execution

For troubleshooting specific resources without running all tests:

**Create synthesizer-tests.yaml**:
```yaml
mode: enabled_only
enabled_tests:
  - cloudflare_zone/synthesis_spec.rb
  - cloudflare_record/synthesis_spec.rb
```

**Run focused tests**:
```bash
nix run .#synthesizer-tests  # Respects YAML config
```

This is much faster than running all 200+ synthesis tests!
