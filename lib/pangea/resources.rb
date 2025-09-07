# frozen_string_literal: true

require 'pangea/resources/types'
require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/aws'
require 'pangea/resources/composition'

module Pangea
  # Resource abstraction system with type-safe functions and return values
  module Resources
    # Auto-include AWS resources and composition helpers in template contexts
    def self.included(base)
      base.include AWS
      base.include Composition
    end
  end
end