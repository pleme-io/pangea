# frozen_string_literal: true

require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/aws_ram_sharing_with_organization/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Manages Resource Access Manager (RAM) resource sharing with AWS Organizations.
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Resource attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_ram_sharing_with_organization(name, attributes = {})
        # Validate attributes using dry-struct
        attrs = Types::RamSharingWithOrganizationAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_ram_sharing_with_organization, name) do
          enable attrs.enable if attrs.enable
          
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
          type: 'aws_ram_sharing_with_organization',
          name: name,
          resource_attributes: attrs.to_h,
          outputs: {
            id: "${aws_ram_sharing_with_organization.#{name}.id}"
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