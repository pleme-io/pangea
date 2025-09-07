# frozen_string_literal: true

module Pangea
  # Registry for auto-loading architecture modules into template synthesis
  #
  # Architectures self-register when required, making them available
  # in template contexts automatically without explicit includes.
  #
  # @example Architecture registration
  #   # In architecture file
  #   module WebApplicationArchitecture
  #     def web_application_architecture(name, attrs = {})
  #       # architecture implementation
  #     end
  #   end
  #   
  #   Pangea::ArchitectureRegistry.register_architecture(WebApplicationArchitecture)
  #
  # @example Usage in template
  #   require 'pangea/architectures/web_application_architecture/architecture'
  #   
  #   template :infrastructure do
  #     web_app = web_application_architecture(:myapp, { ... })  # Available automatically
  #   end
  module ArchitectureRegistry
    @architectures = []
    @mutex = Mutex.new

    class << self
      # Register an architecture module for auto-loading
      #
      # @param architecture_module [Module] The architecture module to register
      # @return [void]
      def register_architecture(architecture_module)
        @mutex.synchronize do
          unless @architectures.include?(architecture_module)
            @architectures << architecture_module
          end
        end
      end

      # Get all registered architecture modules
      #
      # @return [Array<Module>] List of registered architecture modules
      def registered_architectures
        @mutex.synchronize { @architectures.dup }
      end

      # Clear all registered architectures (mainly for testing)
      #
      # @return [void]
      def clear!
        @mutex.synchronize { @architectures.clear }
      end

      # Check if an architecture module is registered
      #
      # @param architecture_module [Module] The module to check
      # @return [Boolean] true if registered
      def registered?(architecture_module)
        @mutex.synchronize { @architectures.include?(architecture_module) }
      end

      # Get registry statistics for debugging
      #
      # @return [Hash] Registry statistics
      def stats
        @mutex.synchronize do
          {
            total_architectures: @architectures.size,
            architectures: @architectures.map(&:name),
            architecture_functions: @architectures.flat_map do |arch_mod|
              arch_mod.instance_methods(false).select { |m| m.to_s.end_with?('_architecture') }
            end
          }
        end
      end
    end
  end
end