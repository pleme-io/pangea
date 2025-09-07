# frozen_string_literal: true

require 'pangea/resources/base'
require 'pangea/resources/reference'
require_relative 'types'

module Pangea
  module Resources
    module AWS
      # Manages aws vpc endpoint service allowed principal resources.
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Resource attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_vpc_endpoint_service_allowed_principal(name, attributes = {})
        # Validate attributes using dry-struct
        attrs = Types::AwsVpcEndpointServiceAllowedPrincipalAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_vpc_endpoint_service_allowed_principal, name) do
          # TODO: Implement specific resource attributes
          
          # Apply tags if present
          if attrs.tags.any?
            tags do
              attrs.tags.each do |key, value|
                public_send(key, value)
              end
            end
          end
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_vpc_endpoint_service_allowed_principal',
          name: name,
          resource_attributes: attrs.to_h,
          outputs: {
            id: "${aws_vpc_endpoint_service_allowed_principal.#{name}.id}"
            # TODO: Add specific output attributes
          },
          computed_properties: {
            # TODO: Add computed properties
          }
        )
      end
    end
  end
end


# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)