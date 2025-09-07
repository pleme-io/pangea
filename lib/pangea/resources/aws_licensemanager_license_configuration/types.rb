# frozen_string_literal: true

require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
      # Type-safe attributes for AwsLicensemanagerLicenseConfiguration resources
      # Provides a License Manager license configuration resource.
      class LicensemanagerLicenseConfigurationAttributes < Dry::Struct
        attribute :name, Resources::Types::String
        attribute :license_counting_type, Resources::Types::String
        attribute :description, Resources::Types::String.optional
        attribute :license_count, Resources::Types::Integer.optional
        attribute :license_count_hard_limit, Resources::Types::Bool.optional
        attribute :license_rules, Resources::Types::Array.of(Types::String).default([].freeze).optional
        
        # Tags to apply to the resource
        attribute :tags, Resources::Types::AwsTags.default({})

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)
          
          
          
          
          attrs
        end
        
        # TODO: Add computed properties specific to aws_licensemanager_license_configuration

      end
    end
      end
    end
  end
end