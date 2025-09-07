# frozen_string_literal: true

require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/aws_licensemanager_license_configuration/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Provides a License Manager license configuration resource.
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Resource attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_licensemanager_license_configuration(name, attributes = {})
        # Validate attributes using dry-struct
        attrs = Types::LicensemanagerLicenseConfigurationAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_licensemanager_license_configuration, name) do
          name attrs.name if attrs.name
          license_counting_type attrs.license_counting_type if attrs.license_counting_type
          description attrs.description if attrs.description
          license_count attrs.license_count if attrs.license_count
          license_count_hard_limit attrs.license_count_hard_limit if attrs.license_count_hard_limit
          license_rules attrs.license_rules if attrs.license_rules
          
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
          type: 'aws_licensemanager_license_configuration',
          name: name,
          resource_attributes: attrs.to_h,
          outputs: {
            id: "${aws_licensemanager_license_configuration.#{name}.id}",
            arn: "${aws_licensemanager_license_configuration.#{name}.arn}",
            owner_account_id: "${aws_licensemanager_license_configuration.#{name}.owner_account_id}"
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