# Common Testing Patterns

## Testing Defaults

```ruby
it 'applies default values in terraform' do
  synthesizer.instance_eval do
    resource_function(:test, { required_only: "value" })
  end

  result = synthesizer.synthesis
  resource = result[:resource][:resource_type][:test]

  # Defaults should appear in Terraform
  expect(resource[:optional_field]).to eq("default_value")
  expect(resource[:enabled]).to be true
end
```

## Testing Conditional Fields

```ruby
it 'includes field only when provided' do
  synthesizer.instance_eval do
    # Without optional field
    resource_function(:minimal, { name: "test" })

    # With optional field
    resource_function(:full, {
      name: "test",
      optional: "value"
    })
  end

  result = synthesizer.synthesis

  minimal = result[:resource][:resource_type][:minimal]
  full = result[:resource][:resource_type][:full]

  expect(minimal).not_to have_key(:optional)
  expect(full[:optional]).to eq("value")
end
```

## Testing Arrays and Nested Structures

```ruby
it 'synthesizes arrays correctly' do
  synthesizer.instance_eval do
    resource_function(:test, {
      items: [
        { name: "item1", value: 100 },
        { name: "item2", value: 200 }
      ]
    })
  end

  result = synthesizer.synthesis
  resource = result[:resource][:resource_type][:test]

  expect(resource[:items]).to be_an(Array)
  expect(resource[:items].length).to eq(2)
  expect(resource[:items][0][:name]).to eq("item1")
end
```

## Testing Resource References

```ruby
synthesizer.instance_eval do
  zone = cloudflare_zone(:main, { zone: "example.com" })

  # Record should reference zone.id
  cloudflare_record(:www, {
    zone_id: zone.id,  # Uses "${cloudflare_zone.main.id}"
    name: "www",
    type: "A",
    value: "192.0.2.1"
  })
end

result = synthesizer.synthesis
record = result[:resource][:cloudflare_record][:www]

# Verify reference was used
expect(record[:zone_id]).to eq("${cloudflare_zone.main.id}")
```

## Testing Generated Structure

```ruby
result = synthesizer.synthesis

# Access resource like Terraform JSON: resource.type.name
resource = result[:resource][:cloudflare_record][:www]

# Test structure
expect(resource).to include(
  zone_id: expected_zone_id,
  name: "www",
  type: "A"
)

# Test defaults are applied
expect(resource[:ttl]).to eq(1)

# Test optional fields are omitted when nil
expect(resource).not_to have_key(:priority)
```
