# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

require 'dry-struct'
require 'pangea/resources/types'
require 'json'

module Pangea
  module Resources
    module AWS
      module Types
        # AWS Step Functions State Machine attributes with validation
        class SfnStateMachineAttributes < Dry::Struct
          transform_keys(&:to_sym)

          # Core attributes
          attribute :name, Resources::Types::String
          attribute :definition, Resources::Types::String
          attribute :role_arn, Resources::Types::String

          # Optional attributes
          attribute :type, Resources::Types::String.optional.default("STANDARD")
          attribute? :logging_configuration, Resources::Types::Hash.optional
          attribute? :tracing_configuration, Resources::Types::Hash.optional
          attribute? :tags, Resources::Types::Hash.optional

          # Custom validation
          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}
            Validators.validate_type(attrs)
            Validators.validate_definition(attrs)
            Validators.validate_logging(attrs)
            Validators.validate_tracing(attrs)
            super(attrs)
          end

          # Computed properties
          def is_express_type? = type == "EXPRESS"
          def is_standard_type? = type == "STANDARD"
          def has_logging? = !logging_configuration.nil? && logging_configuration[:level] != "OFF"
          def has_tracing? = !tracing_configuration.nil? && tracing_configuration[:enabled] == true
          def parsed_definition = @parsed_definition ||= JSON.parse(definition)
          def start_state = parsed_definition["StartAt"]
          def states = parsed_definition["States"] || {}
          def state_count = states.size
        end
      end
    end
  end
end
