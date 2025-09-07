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
        # OpenSearch domain endpoint configuration for custom domains
        class DomainEndpointAttributes < Dry::Struct
          attribute :domain_arn, Types::String
          attribute :domain_endpoint_options do
            attribute :custom_endpoint_enabled, Types::Bool
            attribute :custom_endpoint, Types::String.optional
            attribute :custom_endpoint_certificate_arn, Types::String.optional
            attribute :enforce_https, Types::Bool.default(true)
            attribute :tls_security_policy, Types::String.default('Policy-Min-TLS-1-2-2019-07')
          end
        end

        # OpenSearch domain endpoint reference
        class DomainEndpointReference < ::Pangea::Resources::ResourceReference
          property :id
          property :domain_arn

          def custom_endpoint
            get_attribute(:domain_endpoint_options)&.custom_endpoint
          end

          def custom_endpoint_enabled?
            get_attribute(:domain_endpoint_options)&.custom_endpoint_enabled || false
          end

          def https_enforced?
            get_attribute(:domain_endpoint_options)&.enforce_https || false
          end

          def endpoint_url(path = '')
            endpoint = custom_endpoint || id
            "https://#{endpoint}#{path}"
          end
        end

        module DomainEndpoint
          # Configures a custom endpoint for an OpenSearch domain
          #
          # @param name [Symbol] The endpoint configuration name
          # @param attributes [Hash] Endpoint configuration
          # @return [DomainEndpointReference] Reference to the endpoint configuration
          def aws_opensearch_domain_endpoint(name, attributes = {})
            endpoint_attrs = DomainEndpointAttributes.new(attributes)
            
            synthesizer.resource :aws_opensearch_domain_endpoint, name do
              domain_arn endpoint_attrs.domain_arn

              domain_endpoint_options do
                custom_endpoint_enabled endpoint_attrs.domain_endpoint_options.custom_endpoint_enabled
                custom_endpoint endpoint_attrs.domain_endpoint_options.custom_endpoint if endpoint_attrs.domain_endpoint_options.custom_endpoint
                custom_endpoint_certificate_arn endpoint_attrs.domain_endpoint_options.custom_endpoint_certificate_arn if endpoint_attrs.domain_endpoint_options.custom_endpoint_certificate_arn
                enforce_https endpoint_attrs.domain_endpoint_options.enforce_https
                tls_security_policy endpoint_attrs.domain_endpoint_options.tls_security_policy
              end
            end

            DomainEndpointReference.new(name, :aws_opensearch_domain_endpoint, synthesizer, endpoint_attrs)
          end
        end
      end
    end
  end
end