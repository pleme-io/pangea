# Terraform Synthesis Tests Pattern

**Location**: `spec/resources/{resource_name}/synthesis_spec.rb`

**Purpose**: **CRITICAL** - Validate that resource functions generate correct Terraform JSON via terraform-synthesizer.

## Template

```ruby
# frozen_string_literal: true
# Copyright 2025 The Pangea Authors
# Licensed under the Apache License, Version 2.0

require 'spec_helper'
require 'terraform-synthesizer'
require 'pangea/resources/{resource_name}/resource'
require 'pangea/resources/{resource_name}/types'

RSpec.describe '{resource_name} synthesis' do
  include Pangea::Resources::{Provider}

  let(:synthesizer) { TerraformSynthesizer.new }

  describe 'terraform synthesis' do
    it 'synthesizes basic resource with defaults' do
      synthesizer.instance_eval do
        extend Pangea::Resources::{Provider}
        {resource_function}(:resource_name, {
          required_field: "value"
          # ... minimal required attributes
        })
      end

      result = synthesizer.synthesis
      resource = result[:resource][:{terraform_resource_type}][:resource_name]

      expect(resource).to include(
        required_field: "value",
        optional_field: "default_value"  # Verify defaults in Terraform
      )
      expect(resource).not_to have_key(:omitted_field)
    end

    it 'synthesizes resource with all options' do
      synthesizer.instance_eval do
        extend Pangea::Resources::{Provider}
        {resource_function}(:full_resource, {
          required_field: "value",
          optional_field: "custom",
          complex_field: { nested: "value" },
          tags: { Name: "test", Environment: "prod" }
        })
      end

      result = synthesizer.synthesis
      resource = result[:resource][:{terraform_resource_type}][:full_resource]

      expect(resource[:required_field]).to eq("value")
      expect(resource[:optional_field]).to eq("custom")
      expect(resource[:complex_field]).to include(nested: "value")
      expect(resource[:tags]).to include(Name: "test", Environment: "prod")
    end

    it 'synthesizes resource with nested blocks' do
      synthesizer.instance_eval do
        extend Pangea::Resources::{Provider}
        {resource_function}(:nested, {
          name: "test",
          nested_items: [
            { field1: "value1", field2: 100 },
            { field1: "value2", field2: 200 }
          ]
        })
      end

      result = synthesizer.synthesis
      resource = result[:resource][:{terraform_resource_type}][:nested]

      expect(resource[:nested_items]).to be_an(Array)
      expect(resource[:nested_items].length).to eq(2)
      expect(resource[:nested_items][0]).to include(field1: "value1", field2: 100)
    end

    it 'omits optional fields that are nil' do
      synthesizer.instance_eval do
        extend Pangea::Resources::{Provider}
        {resource_function}(:minimal, {
          required_field: "value"
          # No optional fields provided
        })
      end

      result = synthesizer.synthesis
      resource = result[:resource][:{terraform_resource_type}][:minimal]

      expect(resource).not_to have_key(:optional_field)
      expect(resource).not_to have_key(:another_optional)
    end
  end

  describe 'resource references' do
    it 'provides correct terraform interpolation strings' do
      ref = synthesizer.instance_eval do
        extend Pangea::Resources::{Provider}
        {resource_function}(:test, { required_field: "value" })
      end

      # Test output references
      expect(ref.id).to eq("${{{terraform_resource_type}}}.test.id}")
      expect(ref.outputs[:custom_output]).to eq("${{{terraform_resource_type}}}.test.custom_output}")
    end

    it 'enables resource composition with references' do
      ref1 = nil
      ref2 = nil

      synthesizer.instance_eval do
        extend Pangea::Resources::{Provider}

        ref1 = {resource_function}(:parent, { name: "parent" })
        ref2 = {dependent_resource}(:child, {
          name: "child",
          parent_id: ref1.id  # Use reference from parent
        })
      end

      result = synthesizer.synthesis

      parent = result[:resource][:{terraform_resource_type}][:parent]
      child = result[:resource][:{dependent_type}][:child]

      expect(parent).to be_present
      expect(child[:parent_id]).to eq("${{{terraform_resource_type}}}.parent.id}")
    end
  end

  describe 'resource composition' do
    it 'creates multiple related resources' do
      synthesizer.instance_eval do
        extend Pangea::Resources::{Provider}

        # Create parent resource
        parent = {resource_function}(:parent, { name: "parent" })

        # Create multiple children referencing parent
        {child_resource}(:child1, { parent_id: parent.id, name: "child1" })
        {child_resource}(:child2, { parent_id: parent.id, name: "child2" })
      end

      result = synthesizer.synthesis

      expect(result[:resource][:{terraform_resource_type}]).to have_key(:parent)
      expect(result[:resource][:{child_type}]).to have_key(:child1)
      expect(result[:resource][:{child_type}]).to have_key(:child2)
    end
  end
end
```

## Key Testing Scenarios

| Test Case | Purpose |
|-----------|---------|
| Basic with defaults | Verify minimal config with default values |
| All options | Verify every configurable field |
| Nested blocks | Verify arrays and complex structures |
| Optional field omission | Verify nil fields don't appear in output |
| Resource references | Verify `${type.name.attr}` interpolation |
| Resource composition | Verify parent-child relationships |
