# frozen_string_literal: true

require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/aws_ram_resource_association/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Associates a resource with a RAM Resource Share.
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Resource attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_ram_resource_association(name, attributes = {})
        # Validate attributes using dry-struct
        attrs = Types::RamResourceAssociationAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_ram_resource_association, name) do
          resource_arn attrs.resource_arn if attrs.resource_arn
          resource_share_arn attrs.resource_share_arn if attrs.resource_share_arn
          
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
          type: 'aws_ram_resource_association',
          name: name,
          resource_attributes: attrs.to_h,
          outputs: {
            id: "${aws_ram_resource_association.#{name}.id}"
          },
          computed_properties: {
            # Computed properties from type definitions
          }
        )
      end
    end
  end
end


# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)