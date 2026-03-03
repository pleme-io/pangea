# Type Validation Tests Pattern

**Location**: `spec/resources/{provider}/types/{resource_name}_spec.rb`

**Purpose**: Test Dry::Struct attribute validation, defaults, and computed properties.

## Template

```ruby
# frozen_string_literal: true
# Copyright 2025 The Pangea Authors
# Licensed under the Apache License, Version 2.0

require_relative '../../../spec_helper'

RSpec.describe Pangea::Resources::{Provider}::Types::{ResourceName}Attributes do
  describe "type validation and creation" do
    it "creates valid resource with required attributes" do
      attrs = described_class.new(
        required_field: "value",
        # ... other required fields
      )

      expect(attrs.required_field).to eq("value")
      expect(attrs.optional_field).to eq("default_value")  # Test defaults
    end

    it "creates resource with all attributes" do
      attrs = described_class.new(
        required_field: "value",
        optional_field: "custom_value",
        # ... all fields
      )

      expect(attrs.optional_field).to eq("custom_value")
    end

    it "accepts all valid enum values" do
      %w[value1 value2 value3].each do |enum_value|
        attrs = described_class.new(
          required_field: "value",
          enum_field: enum_value
        )
        expect(attrs.enum_field).to eq(enum_value)
      end
    end

    it "rejects invalid values" do
      expect {
        described_class.new(required_field: "invalid!")
      }.to raise_error(Dry::Types::ConstraintError)
    end
  end

  describe "custom validation rules" do
    it "validates business logic constraints" do
      # Example: MX records require priority
      expect {
        described_class.new(type: "MX", value: "mail.example.com")
      }.to raise_error(Dry::Struct::Error, /require.*priority/)
    end
  end

  describe "computed properties" do
    it "provides computed attributes" do
      attrs = described_class.new(required_field: "value")

      expect(attrs.is_enabled?).to be true
      expect(attrs.computed_value).to eq("expected")
    end
  end

  describe "real-world usage scenarios" do
    it "supports typical production configuration" do
      production_attrs = described_class.new(
        # ... realistic production values
      )

      expect(production_attrs.is_valid?).to be true
    end
  end
end
```

## Key Principles

1. **Test required attributes** - Verify struct creation with minimal required fields
2. **Test defaults** - Ensure optional fields have correct default values
3. **Test all enum values** - Iterate through all valid enum options
4. **Test validation rules** - Verify invalid inputs are rejected
5. **Test computed properties** - Verify derived/calculated values
6. **Test real-world scenarios** - Include production-like configurations
