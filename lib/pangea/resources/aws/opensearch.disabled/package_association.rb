# frozen_string_literal: true

require 'dry-struct'
require 'pangea/resources/types'
require 'pangea/resources/base'
require 'pangea/resources/reference'

module Pangea
  module Resources
    module AWS
      module OpenSearch
        # OpenSearch package association with domain
        class PackageAssociationAttributes < Dry::Struct
          attribute :package_id, Types::String
          attribute :domain_name, Types::String
        end

        # OpenSearch package association reference
        class PackageAssociationReference < ::Pangea::Resources::ResourceReference
          property :id
          property :package_id
          property :domain_name
          property :domain_package_status

          def associated?
            domain_package_status == 'ACTIVE'
          end

          def associating?
            domain_package_status == 'ASSOCIATING'
          end

          def dissociating?
            domain_package_status == 'DISSOCIATING'
          end

          def association_failed?
            domain_package_status == 'ASSOCIATION_FAILED'
          end

          def dissociation_failed?
            domain_package_status == 'DISSOCIATION_FAILED'
          end
        end

        module PackageAssociation
          # Associates an OpenSearch package with a domain
          #
          # @param name [Symbol] The association name
          # @param attributes [Hash] Association configuration
          # @return [PackageAssociationReference] Reference to the association
          def aws_opensearch_package_association(name, attributes = {})
            association_attrs = PackageAssociationAttributes.new(attributes)
            
            synthesizer.resource :aws_opensearch_package_association, name do
              package_id association_attrs.package_id
              domain_name association_attrs.domain_name
            end

            PackageAssociationReference.new(name, :aws_opensearch_package_association, synthesizer, association_attrs)
          end
        end
      end
    end
  end
end