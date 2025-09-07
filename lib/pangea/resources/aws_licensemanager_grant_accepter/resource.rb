# frozen_string_literal: true

require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/aws_licensemanager_grant_accepter/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Provides a License Manager grant accepter resource.
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Resource attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_licensemanager_grant_accepter(name, attributes = {})
        # Validate attributes using dry-struct
        attrs = Types::LicensemanagerGrantAccepterAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_licensemanager_grant_accepter, name) do
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
          type: 'aws_licensemanager_grant_accepter',
          name: name,
          resource_attributes: attrs.to_h,
          outputs: {
            id: "${aws_licensemanager_grant_accepter.#{name}.id}",
            name: "${aws_licensemanager_grant_accepter.#{name}.name}",
            allowed_operations: "${aws_licensemanager_grant_accepter.#{name}.allowed_operations}",
            license_arn: "${aws_licensemanager_grant_accepter.#{name}.license_arn}",
            principal: "${aws_licensemanager_grant_accepter.#{name}.principal}",
            home_region: "${aws_licensemanager_grant_accepter.#{name}.home_region}",
            status: "${aws_licensemanager_grant_accepter.#{name}.status}",
            version: "${aws_licensemanager_grant_accepter.#{name}.version}"
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