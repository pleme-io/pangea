# frozen_string_literal: true

module Pangea
  module Components
    # Base module for all Pangea components
    #
    # Provides common functionality and patterns for component implementations.
    # Components that include this module get access to helper methods and
    # standard validation patterns.
    module Base
      # Base error class for component-related errors
      class ComponentError < StandardError; end
      
      # Error raised when component validation fails
      class ValidationError < ComponentError; end
      
      # Error raised when component composition fails
      class CompositionError < ComponentError; end

      # Validate required attributes are present
      #
      # @param attributes [Hash] Input attributes
      # @param required [Array<Symbol>] Required attribute names
      # @raise [ValidationError] if any required attributes are missing
      def validate_required_attributes(attributes, required)
        missing = required - attributes.keys
        unless missing.empty?
          raise ValidationError, "Missing required attributes: #{missing.join(', ')}"
        end
      end

      # Calculate subnet CIDR blocks from a VPC CIDR
      #
      # @param vpc_cidr [String] VPC CIDR block (e.g., "10.0.0.0/16")
      # @param index [Integer] Subnet index
      # @param new_bits [Integer] Additional bits for subnet mask (default: 8)
      # @return [String] Subnet CIDR block
      def calculate_subnet_cidr(vpc_cidr, index, new_bits = 8)
        require 'ipaddr'
        
        vpc_network = IPAddr.new(vpc_cidr)
        vpc_prefix = vpc_cidr.split('/').last.to_i
        subnet_prefix = vpc_prefix + new_bits
        
        # Calculate the subnet size
        subnet_size = 2 ** (32 - subnet_prefix)
        
        # Calculate the subnet network address
        subnet_network = vpc_network.to_i + (index * subnet_size)
        
        # Return the subnet CIDR
        "#{IPAddr.new(subnet_network, Socket::AF_INET)}/#{subnet_prefix}"
      end

      # Generate consistent naming for component resources
      #
      # @param component_name [Symbol, String] Base component name
      # @param resource_type [Symbol, String] Type of resource
      # @param suffix [String, nil] Optional suffix
      # @return [Symbol] Generated resource name
      def component_resource_name(component_name, resource_type, suffix = nil)
        parts = [component_name, resource_type]
        parts << suffix if suffix
        parts.join('_').to_sym
      end

      # Merge default tags with user-provided tags
      #
      # @param default_tags [Hash] Default tags to apply
      # @param user_tags [Hash] User-provided tags (takes precedence)
      # @return [Hash] Merged tags
      def merge_tags(default_tags, user_tags = {})
        default_tags.merge(user_tags)
      end

      # Create a component output hash
      #
      # @param resources [Hash] Created resources
      # @param computed [Hash] Computed values
      # @return [Hash] Combined outputs
      def component_outputs(resources, computed = {})
        {
          resources: resources,
          computed: computed,
          created_at: Time.now.utc.iso8601
        }
      end
    end
  end
end