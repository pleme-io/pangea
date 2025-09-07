# frozen_string_literal: true

require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
      # Type-safe attributes for AwsLicensemanagerReportGenerator resources
      # Provides a License Manager report generator resource.
      class LicensemanagerReportGeneratorAttributes < Dry::Struct
        attribute :license_manager_report_generator_name, Resources::Types::String
        attribute :type, Resources::Types::Array.of(Types::String).default([].freeze)
        attribute :report_context, Resources::Types::Hash.default({})
        attribute :report_frequency, Resources::Types::String
        attributes3_bucket_name :, Resources::Types::String
        attribute :description, Resources::Types::String.optional
        
        # Tags to apply to the resource
        attribute :tags, Resources::Types::AwsTags.default({})

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)
          
          
          
          
          attrs
        end
        
        # TODO: Add computed properties specific to aws_licensemanager_report_generator

      end
    end
      end
    end
  end
end