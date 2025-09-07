# frozen_string_literal: true

require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/aws_licensemanager_license_grant_accepter/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Provides a License Manager license grant accepter resource.
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Resource attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_licensemanager_license_grant_accepter(name, attributes = {})
        # Validate attributes using dry-struct
        attrs = Types::LicensemanagerLicenseGrantAccepterAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_licensemanager_license_grant_accepter, name) do
          grant_arn attrs.grant_arn if attrs.grant_arn
          
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
          type: 'aws_licensemanager_license_grant_accepter',
          name: name,
          resource_attributes: attrs.to_h,
          outputs: {
            id: "${aws_licensemanager_license_grant_accepter.#{name}.id}",
            parent_arn: "${aws_licensemanager_license_grant_accepter.#{name}.parent_arn}"
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