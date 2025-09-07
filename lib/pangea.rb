# frozen_string_literal: true

require 'pangea/version'
require 'pangea/configuration'
require 'pangea/types'
require 'pangea/entities'
require 'pangea/utilities'

module Pangea
  class << self
    def configuration
      @configuration ||= Configuration.new
    end
    
    def config
      configuration
    end
    
    def configure
      yield(configuration) if block_given?
      configuration
    end
    
    # Add utilities access
    def utilities
      Utilities
    end
  end
end
