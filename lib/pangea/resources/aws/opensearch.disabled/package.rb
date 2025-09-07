# frozen_string_literal: true

require 'dry-struct'
require 'pangea/resources/types'
require 'pangea/resources/base'
require 'pangea/resources/reference'

module Pangea
  module Resources
    module AWS
      module OpenSearch
        # OpenSearch package for plugins and dictionaries
        class PackageAttributes < Dry::Struct
          attribute :package_name, Types::String
          attribute :package_type, Types::String # 'TXT-DICTIONARY', 'ZIP-PLUGIN'
          attribute :package_description, Types::String.optional
          
          attribute? :package_source do
            attribute :s3_bucket_name, Types::String
            attribute :s3_key, Types::String
          end
          
          attribute :package_encryption_options, Types::Hash.default({})
        end

        # OpenSearch package reference
        class PackageReference < ::Pangea::Resources::ResourceReference
          property :id
          property :package_id
          property :package_name
          property :package_type
          property :package_status

          def dictionary_package?
            package_type == 'TXT-DICTIONARY'
          end

          def plugin_package?
            package_type == 'ZIP-PLUGIN'
          end

          def available?
            package_status == 'AVAILABLE'
          end

          def s3_source
            get_attribute(:package_source)
          end

          def source_location
            source = s3_source
            return nil unless source
            
            "s3://#{source.s3_bucket_name}/#{source.s3_key}"
          end
        end

        module Package
          # Creates an OpenSearch package for plugins or dictionaries
          #
          # @param name [Symbol] The package name
          # @param attributes [Hash] Package configuration
          # @return [PackageReference] Reference to the package
          def aws_opensearch_package(name, attributes = {})
            package_attrs = PackageAttributes.new(attributes)
            
            synthesizer.resource :aws_opensearch_package, name do
              package_name package_attrs.package_name
              package_type package_attrs.package_type
              package_description package_attrs.package_description if package_attrs.package_description

              if package_attrs.package_source
                package_source do
                  s3_bucket_name package_attrs.package_source.s3_bucket_name
                  s3_key package_attrs.package_source.s3_key
                end
              end

              package_encryption_options package_attrs.package_encryption_options unless package_attrs.package_encryption_options.empty?
            end

            PackageReference.new(name, :aws_opensearch_package, synthesizer, package_attrs)
          end
        end
      end
    end
  end
end