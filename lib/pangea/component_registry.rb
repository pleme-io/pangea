# frozen_string_literal: true
# Copyright 2025 The Pangea Authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


module Pangea
  # Registry for auto-loading component modules into template synthesis
  #
  # Components self-register when required, making them available
  # in template contexts automatically without explicit includes.
  #
  # @example Component registration
  #   # In component file
  #   module MyComponent
  #     def my_component(name, attrs = {})
  #       # component implementation
  #     end
  #   end
  #   
  #   Pangea::ComponentRegistry.register_component(MyComponent)
  #
  # @example Usage in template
  #   require 'pangea/components/my_component/component'
  #   
  #   template :infrastructure do
  #     my_component(:example, { ... })  # Available automatically
  #   end
  module ComponentRegistry
    @components = []
    @mutex = Mutex.new

    class << self
      # Register a component module for auto-loading
      #
      # @param component_module [Module] The component module to register
      # @return [void]
      def register_component(component_module)
        @mutex.synchronize do
          unless @components.include?(component_module)
            @components << component_module
          end
        end
      end

      # Get all registered component modules
      #
      # @return [Array<Module>] List of registered component modules
      def registered_components
        @mutex.synchronize { @components.dup }
      end

      # Clear all registered components (mainly for testing)
      #
      # @return [void]
      def clear!
        @mutex.synchronize { @components.clear }
      end

      # Check if a component module is registered
      #
      # @param component_module [Module] The module to check
      # @return [Boolean] true if registered
      def registered?(component_module)
        @mutex.synchronize { @components.include?(component_module) }
      end
    end
  end
end