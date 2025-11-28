# frozen_string_literal: true
# Copyright 2025 The Pangea Authors

require 'dry-struct'
require 'pangea/resources/types'

module Pangea
  module Resources
    module Hetzner
      module Types
        # Hetzner Volume Attachment attributes
        class VolumeAttachmentAttributes < Dry::Struct
          transform_keys(&:to_sym)

          # Required attributes
          attribute :volume_id, Resources::Types::String
          attribute :server_id, Resources::Types::String

          # Optional attributes
          attribute :automount, Resources::Types::Bool.default(false)
        end
      end
    end
  end
end
