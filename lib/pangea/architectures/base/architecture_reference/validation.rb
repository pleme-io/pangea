# frozen_string_literal: true

module Pangea
  module Architectures
    module Base
      class ArchitectureReference
        # Validation methods
        module Validation
          def validate_deployment
            validations = []

            components.each do |name, component|
              validations << validate_component(name, component)
            end

            resources.each do |name, resource|
              validations << validate_resource_dependencies(name, resource)
            end

            validations.all?
          end

          private

          def validate_component(name, component)
            return true unless component.respond_to?(:validate)

            component.validate
          rescue StandardError => e
            warn "Component #{name} validation failed: #{e.message}"
            false
          end

          def validate_resource_dependencies(name, resource)
            return false if resource.nil?

            true
          rescue StandardError => e
            warn "Resource #{name} dependency validation failed: #{e.message}"
            false
          end
        end
      end
    end
  end
end
