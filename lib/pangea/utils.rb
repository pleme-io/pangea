module Pangea
  module Utils
    class << self
      def component(kwargs)
        resource(kwargs[:type], kwargs[:name]) do
          kwargs[:attrs].each_key do |k|
            send(k, kwargs[:attrs][k])
          end
        end
      end

      def pretty(hash)
        JSON.pretty_generate(hash)
      end

      def symbolize(hash)
        JSON[JSON[hash], symbolize_names: true]
      end

      # Recursively deep merges two hashes.
      def deep_merge(hash1, hash2)
        hash1.merge(hash2) do |_, old_val, new_val|
          if old_val.is_a?(Hash) && new_val.is_a?(Hash)
            deep_merge(old_val, new_val)
          else
            new_val
          end
        end
      end
    end
  end
end
