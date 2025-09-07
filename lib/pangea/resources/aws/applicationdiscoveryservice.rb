# frozen_string_literal: true

require 'pangea/resources/aws/applicationdiscoveryservice/application'

module Pangea
  module Resources
    module AWS
      # AWS Application Discovery Service resources module
      # Includes all Application Discovery Service resource implementations for
      # managing applications and migration tracking.
      module ApplicationDiscoveryService
        include Application
      end
    end
  end
end