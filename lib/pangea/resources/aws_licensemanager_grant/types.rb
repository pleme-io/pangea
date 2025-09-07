# frozen_string_literal: true

require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
      # Type-safe attributes for AwsLicensemanagerGrant resources
      # Provides a License Manager grant resource.
      class LicensemanagerGrantAttributes < Dry::Struct
        attribute :name, Resources::Types::String
        attribute :allowed_operations, Resources::Types::Array.of(Types::String).default([].freeze)
        attribute :license_arn, Resources::Types::String
        attribute :principal, Resources::Types::String
        attribute :home_region, Resources::Types::String
        
        # Tags to apply to the resource
        attribute :tags, Resources::Types::AwsTags.default({})

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)
          
          
          
          
          attrs
        end
        
        # TODO: Add computed properties specific to aws_licensemanager_grant

      end
    end
      end
    end
  end
end