# frozen_string_literal: true

require 'dry-struct'
require 'pangea/resources/types'
require 'json'

module Pangea
  module Resources
    module AWS
      module Types
      # Type-safe attributes for AWS S3 Bucket Policy resources
      class S3BucketPolicyAttributes < Dry::Struct
        transform_keys(&:to_sym)

        # Bucket name (required)
        attribute :bucket, Resources::Types::String

        # JSON policy document (required)
        attribute :policy, Resources::Types::String

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)

          # Validate policy is valid JSON
          begin
            policy_doc = JSON.parse(attrs.policy)
          rescue JSON::ParserError => e
            raise Dry::Struct::Error, "policy must be valid JSON: #{e.message}"
          end

          # Validate policy has required IAM policy structure
          unless policy_doc.is_a?(Hash) && policy_doc.key?('Version') && policy_doc.key?('Statement')
            raise Dry::Struct::Error, "policy must be a valid IAM policy document with Version and Statement"
          end

          # Validate statements structure
          statements = policy_doc['Statement']
          unless statements.is_a?(Array) && statements.all? { |s| s.is_a?(Hash) && s.key?('Effect') }
            raise Dry::Struct::Error, "policy statements must be an array with each statement having an Effect"
          end

          attrs
        end

        # Helper methods
        def policy_document
          JSON.parse(policy)
        end

        def statement_count
          policy_document['Statement'].size
        end

        def allows_public_read?
          policy_document['Statement'].any? do |stmt|
            stmt['Effect'] == 'Allow' && 
            (stmt['Principal'] == '*' || stmt['Principal']&.dig('AWS') == '*') &&
            (stmt['Action']&.include?('s3:GetObject') || stmt['Action']&.include?('s3:*'))
          end
        end

        def allows_public_write?
          policy_document['Statement'].any? do |stmt|
            stmt['Effect'] == 'Allow' && 
            (stmt['Principal'] == '*' || stmt['Principal']&.dig('AWS') == '*') &&
            (stmt['Action']&.include?('s3:PutObject') || stmt['Action']&.include?('s3:*'))
          end
        end

        def has_condition_restrictions?
          policy_document['Statement'].any? { |stmt| stmt.key?('Condition') }
        end
      end
    end
      end
    end
  end
end