require 'singleton'

module Pangea
  module Types
    class Registry
      include Singleton
      
      def initialize
        @types = {}
      end
      
      def register(name, base_type, &block)
        type_def = TypeDefinition.new(name, base_type)
        type_def.instance_eval(&block) if block_given?
        @types[name] = type_def
      end
      
      def [](name)
        @types[name] || raise("Unknown type: #{name}")
      end
      
      class TypeDefinition
        attr_reader :name, :base_type, :validations, :constraints
        
        def initialize(name, base_type)
          @name = name
          @base_type = base_type
          @validations = []
          @constraints = {}
        end
        
        def format(regex)
          @constraints[:format] = regex
        end
        
        def enum(values)
          @constraints[:enum] = values
        end
        
        def range(min, max)
          @constraints[:range] = (min..max)
        end
        
        def max_length(length)
          @constraints[:max_length] = length
        end
        
        def validation(&block)
          @validations << block
        end
      end
    end
  end
end