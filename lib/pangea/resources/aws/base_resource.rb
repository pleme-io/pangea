# frozen_string_literal: true

require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      # Base functionality for AWS resources
      module BaseResource
        def self.included(base)
          base.extend(ClassMethods)
        end

        module ClassMethods
          def new(name:, synthesizer:, attributes:)
            instance = allocate
            instance.instance_variable_set(:@name, name)
            instance.instance_variable_set(:@synthesizer, synthesizer)
            instance.instance_variable_set(:@attributes, attributes)
            instance
          end
        end

        attr_reader :name, :synthesizer, :attributes

        def synthesize
          synthesis
        end

        def reference
          reference_class.new(
            type: resource_type.to_s,
            name: name,
            synthesizer: synthesizer
          )
        end

        # Subclasses must implement these methods
        def resource_type
          raise NotImplementedError, "Subclasses must define resource_type"
        end

        def synthesis
          raise NotImplementedError, "Subclasses must define synthesis"
        end

        def reference_class
          raise NotImplementedError, "Subclasses must define reference_class"
        end
      end

      # Base attributes class for all AWS resources
      class BaseAttributes < Dry::Struct
        # Common AWS resource attributes can go here
        transform_keys(&:to_sym)
      end

      # Base reference class for all AWS resources
      class Reference
        def initialize(type:, name:, synthesizer:)
          @type = type
          @name = name
          @synthesizer = synthesizer
        end

        attr_reader :type, :name, :synthesizer

        protected

        def output(attribute)
          "${#{type}.#{name}.#{attribute}}"
        end
      end
    end
  end
end