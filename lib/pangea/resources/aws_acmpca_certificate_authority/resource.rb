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


require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/aws_acmpca_certificate_authority/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS ACM PCA Certificate Authority with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] ACM PCA certificate authority attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_acmpca_certificate_authority(name, attributes = {})
        # Validate attributes using dry-struct
        ca_attrs = Types::AcmPcaCertificateAuthorityAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_acmpca_certificate_authority, name) do
          # Configure certificate authority
          certificate_authority_configuration do
            key_algorithm ca_attrs.certificate_authority_configuration[:key_algorithm]
            signing_algorithm ca_attrs.certificate_authority_configuration[:signing_algorithm]
            
            subject do
              ca_attrs.certificate_authority_configuration[:subject].each do |key, value|
                public_send(key, value) if value
              end
            end
          end
          
          type ca_attrs.type
          status ca_attrs.status if ca_attrs.status
          permanent_deletion_time_in_days ca_attrs.permanent_deletion_time_in_days
          
          # Configure revocation if specified
          if ca_attrs.revocation_configuration
            revocation_configuration do
              if ca_attrs.revocation_configuration[:crl_configuration]
                crl_configuration do
                  enabled ca_attrs.revocation_configuration[:crl_configuration][:enabled]
                  expiration_in_days ca_attrs.revocation_configuration[:crl_configuration][:expiration_in_days] if ca_attrs.revocation_configuration[:crl_configuration][:expiration_in_days]
                  custom_cname ca_attrs.revocation_configuration[:crl_configuration][:custom_cname] if ca_attrs.revocation_configuration[:crl_configuration][:custom_cname]
                  s3_bucket_name ca_attrs.revocation_configuration[:crl_configuration][:s3_bucket_name] if ca_attrs.revocation_configuration[:crl_configuration][:s3_bucket_name]
                  s3_object_acl ca_attrs.revocation_configuration[:crl_configuration][:s3_object_acl] if ca_attrs.revocation_configuration[:crl_configuration][:s3_object_acl]
                end
              end
              
              if ca_attrs.revocation_configuration[:ocsp_configuration]
                ocsp_configuration do
                  enabled ca_attrs.revocation_configuration[:ocsp_configuration][:enabled]
                  ocsp_custom_cname ca_attrs.revocation_configuration[:ocsp_configuration][:ocsp_custom_cname] if ca_attrs.revocation_configuration[:ocsp_configuration][:ocsp_custom_cname]
                end
              end
            end
          end
          
          # Set usage mode and security standard if specified
          usage_mode ca_attrs.usage_mode if ca_attrs.usage_mode
          key_storage_security_standard ca_attrs.key_storage_security_standard if ca_attrs.key_storage_security_standard
          
          # Apply tags if present
          if ca_attrs.tags.any?
            tags do
              ca_attrs.tags.each do |key, value|
                public_send(key, value)
              end
            end
          end
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_acmpca_certificate_authority',
          name: name,
          resource_attributes: ca_attrs.to_h,
          outputs: {
            id: "${aws_acmpca_certificate_authority.#{name}.id}",
            arn: "${aws_acmpca_certificate_authority.#{name}.arn}",
            certificate: "${aws_acmpca_certificate_authority.#{name}.certificate}",
            certificate_chain: "${aws_acmpca_certificate_authority.#{name}.certificate_chain}",
            certificate_signing_request: "${aws_acmpca_certificate_authority.#{name}.certificate_signing_request}",
            not_after: "${aws_acmpca_certificate_authority.#{name}.not_after}",
            not_before: "${aws_acmpca_certificate_authority.#{name}.not_before}",
            serial: "${aws_acmpca_certificate_authority.#{name}.serial}",
            status: "${aws_acmpca_certificate_authority.#{name}.status}",
            type: "${aws_acmpca_certificate_authority.#{name}.type}",
            usage_mode: "${aws_acmpca_certificate_authority.#{name}.usage_mode}",
            tags_all: "${aws_acmpca_certificate_authority.#{name}.tags_all}"
          },
          computed_properties: {
            root_ca: ca_attrs.root_ca?,
            subordinate_ca: ca_attrs.subordinate_ca?,
            rsa_key: ca_attrs.rsa_key?,
            ec_key: ca_attrs.ec_key?,
            key_size: ca_attrs.key_size,
            signing_strength: ca_attrs.signing_strength,
            has_crl_distribution: ca_attrs.has_crl_distribution?,
            has_ocsp: ca_attrs.has_ocsp?,
            security_level: ca_attrs.security_level,
            production_ready: ca_attrs.production_ready?,
            hierarchy_level: ca_attrs.hierarchy_level,
            configuration_warnings: ca_attrs.validate_configuration,
            estimated_monthly_cost: ca_attrs.estimated_monthly_cost
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)