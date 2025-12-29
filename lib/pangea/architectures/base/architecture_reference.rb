# frozen_string_literal: true

require_relative 'architecture_reference/validation'
require_relative 'architecture_reference/cost'
require_relative 'architecture_reference/security'
require_relative 'architecture_reference/high_availability'
require_relative 'architecture_reference/performance'

module Pangea
  module Architectures
    module Base
      # Base class for architecture reference objects
      class ArchitectureReference
        include Validation
        include Cost
        include Security
        include HighAvailability
        include Performance

        attr_reader :type, :name, :architecture_attributes, :components, :resources, :outputs

        def initialize(type:, name:, architecture_attributes: {}, components: {}, resources: {}, outputs: {})
          @type = type
          @name = name
          @architecture_attributes = architecture_attributes
          @components = components
          @resources = resources
          @outputs = outputs
        end

        def method_missing(method_name, *args, &block)
          if outputs.key?(method_name)
            outputs[method_name]
          elsif components.key?(method_name)
            components[method_name]
          elsif resources.key?(method_name)
            resources[method_name]
          else
            super
          end
        end

        def respond_to_missing?(method_name, include_private = false)
          outputs.key?(method_name) || components.key?(method_name) || resources.key?(method_name) || super
        end

        def override(component_name, &block)
          raise ArgumentError, "Component #{component_name} does not exist" unless components.key?(component_name)

          @components[component_name] = yield(self)
          recalculate_outputs
          self
        end

        def extend_with(additional_resources)
          @resources.merge!(additional_resources)
          recalculate_outputs
          self
        end

        def compose_with(&block)
          yield(self)
          recalculate_outputs
          self
        end

        def all_resources
          component_resources = components.values.flat_map do |component|
            component.respond_to?(:resources) ? component.resources.values : [component]
          end
          (component_resources + resources.values).compact
        end

        def summary
          {
            name: name,
            type: type,
            architecture_attributes: architecture_attributes,
            component_count: components.size,
            resource_count: all_resources.size,
            estimated_monthly_cost: estimated_monthly_cost,
            security_compliance_score: security_compliance_score,
            high_availability_score: high_availability_score,
            performance_score: performance_score,
            validation_status: validate_deployment
          }
        end

        def to_configuration
          {
            architecture: { type: type, name: name, attributes: architecture_attributes },
            components: components.transform_values { |c| c.respond_to?(:to_configuration) ? c.to_configuration : c.to_h },
            resources: resources.transform_values { |r| r.respond_to?(:to_configuration) ? r.to_configuration : r.to_h },
            outputs: outputs
          }
        end

        private

        def recalculate_outputs
          @outputs[:estimated_monthly_cost] = cost_breakdown[:total]
          @outputs[:security_compliance_score] = security_compliance_score
          @outputs[:high_availability_score] = high_availability_score
          @outputs[:performance_score] = performance_score
        end
      end
    end
  end
end
