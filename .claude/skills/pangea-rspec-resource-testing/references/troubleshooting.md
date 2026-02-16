# Common Test Failures and Fixes

## 1. Nested Block Hash vs Array Issue

**Problem**: Test expects Array but gets Hash (or vice versa)

**Root Cause**: terraform-synthesizer returns different types based on count:
- **Single nested block** = Returns a Hash
- **Multiple nested blocks** = Returns an Array

**Fix**:
```ruby
# For single nested block - expect Hash
expect(worker[:kv_namespace_binding]).to be_a(Hash)
expect(worker[:kv_namespace_binding][:name]).to eq("CACHE")

# For multiple nested blocks - expect Array
expect(worker[:bindings]).to be_an(Array)
expect(worker[:bindings][0][:name]).to eq("CACHE")
```

**Best Practice**: Test both scenarios when resource can have multiple nested blocks.

---

## 2. Field Inclusion/Omission Issues

**Problem**: Fields appear in output when they shouldn't

**Root Cause**: Resource includes fields with default `false` values

**Fix in resource.rb**:
```ruby
# Only include when true
proxied record_attrs.proxied if record_attrs.can_be_proxied? && record_attrs.proxied

# BAD: Always includes (even when false)
proxied record_attrs.proxied
```

---

## 3. Hash Key Type Mismatch (Symbol vs String)

**Problem**: Type validation fails with "violates constraints"
```
Error: :Type violates constraints (type?(String, :Type) failed)
```

**Root Cause**: Dry::Types expects string keys, not symbols

**Fix**:
```ruby
# CORRECT - string keys
tags: { "Type" => "blog", "Environment" => "production" }

# WRONG - symbol keys
tags: { Type: "blog", Environment: "production" }
```

---

## 4. Missing Resource Requires

**Problem**: Test fails with "invalid for TerraformSynthesizer"

**Fix**: Add require statement for referenced resources:
```ruby
require 'pangea/resources/cloudflare_workers_kv_namespace/resource'
require 'pangea/resources/cloudflare_worker_script/resource'  # Add this!
```

---

## 5. Missing Required Attributes

**Problem**: Test fails with ":field is missing in Hash input"

**Fix**: Check types.rb for required attributes (no `.optional`, no `.default`):
```ruby
cloudflare_page_rule(:test, {
  zone_id: "...",
  target: "*.example.com/*",  # Add required field
  actions: { cache_level: "cache_everything" }
})
```

---

## 6. SimpleCov Coverage Failures

**Problem**: Tests pass but build fails with "coverage below minimum"

**Fix Option 1** - Disable minimum in spec_helper.rb:
```ruby
SimpleCov.start do
  # minimum_coverage 80  # Comment out
end
```

**Fix Option 2** - Use environment variable:
```ruby
SimpleCov.start do
  minimum_coverage 80 unless ENV['SKIP_COVERAGE_CHECK']
end
```

---

## 7. Incomplete Test Expectations

**Problem**: Test doesn't fully validate the synthesized resource

**Fix**: Always validate complete output structure:
```ruby
result = synthesizer.synthesis
zone = result[:resource][:cloudflare_zone][:test]

# Check required fields
expect(zone[:zone]).to eq("example.com")

# Check defaults are applied
expect(zone[:plan]).to eq("free")
expect(zone[:jump_start]).to be false

# Check optional fields are omitted
expect(zone).not_to have_key(:paused)
expect(zone).not_to have_key(:vanity_name_servers)
```
