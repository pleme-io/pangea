# frozen_string_literal: true

require 'pangea/resources/base'

module Pangea
  module Resources
    module AWS
      # AWS Directory Service Directory resource (stub - to be implemented)
      def aws_directory_service_directory(name, attributes = {})
        # Stub implementation
        resource(:aws_directory_service_directory, name) do
          # To be implemented
        end
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)