# frozen_string_literal: true

require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
      # Type-safe attributes for AwsDocdbCertificate resources
      # Provides information about a DocumentDB certificate.
      class DocdbCertificateAttributes < Dry::Struct
        attribute :certificate_identifier, Resources::Types::String
        
        # Tags to apply to the resource
        attribute :tags, Resources::Types::AwsTags.default({})

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)
          
          
          
          
          attrs
        end
        
        # TODO: Add computed properties specific to aws_docdb_certificate

      end
    end
      end
    end
  end
end