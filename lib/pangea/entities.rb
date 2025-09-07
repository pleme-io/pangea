# frozen_string_literal: true

require 'pangea/types'
require 'pangea/entities/namespace'
require 'pangea/entities/project'
require 'pangea/entities/module_definition'
require 'pangea/entities/template'

module Pangea
  # Domain entities for Pangea
  module Entities
    # Custom error for validation failures
    class ValidationError < StandardError; end
  end
end