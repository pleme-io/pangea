# frozen_string_literal: true

require 'dry-struct'
require 'pangea/resources/types'
require 'pangea/resources/base'
require 'pangea/resources/reference'

module Pangea
  module Resources
    module AWS
      module OpenSearch
        # OpenSearch Serverless access policy configuration
        class ServerlessAccessPolicyAttributes < Dry::Struct
          attribute :name, Types::String
          attribute :type, Types::String.default('data') # 'data'
          attribute :description, Types::String.optional
          attribute :policy, Types::String # JSON policy document
        end

        # OpenSearch Serverless access policy reference
        class ServerlessAccessPolicyReference < ::Pangea::Resources::ResourceReference
          property :id
          property :name
          property :type
          property :policy_version

          def policy_type
            get_attribute(:type) || 'data'
          end

          def data_access_policy?
            policy_type == 'data'
          end

          def policy_document
            get_attribute(:policy)
          end

          def policy_json
            JSON.parse(policy_document) if policy_document
          rescue JSON::ParserError
            nil
          end

          def granted_principals
            return [] unless policy_json

            rules = policy_json['Rules'] || []
            principals = []
            
            rules.each do |rule|
              rule_principals = rule['Principal'] || []
              principals.concat(Array(rule_principals))
            end
            
            principals.uniq
          end

          def permitted_collections
            return [] unless policy_json

            rules = policy_json['Rules'] || []
            collections = []
            
            rules.each do |rule|
              resource = rule['Resource'] || []
              resource.each do |res|
                if res.start_with?('collection/')
                  collections << res.sub('collection/', '')
                end
              end
            end
            
            collections.uniq
          end

          def permissions_for_principal(principal)
            return [] unless policy_json

            rules = policy_json['Rules'] || []
            permissions = []
            
            rules.each do |rule|
              rule_principals = Array(rule['Principal'] || [])
              if rule_principals.include?(principal)
                permissions.concat(Array(rule['Permission'] || []))
              end
            end
            
            permissions.uniq
          end

          def grants_admin_access?(principal)
            perms = permissions_for_principal(principal)
            perms.include?('aoss:*') || 
              (perms.include?('aoss:CreateCollectionItems') && 
               perms.include?('aoss:UpdateCollectionItems') && 
               perms.include?('aoss:DescribeCollectionItems'))
          end

          def grants_read_access?(principal)
            perms = permissions_for_principal(principal)
            perms.include?('aoss:DescribeCollectionItems') || perms.include?('aoss:*')
          end
        end

        module ServerlessAccessPolicy
          # Creates an OpenSearch Serverless access policy
          #
          # @param name [Symbol] The policy identifier
          # @param attributes [Hash] Policy configuration
          # @return [ServerlessAccessPolicyReference] Reference to the policy
          def aws_opensearch_serverless_access_policy(name, attributes = {})
            policy_attrs = ServerlessAccessPolicyAttributes.new(attributes)
            
            synthesizer.resource :aws_opensearch_serverless_access_policy, name do
              name policy_attrs.name
              type policy_attrs.type
              description policy_attrs.description if policy_attrs.description
              policy policy_attrs.policy
            end

            ServerlessAccessPolicyReference.new(name, :aws_opensearch_serverless_access_policy, synthesizer, policy_attrs)
          end
        end
      end
    end
  end
end