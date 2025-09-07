# frozen_string_literal: true

require 'pangea/resources/base'

module Pangea
  module Resources
    module AWS
      # AWS AppStream Image Builder resource (stub - to be implemented)
      def aws_appstream_image_builder(name, attributes = {})
        # Stub implementation
        resource(:aws_appstream_image_builder, name) do
          # To be implemented
        end
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)