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
require 'pangea/resources/aws_acm_certificate/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS ACM (Certificate Manager) Certificate with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Certificate attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_acm_certificate(name, attributes = {})
        # Validate attributes using dry-struct
        cert_attrs = Types::Types::AcmCertificateAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_acm_certificate, name) do
          domain_name cert_attrs.domain_name
          
          # Add subject alternative names if provided
          if cert_attrs.subject_alternative_names&.any?
            subject_alternative_names cert_attrs.subject_alternative_names
          end
          
          validation_method cert_attrs.validation_method
          
          # Set key algorithm if specified
          if cert_attrs.key_algorithm
            key_algorithm cert_attrs.key_algorithm
          end
          
          # Configure certificate transparency logging
          if cert_attrs.certificate_transparency_logging_preference
            options do
              certificate_transparency_logging_preference cert_attrs.certificate_transparency_logging_preference
            end
          end
          
          # Add validation options if provided
          if cert_attrs.validation_options&.any?
            cert_attrs.validation_options.each do |validation_option|
              validation_option do
                domain_name validation_option[:domain_name]
                if validation_option[:validation_domain]
                  validation_domain validation_option[:validation_domain]
                end
              end
            end
          end
          
          # Apply tags if present
          if cert_attrs.tags&.any?
            tags do
              cert_attrs.tags.each do |key, value|
                public_send(key, value)
              end
            end
          end
          
          # Apply lifecycle configuration if specified
          if cert_attrs.lifecycle
            lifecycle do
              if cert_attrs.lifecycle[:create_before_destroy]
                create_before_destroy cert_attrs.lifecycle[:create_before_destroy]
              end
              if cert_attrs.lifecycle[:prevent_destroy]
                prevent_destroy cert_attrs.lifecycle[:prevent_destroy]
              end
            end
          end
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_acm_certificate',
          name: name,
          resource_attributes: cert_attrs.to_h,
          outputs: {
            id: "${aws_acm_certificate.#{name}.id}",
            arn: "${aws_acm_certificate.#{name}.arn}",
            domain_name: "${aws_acm_certificate.#{name}.domain_name}",
            domain_validation_options: "${aws_acm_certificate.#{name}.domain_validation_options}",
            status: "${aws_acm_certificate.#{name}.status}",
            validation_emails: "${aws_acm_certificate.#{name}.validation_emails}",
            validation_method: "${aws_acm_certificate.#{name}.validation_method}",
            subject_alternative_names: "${aws_acm_certificate.#{name}.subject_alternative_names}",
            key_algorithm: "${aws_acm_certificate.#{name}.key_algorithm}",
            not_after: "${aws_acm_certificate.#{name}.not_after}",
            not_before: "${aws_acm_certificate.#{name}.not_before}",
            pending_renewal: "${aws_acm_certificate.#{name}.pending_renewal}",
            renewal_eligibility: "${aws_acm_certificate.#{name}.renewal_eligibility}",
            renewal_summary: "${aws_acm_certificate.#{name}.renewal_summary}",
            type: "${aws_acm_certificate.#{name}.type}"
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)