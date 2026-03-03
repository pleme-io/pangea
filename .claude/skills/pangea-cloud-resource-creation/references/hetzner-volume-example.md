# Complete Example: Hetzner Volume

End-to-end implementation of `hcloud_volume` resource.

## 1. Type Definition in types.rb

```ruby
# lib/pangea/resources/types.rb (ADD at end before closing 'end')

# Hetzner volume filesystem formats
HetznerVolumeFormat = String.enum('xfs', 'ext4')

# Hetzner volume size validation (10-10000 GB)
HetznerVolumeSize = Integer.constrained(gteq: 10, lteq: 10000)
```

## 2. Resource Types

```ruby
# lib/pangea/resources/hcloud_volume/types.rb
# frozen_string_literal: true
# Copyright 2025 The Pangea Authors

require 'dry-struct'
require 'pangea/resources/types'

module Pangea
  module Resources
    module Hetzner
      module Types
        class VolumeAttributes < Dry::Struct
          transform_keys(&:to_sym)

          # Required
          attribute :name, Resources::Types::String
          attribute :size, HetznerVolumeSize

          # Optional
          attribute :location, HetznerLocation.optional.default(nil)
          attribute :format, HetznerVolumeFormat.optional.default(nil)
          attribute :labels, HetznerLabels.default({}.freeze)
        end
      end
    end
  end
end
```

## 3. Resource Function

```ruby
# lib/pangea/resources/hcloud_volume/resource.rb
# frozen_string_literal: true
# Copyright 2025 The Pangea Authors

require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/hcloud_volume/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module HcloudVolume
      def hcloud_volume(name, attributes = {})
        volume_attrs = Hetzner::Types::VolumeAttributes.new(attributes)

        resource(:hcloud_volume, name) do
          name volume_attrs.name
          size volume_attrs.size
          location volume_attrs.location if volume_attrs.location
          format volume_attrs.format if volume_attrs.format
          labels volume_attrs.labels
        end

        ResourceReference.new(
          type: 'hcloud_volume',
          name: name,
          resource_attributes: volume_attrs.to_h,
          outputs: {
            id: "${hcloud_volume.#{name}.id}",
            size: "${hcloud_volume.#{name}.size}",
            linux_device: "${hcloud_volume.#{name}.linux_device}"
          }
        )
      end
    end

    module Hetzner
      include HcloudVolume
    end
  end
end

Pangea::ResourceRegistry.register_module(Pangea::Resources::Hetzner)
```

## 4. Synthesis Spec

```ruby
# spec/resources/hcloud_volume/synthesis_spec.rb
# frozen_string_literal: true
# Copyright 2025 The Pangea Authors

require 'spec_helper'
require 'terraform-synthesizer'
require 'pangea/resources/hcloud_volume/resource'

RSpec.describe 'hcloud_volume synthesis' do
  include Pangea::Resources::Hetzner

  let(:synthesizer) { TerraformSynthesizer.new }

  it 'synthesizes volume' do
    synthesizer.instance_eval do
      extend Pangea::Resources::Hetzner
      hcloud_volume(:data, {
        name: "web-data",
        size: 100,
        location: "fsn1",
        format: "ext4"
      })
    end

    result = synthesizer.synthesis
    volume = result[:resource][:hcloud_volume][:data]

    expect(volume[:name]).to eq("web-data")
    expect(volume[:size]).to eq(100)
    expect(volume[:location]).to eq("fsn1")
    expect(volume[:format]).to eq("ext4")
  end
end
```
