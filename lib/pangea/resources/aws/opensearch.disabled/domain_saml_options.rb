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
        # OpenSearch domain SAML authentication configuration
        class DomainSamlOptionsAttributes < Dry::Struct
          attribute :domain_name, Types::String
          
          attribute? :saml_options do
            attribute :enabled, Types::Bool.default(true)
            attribute? :idp do
              attribute :entity_id, Types::String
              attribute :metadata_content, Types::String
            end
            attribute :master_user_name, Types::String.optional
            attribute :master_backend_role, Types::String.optional
            attribute :subject_key, Types::String.default('http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name')
            attribute :roles_key, Types::String.default('http://schemas.microsoft.com/ws/2008/06/identity/claims/role')
            attribute :session_timeout_minutes, Types::Integer.default(60)
          end
        end

        # OpenSearch domain SAML options reference
        class DomainSamlOptionsReference < ::Pangea::Resources::ResourceReference
          property :id
          property :domain_name

          def saml_enabled?
            saml_options = get_attribute(:saml_options)
            saml_options&.enabled || false
          end

          def idp_entity_id
            get_attribute(:saml_options)&.idp&.entity_id
          end

          def master_user_name
            get_attribute(:saml_options)&.master_user_name
          end

          def session_timeout_minutes
            get_attribute(:saml_options)&.session_timeout_minutes || 60
          end
        end

        module DomainSamlOptions
          # Configures SAML authentication for an OpenSearch domain
          #
          # @param name [Symbol] The SAML configuration name
          # @param attributes [Hash] SAML configuration
          # @return [DomainSamlOptionsReference] Reference to the SAML configuration
          def aws_opensearch_domain_saml_options(name, attributes = {})
            saml_attrs = DomainSamlOptionsAttributes.new(attributes)
            
            synthesizer.resource :aws_opensearch_domain_saml_options, name do
              domain_name saml_attrs.domain_name

              if saml_attrs.saml_options
                saml_options do
                  enabled saml_attrs.saml_options.enabled

                  if saml_attrs.saml_options.idp
                    idp do
                      entity_id saml_attrs.saml_options.idp.entity_id
                      metadata_content saml_attrs.saml_options.idp.metadata_content
                    end
                  end

                  master_user_name saml_attrs.saml_options.master_user_name if saml_attrs.saml_options.master_user_name
                  master_backend_role saml_attrs.saml_options.master_backend_role if saml_attrs.saml_options.master_backend_role
                  subject_key saml_attrs.saml_options.subject_key
                  roles_key saml_attrs.saml_options.roles_key
                  session_timeout_minutes saml_attrs.saml_options.session_timeout_minutes
                end
              end
            end

            DomainSamlOptionsReference.new(name, :aws_opensearch_domain_saml_options, synthesizer, saml_attrs)
          end
        end
      end
    end
  end
end