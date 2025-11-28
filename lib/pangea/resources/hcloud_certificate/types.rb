# frozen_string_literal: true
# Copyright 2025 The Pangea Authors

require 'dry-struct'
require 'pangea/resources/types'

module Pangea
  module Resources
    module Hetzner
      module Types
        # Hetzner Certificate attributes
        class CertificateAttributes < Dry::Struct
          transform_keys(&:to_sym)

          # Required attributes
          attribute :name, Resources::Types::String

          # Optional attributes (depends on type)
          attribute :certificate, Resources::Types::String.optional.default(nil)
          attribute :private_key, Resources::Types::String.optional.default(nil)
          attribute :labels, Resources::Types::HetznerLabels.default({}.freeze)
        end
      end
    end
  end
end
