# frozen_string_literal: true

require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/aws_licensemanager_association/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Provides a License Manager association between a license configuration and a resource.
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Resource attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_licensemanager_association(name, attributes = {})
        # Validate attributes using dry-struct
        attrs = Types::LicensemanagerAssociationAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_licensemanager_association, name) do
          license_configuration_arn attrs.license_configuration_arn if attrs.license_configuration_arn
          resource_arn attrs.resource_arn if attrs.resource_arn
          
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
          type: 'aws_licensemanager_association',
          name: name,
          resource_attributes: attrs.to_h,
          outputs: {
            id: "${aws_licensemanager_association.#{name}.id}"
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