# frozen_string_literal: true

require 'forwardable'

module Pangea
  module Components
    # Reference object returned by component functions
    #
    # Provides access to all resources created by a component
    # and enables chaining and composition of components.
    #
    # @example Basic usage
    #   network = vpc_with_subnets(:main, { ... })
    #   network.vpc.id           # Access VPC
    #   network.subnets.first.id # Access subnets
    #   network.resources        # All resources
    #
    # @example Composition
    #   network = vpc_with_subnets(:main, { ... })
    #   app = web_application(:myapp, {
    #     vpc_ref: network.vpc,
    #     subnet_refs: network.subnets
    #   })
    class ComponentReference
      extend Forwardable

      attr_reader :type, :name, :resources, :attributes, :outputs

      # Initialize a new component reference
      #
      # @param type [String] Component type (e.g., 'vpc_with_subnets')
      # @param name [Symbol] Component instance name
      # @param resources [Hash] Created resources keyed by name
      # @param attributes [Hash] Original input attributes
      # @param outputs [Hash] Additional computed outputs
      def initialize(type:, name:, resources: {}, attributes: {}, outputs: {})
        @type = type
        @name = name
        @resources = resources
        @attributes = attributes
        @outputs = outputs
      end

      # Access resources by name using method syntax
      #
      # @example
      #   network.vpc     # Returns the VPC resource reference
      #   network.subnets # Returns array of subnet references
      def method_missing(method_name, *args)
        if @resources.key?(method_name)
          @resources[method_name]
        elsif @outputs.key?(method_name)
          @outputs[method_name]
        else
          super
        end
      end

      def respond_to_missing?(method_name, include_private = false)
        @resources.key?(method_name) || @outputs.key?(method_name) || super
      end

      # Array-style access to resources
      #
      # @param key [Symbol, String] Resource or output key
      # @return [Object] The resource or output value
      def [](key)
        key = key.to_sym
        @resources[key] || @outputs[key]
      end

      # Get a specific resource by name
      #
      # @param resource_name [Symbol, String] Resource name
      # @return [Object, nil] The resource reference or nil
      def resource(resource_name)
        @resources[resource_name.to_sym]
      end

      # Get a specific output by name
      #
      # @param output_name [Symbol, String] Output name
      # @return [Object, nil] The output value or nil
      def output(output_name)
        @outputs[output_name.to_sym]
      end

      # Check if component has a specific resource
      #
      # @param resource_name [Symbol, String] Resource name to check
      # @return [Boolean] true if resource exists
      def has_resource?(resource_name)
        @resources.key?(resource_name.to_sym)
      end

      # Check if component has a specific output
      #
      # @param output_name [Symbol, String] Output name to check
      # @return [Boolean] true if output exists
      def has_output?(output_name)
        @outputs.key?(output_name.to_sym)
      end

      # Get all resource names
      #
      # @return [Array<Symbol>] List of resource names
      def resource_names
        @resources.keys
      end

      # Get all output names
      #
      # @return [Array<Symbol>] List of output names
      def output_names
        @outputs.keys
      end

      # Convert to hash representation
      #
      # @return [Hash] Component data as hash
      def to_h
        {
          type: @type,
          name: @name,
          resources: @resources,
          attributes: @attributes,
          outputs: @outputs
        }
      end

      # String representation for debugging
      #
      # @return [String] Human-readable representation
      def to_s
        "#<ComponentReference:#{@type}:#{@name} resources=#{@resources.keys.join(',')}>"
      end

      alias inspect to_s
    end
  end
end