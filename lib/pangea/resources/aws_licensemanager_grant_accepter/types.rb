# frozen_string_literal: true

require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
      # Type-safe attributes for AwsLicensemanagerGrantAccepter resources
      # Provides a License Manager grant accepter resource.
      class LicensemanagerGrantAccepterAttributes < Dry::Struct
        attribute :grant_arn, Resources::Types::String
        
        # Tags to apply to the resource
        attribute :tags, Resources::Types::AwsTags.default({})

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)
          
          
          
          
          attrs
        end
        
        # TODO: Add computed properties specific to aws_licensemanager_grant_accepter

      end
    end
      end
    end
  end
end