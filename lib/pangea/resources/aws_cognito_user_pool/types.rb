# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

require 'pangea/resources/types'
require_relative 'types/nested_types'
require_relative 'types/attributes'
require_relative 'types/templates'

module Pangea
  module Resources
    module AWS
      module Types
        # Nested configuration types are defined in types/nested_types.rb
        # CognitoUserPoolAttributes is defined in types/attributes.rb
        # UserPoolTemplates is defined in types/templates.rb
      end
    end
  end
end
