# frozen_string_literal: true

require 'set'

module Pangea
  # Global registry for resource modules that auto-register when loaded
  module ResourceRegistry
    @registered_modules = Set.new
    @provider_modules = Hash.new { |h, k| h[k] = Set.new }

    class << self
      def register_module(mod)
        @registered_modules.add(mod)
      end

      def registered_modules
        @registered_modules.to_a
      end

      def clear!
        @registered_modules.clear
      end

      def registered?(mod)
        @registered_modules.include?(mod)
      end

      def register(provider, mod)
        @provider_modules[provider].add(mod)
        @registered_modules.add(mod)
      end

      def modules_for(provider)
        @provider_modules[provider].to_a
      end

      def stats
        {
          total_modules: @registered_modules.size,
          modules: @registered_modules.map(&:name),
          by_provider: @provider_modules.transform_values(&:size)
        }
      end
    end
  end
end
