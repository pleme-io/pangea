# frozen_string_literal: true

require 'dry-struct'
require 'pangea/resources/types'
require 'pangea/resources/base'
require 'pangea/resources/reference'

module Pangea
  module Resources
    module AWS
      module OpenSearch
        # OpenSearch domain access policy configuration
        class DomainPolicyAttributes < Dry::Struct
          attribute :domain_name, Types::String
          attribute :access_policies, Types::String
        end

        # OpenSearch domain policy reference
        class DomainPolicyReference < ::Pangea::Resources::ResourceReference
          property :id
          property :domain_name

          def access_policies
            get_attribute(:access_policies)
          end

          def policy_json
            JSON.parse(access_policies) if access_policies
          rescue JSON::ParserError
            nil
          end

          def allows_public_access?
            return false unless policy_json

            # Check if policy contains wildcard principals
            statements = policy_json['Statement'] || []
            statements.any? do |statement|
              principal = statement['Principal']
              principal == '*' || (principal.is_a?(Hash) && principal['AWS'] == '*')
            end
          end

          def restricted_to_vpc?
            return false unless policy_json

            statements = policy_json['Statement'] || []
            statements.any? do |statement|
              condition = statement['Condition'] || {}
              condition.key?('IpAddress') || condition.key?('aws:SourceVpc') || condition.key?('aws:sourceVpce')
            end
          end
        end

        module DomainPolicy
          # Configures access policies for an OpenSearch domain
          #
          # @param name [Symbol] The policy name
          # @param attributes [Hash] Policy configuration
          # @return [DomainPolicyReference] Reference to the policy
          def aws_opensearch_domain_policy(name, attributes = {})
            policy_attrs = DomainPolicyAttributes.new(attributes)
            
            synthesizer.resource :aws_opensearch_domain_policy, name do
              domain_name policy_attrs.domain_name
              access_policies policy_attrs.access_policies
            end

            DomainPolicyReference.new(name, :aws_opensearch_domain_policy, synthesizer, policy_attrs)
          end
        end
      end
    end
  end
end