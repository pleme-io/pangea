# Resource File Templates

Complete templates for the three required files per cloud provider resource.

## File 1: types.rb (Resource Attributes)

**Location**: `lib/pangea/resources/{resource_name}/types.rb`

```ruby
# frozen_string_literal: true
# Copyright 2025 The Pangea Authors

require 'dry-struct'
require 'pangea/resources/types'

module Pangea
  module Resources
    module Provider  # e.g., Hetzner, Cloudflare, Aws
      module Types
        # Resource Name attributes (e.g., ServerAttributes, ZoneAttributes)
        class ResourceNameAttributes < Dry::Struct
          transform_keys(&:to_sym)

          # Required attributes (no default, no optional)
          attribute :name, Resources::Types::String
          attribute :required_field, ProviderSpecificType

          # Optional attributes with defaults
          attribute :optional_with_default, Resources::Types::Bool.default(false)
          attribute :ttl, Resources::Types::Integer.default(3600)

          # Optional attributes without defaults (use .optional.default(nil))
          attribute :description, Resources::Types::String.optional.default(nil)
          attribute :tags, ProviderLabels.default({}.freeze)

          # Array attributes
          attribute :items, Resources::Types::Array.of(Resources::Types::String).default([].freeze)

          # Nested attributes
          attribute :config, Resources::Types::Hash.schema(
            field1: Resources::Types::String,
            field2?: Resources::Types::Integer.optional
          ).optional.default(nil)

          # Computed properties (methods, not attributes)
          def is_enabled?
            enabled == true
          end

          def formatted_name
            "prefix-#{name}-suffix"
          end
        end
      end
    end
  end
end
```

**Key Rules**:
- `transform_keys(&:to_sym)` - REQUIRED for symbol keys
- Required: `attribute :name, Type` (no default)
- Optional with default: `attribute :name, Type.default(value)`
- Optional without default: `attribute :name, Type.optional.default(nil)`
- Arrays: Use `.default([].freeze)` to prevent mutation
- Hashes: Use `.default({}.freeze)` to prevent mutation
- Computed: Define methods, not attributes

## File 2: resource.rb (terraform-synthesizer Integration)

**Location**: `lib/pangea/resources/{resource_name}/resource.rb`

```ruby
# frozen_string_literal: true
# Copyright 2025 The Pangea Authors

require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/{resource_name}/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module ResourceModule  # e.g., HcloudServer, CloudflareZone
      # Resource function (e.g., hcloud_server, cloudflare_zone)
      def resource_function(name, attributes = {})
        # 1. Validate attributes with Dry::Struct
        attrs = Provider::Types::ResourceNameAttributes.new(attributes)

        # 2. Generate Terraform resource using terraform-synthesizer
        resource(:terraform_resource_type, name) do
          # Required fields - always include
          name attrs.name
          required_field attrs.required_field

          # Optional fields - use conditionals
          description attrs.description if attrs.description
          optional_field attrs.optional_field if attrs.optional_field

          # Fields with defaults - always include
          enabled attrs.enabled
          ttl attrs.ttl

          # Arrays - conditionals or empty check
          items attrs.items unless attrs.items.empty?

          # Nested blocks - use if/unless
          if attrs.nested_config
            nested_block do
              field1 attrs.nested_config[:field1]
              field2 attrs.nested_config[:field2] if attrs.nested_config[:field2]
            end
          end

          # Array of nested blocks
          attrs.rules.each do |rule|
            rule_block do
              direction rule[:direction]
              protocol rule[:protocol]
              port rule[:port] if rule[:port]
            end
          end

          # Tags/Labels - always include even if empty
          labels attrs.labels
          tags attrs.tags
        end

        # 3. Return ResourceReference for interpolation
        ResourceReference.new(
          type: 'terraform_resource_type',
          name: name,
          resource_attributes: attrs.to_h,
          outputs: {
            id: "${terraform_resource_type.#{name}.id}",
            custom_output: "${terraform_resource_type.#{name}.custom_field}",
            computed: "${terraform_resource_type.#{name}.computed_value}"
          }
        )
      end
    end

    # Provider namespace (e.g., Hetzner, Cloudflare, Aws)
    module Provider
      include ResourceModule
    end
  end
end

# Auto-registration (REQUIRED)
Pangea::ResourceRegistry.register_module(Pangea::Resources::Provider)
```

**Key Patterns**:
- Function naming: `{provider}_{resource}` (e.g., `hcloud_server`, `cloudflare_zone`)
- Validate with Dry::Struct: `attrs = Types::...Attributes.new(attributes)`
- Use `resource(:type, name) do ... end` for terraform-synthesizer
- Conditionals: `field value if value` or `field value unless value.nil?`
- Arrays: `items.each do |item| ... end` for nested blocks
- ResourceReference: Return interpolation strings via `outputs` hash
- Auto-register: `Pangea::ResourceRegistry.register_module(...)`

## File 3: synthesis_spec.rb (RSpec Tests)

**Location**: `spec/resources/{resource_name}/synthesis_spec.rb`

```ruby
# frozen_string_literal: true
# Copyright 2025 The Pangea Authors

require 'spec_helper'
require 'terraform-synthesizer'
require 'pangea/resources/{resource_name}/resource'

RSpec.describe '{resource_name} synthesis' do
  include Pangea::Resources::Provider

  let(:synthesizer) { TerraformSynthesizer.new }

  it 'synthesizes basic resource with defaults' do
    synthesizer.instance_eval do
      extend Pangea::Resources::Provider
      resource_function(:test, {
        name: "test-resource",
        required_field: "value"
        # Omit optional fields to test defaults
      })
    end

    result = synthesizer.synthesis
    resource = result[:resource][:terraform_resource_type][:test]

    expect(resource[:name]).to eq("test-resource")
    expect(resource[:required_field]).to eq("value")
    expect(resource[:enabled]).to be true  # Default
    expect(resource[:ttl]).to eq(3600)     # Default
    expect(resource).not_to have_key(:description)  # Omitted
  end

  it 'synthesizes resource with all options' do
    synthesizer.instance_eval do
      extend Pangea::Resources::Provider
      resource_function(:full, {
        name: "full-resource",
        required_field: "value",
        description: "Test description",
        enabled: false,
        ttl: 7200,
        tags: { "env" => "production" }
      })
    end

    result = synthesizer.synthesis
    resource = result[:resource][:terraform_resource_type][:full]

    expect(resource[:name]).to eq("full-resource")
    expect(resource[:description]).to eq("Test description")
    expect(resource[:enabled]).to be false
    expect(resource[:ttl]).to eq(7200)
    expect(resource[:tags]).to eq({ "env" => "production" })
  end

  it 'synthesizes resource with nested blocks' do
    synthesizer.instance_eval do
      extend Pangea::Resources::Provider
      resource_function(:nested, {
        name: "nested-resource",
        rules: [
          { direction: "in", protocol: "tcp", port: "80" },
          { direction: "out", protocol: "udp" }
        ]
      })
    end

    result = synthesizer.synthesis
    resource = result[:resource][:terraform_resource_type][:nested]

    expect(resource[:rules]).to be_an(Array)
    expect(resource[:rules].length).to eq(2)
    expect(resource[:rules][0]).to include(direction: "in", protocol: "tcp", port: "80")
    expect(resource[:rules][1]).to include(direction: "out", protocol: "udp")
    expect(resource[:rules][1]).not_to have_key(:port)
  end

  it 'provides correct resource references' do
    ref = synthesizer.instance_eval do
      extend Pangea::Resources::Provider
      resource_function(:ref_test, {
        name: "reference-test",
        required_field: "value"
      })
    end

    expect(ref.id).to eq("${terraform_resource_type.ref_test.id}")
    expect(ref.outputs[:custom_output]).to eq("${terraform_resource_type.ref_test.custom_field}")
  end

  it 'enables resource composition' do
    synthesizer.instance_eval do
      extend Pangea::Resources::Provider

      parent = resource_function(:parent, {
        name: "parent-resource",
        required_field: "value"
      })

      dependent_resource(:child, {
        name: "child-resource",
        parent_id: parent.id  # Uses "${terraform_resource_type.parent.id}"
      })
    end

    result = synthesizer.synthesis
    child = result[:resource][:dependent_type][:child]

    expect(child[:parent_id]).to eq("${terraform_resource_type.parent.id}")
  end
end
```

**Test Coverage Requirements**:
- Basic resource with defaults
- Resource with all options
- Nested blocks/arrays
- Resource references (interpolation)
- Resource composition (parent-child)
- Verify defaults appear in Terraform
- Verify omitted fields don't appear
