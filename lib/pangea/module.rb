require 'pangea/renderer'
require 'pangea/config'

module Pangea
  # Pangea::Module is a group of delcared render_component calls
  class Module
    attr_reader :name

    def initialize(name)
      @name = name
    end

    # def render(namespace, &block)
    #   Pangea::S3Renderer.new(namespace).render_component(name, &block)
    # end
  end
end
