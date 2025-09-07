# frozen_string_literal: true

require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
      # Type-safe attributes for AwsLicensemanagerAssociation resources
      # Provides a License Manager association between a license configuration and a resource.
      class LicensemanagerAssociationAttributes < Dry::Struct
        attribute :license_configuration_arn, Resources::Types::String
        attribute :resource_arn, Resources::Types::String
        
        # Tags to apply to the resource
        attribute :tags, Resources::Types::AwsTags.default({})

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)
          
          
          
          
          attrs
        end
        
        # TODO: Add computed properties specific to aws_licensemanager_association

      end
    end
      end
    end
  end
end