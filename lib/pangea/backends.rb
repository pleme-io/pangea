# frozen_string_literal: true

require 'pangea/backends/base'
require 'pangea/backends/s3'
require 'pangea/backends/local'

module Pangea
  module Backends
    # Registry of available backends
    REGISTRY = {
      's3' => S3,
      'local' => Local
    }.freeze
    
    # Create a backend instance from configuration
    def self.create(type:, config: {})
      backend_class = REGISTRY[type.to_s]
      
      unless backend_class
        raise ArgumentError, "Unknown backend type: #{type}. Available: #{REGISTRY.keys.join(', ')}"
      end
      
      backend_class.new(config)
    end
    
    # Create backend from namespace entity
    def self.from_namespace(namespace)
      return nil unless namespace.state
      
      type = namespace.state[:type]
      config = namespace.state.dup
      config.delete(:type)
      
      create(type: type, config: config)
    end
  end
end