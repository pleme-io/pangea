# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
        # Database parameter configuration
        class DbParameter < Dry::Struct
          attribute :name, Resources::Types::String
          attribute :value, Resources::Types::String | Types::Integer | Types::Float | Types::Bool
          attribute :apply_method, Resources::Types::String.enum('immediate', 'pending-reboot').default('pending-reboot')

          def self.new(attributes = {})
            attrs = super(attributes)

            if attrs.value.is_a?(TrueClass) || attrs.value.is_a?(FalseClass)
              attrs = attrs.copy(value: attrs.value ? '1' : '0')
            elsif attrs.value.is_a?(Numeric)
              attrs = attrs.copy(value: attrs.value.to_s)
            end

            attrs
          end

          def terraform_value = value.to_s
          def requires_immediate_application? = apply_method == 'immediate'
          def requires_reboot? = apply_method == 'pending-reboot'
        end
      end
    end
  end
end
