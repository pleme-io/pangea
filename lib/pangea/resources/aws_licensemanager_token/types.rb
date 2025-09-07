# frozen_string_literal: true

require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
      # Type-safe attributes for AwsLicensemanagerToken resources
      # Provides a License Manager token resource.
      class LicensemanagerTokenAttributes < Dry::Struct
        attribute :license_arn, Resources::Types::String
        attribute :role_arns, Resources::Types::Array.of(Types::String).default([].freeze).optional
        attribute :token_properties, Resources::Types::Hash.default({}).optional
        
        # Tags to apply to the resource
        attribute :tags, Resources::Types::AwsTags.default({})

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)
          
          
          
          
          attrs
        end
        
        # TODO: Add computed properties specific to aws_licensemanager_token

      end
    end
      end
    end
  end
end