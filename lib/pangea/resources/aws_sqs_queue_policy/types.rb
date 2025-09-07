# frozen_string_literal: true

require 'dry-struct'
require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
      # Type-safe attributes for AWS SQS Queue Policy resources
      class SQSQueuePolicyAttributes < Dry::Struct
        transform_keys(&:to_sym)

        # Queue URL to attach the policy to
        attribute :queue_url, Resources::Types::String

        # Policy document as JSON string
        attribute :policy, Resources::Types::String

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)

          # Validate policy is valid JSON
          begin
            policy_doc = JSON.parse(attrs.policy)
            
            # Basic policy structure validation
            unless policy_doc.is_a?(Hash) && policy_doc['Statement'].is_a?(Array)
              raise Dry::Struct::Error, "Policy must be a valid IAM policy document with Statement array"
            end

            # Validate each statement has required fields
            policy_doc['Statement'].each_with_index do |statement, index|
              unless statement['Effect'] && statement['Action']
                raise Dry::Struct::Error, "Policy statement #{index} must have Effect and Action"
              end
              
              unless %w[Allow Deny].include?(statement['Effect'])
                raise Dry::Struct::Error, "Policy statement #{index} Effect must be Allow or Deny"
              end
            end
          rescue JSON::ParserError => e
            raise Dry::Struct::Error, "Policy must be valid JSON: #{e.message}"
          end

          attrs
        end

        # Helper methods
        def policy_document
          @policy_document ||= JSON.parse(policy)
        end

        def statement_count
          policy_document['Statement'].size
        end

        def allows_cross_account?
          policy_document['Statement'].any? do |statement|
            principal = statement['Principal']
            next false unless principal
            
            if principal.is_a?(Hash) && principal['AWS']
              aws_principals = Array(principal['AWS'])
              aws_principals.any? { |p| p.include?(':root') && !p.include?('*') }
            elsif principal.is_a?(String)
              principal != '*' && principal.include?(':root')
            else
              false
            end
          end
        end

        def allows_public_access?
          policy_document['Statement'].any? do |statement|
            statement['Effect'] == 'Allow' && 
            (statement['Principal'] == '*' || 
             (statement['Principal'].is_a?(Hash) && statement['Principal']['AWS'] == '*'))
          end
        end

        def allowed_actions
          policy_document['Statement']
            .select { |s| s['Effect'] == 'Allow' }
            .flat_map { |s| Array(s['Action']) }
            .uniq
        end

        def denied_actions
          policy_document['Statement']
            .select { |s| s['Effect'] == 'Deny' }
            .flat_map { |s| Array(s['Action']) }
            .uniq
        end
      end
    end
      end
    end
  end
end