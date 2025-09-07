# frozen_string_literal: true
# Copyright 2025 The Pangea Authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


require 'dry-struct'
require 'pangea/resources/types'
require 'pangea/resources/base'
require 'pangea/resources/reference'

module Pangea
  module Resources
    module AWS
      module OpenSearch
        # OpenSearch Serverless security policy configuration
        class ServerlessSecurityPolicyAttributes < Dry::Struct
          attribute :name, Types::String
          attribute :type, Types::String # 'encryption', 'network'
          attribute :description, Types::String.optional
          attribute :policy, Types::String # JSON policy document
        end

        # OpenSearch Serverless security policy reference
        class ServerlessSecurityPolicyReference < ::Pangea::Resources::ResourceReference
          property :id
          property :name
          property :type
          property :policy_version

          def policy_type
            get_attribute(:type)
          end

          def encryption_policy?
            policy_type == 'encryption'
          end

          def network_policy?
            policy_type == 'network'
          end

          def policy_document
            get_attribute(:policy)
          end

          def policy_json
            JSON.parse(policy_document) if policy_document
          rescue JSON::ParserError
            nil
          end

          def applies_to_collections
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

          def encryption_in_transit_enabled?
            return false unless encryption_policy? && policy_json

            rules = policy_json['Rules'] || []
            rules.any? { |rule| rule.dig('ResourceType') == 'collection' }
          end

          def vpc_access_configured?
            return false unless network_policy? && policy_json

            rules = policy_json['Rules'] || []
            rules.any? { |rule| rule.dig('AllowFromPublic') == false }
          end
        end

        module ServerlessSecurityPolicy
          # Creates an OpenSearch Serverless security policy
          #
          # @param name [Symbol] The policy identifier
          # @param attributes [Hash] Policy configuration
          # @return [ServerlessSecurityPolicyReference] Reference to the policy
          def aws_opensearch_serverless_security_policy(name, attributes = {})
            policy_attrs = ServerlessSecurityPolicyAttributes.new(attributes)
            
            synthesizer.resource :aws_opensearch_serverless_security_policy, name do
              name policy_attrs.name
              type policy_attrs.type
              description policy_attrs.description if policy_attrs.description
              policy policy_attrs.policy
            end

            ServerlessSecurityPolicyReference.new(name, :aws_opensearch_serverless_security_policy, synthesizer, policy_attrs)
          end
        end
      end
    end
  end
end