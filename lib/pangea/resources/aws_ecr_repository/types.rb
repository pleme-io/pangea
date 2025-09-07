# frozen_string_literal: true

require 'dry-struct'
require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
        # ECR Repository resource attributes with validation
        class ECRRepositoryAttributes < Dry::Struct
          transform_keys(&:to_sym)
          
          # Required attributes
          attribute :name, Pangea::Resources::Types::String
          
          # Optional attributes
          attribute :image_tag_mutability, Pangea::Resources::Types::String.default('MUTABLE').constrained(included_in: ['MUTABLE', 'IMMUTABLE'])
          attribute :image_scanning_configuration, Pangea::Resources::Types::Hash.schema(
            scan_on_push: Pangea::Resources::Types::Bool.default(false)
          ).default({})
          attribute :encryption_configuration, Pangea::Resources::Types::Hash.schema(
            encryption_type?: Pangea::Resources::Types::String.constrained(included_in: ['AES256', 'KMS']),
            kms_key?: Pangea::Resources::Types::String
          ).optional.default(nil)
          attribute :force_delete, Pangea::Resources::Types::Bool.default(false)
          attribute :tags, Pangea::Resources::Types::AwsTags
          
          # Validate attributes
          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}
            
            # Validate repository name
            if attrs[:name]
              name = attrs[:name]
              unless name.match?(/^[a-z0-9]+(?:[._-][a-z0-9]+)*$/)
                raise Dry::Struct::Error, "Repository name must contain only lowercase letters, numbers, hyphens, underscores, and periods"
              end
              
              if name.length < 2 || name.length > 256
                raise Dry::Struct::Error, "Repository name must be between 2 and 256 characters"
              end
              
              if name.start_with?('-') || name.end_with?('-')
                raise Dry::Struct::Error, "Repository name cannot start or end with hyphens"
              end
            end
            
            # Validate encryption configuration
            if attrs[:encryption_configuration]
              enc = attrs[:encryption_configuration]
              if enc[:encryption_type] == 'KMS' && !enc[:kms_key]
                raise Dry::Struct::Error, "kms_key is required when encryption_type is KMS"
              end
              
              if enc[:kms_key] && enc[:encryption_type] != 'KMS'
                raise Dry::Struct::Error, "kms_key can only be specified when encryption_type is KMS"
              end
            end
            
            super(attrs)
          end
          
          # Computed properties
          def repository_uri_template
            "${aws_ecr_repository.%{name}.repository_url}"
          end
          
          def is_immutable?
            image_tag_mutability == 'IMMUTABLE'
          end
          
          def scan_on_push_enabled?
            image_scanning_configuration[:scan_on_push] || false
          end
          
          def uses_kms_encryption?
            encryption_configuration && encryption_configuration[:encryption_type] == 'KMS'
          end
          
          def uses_aes256_encryption?
            encryption_configuration && encryption_configuration[:encryption_type] == 'AES256'
          end
          
          def allows_force_delete?
            force_delete
          end
          
          def registry_id_template
            "${aws_ecr_repository.%{name}.registry_id}"
          end
          
          def to_h
            hash = {
              name: name,
              image_tag_mutability: image_tag_mutability,
              image_scanning_configuration: {
                scan_on_push: scan_on_push_enabled?
              },
              force_delete: force_delete,
              tags: tags
            }
            
            if encryption_configuration
              hash[:encryption_configuration] = [encryption_configuration.compact]
            end
            
            hash.compact
          end
        end
      end
    end
  end
end