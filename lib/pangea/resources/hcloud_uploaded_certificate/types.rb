# frozen_string_literal: true
# Copyright 2025 The Pangea Authors

require 'dry-struct'
require 'pangea/resources/types'

module Pangea
  module Resources
    module Hetzner
      module Types
        # Hetzner Uploaded Certificate attributes
        class UploadedCertificateAttributes < Dry::Struct
          transform_keys(&:to_sym)

          # Required attributes
          attribute :name, Resources::Types::String
          attribute :certificate, Resources::Types::HetznerPemCertificate
          attribute :private_key, Resources::Types::HetznerPemPrivateKey

          # Optional attributes
          attribute :labels, Resources::Types::HetznerLabels.default({}.freeze)
        end
      end
    end
  end
end
