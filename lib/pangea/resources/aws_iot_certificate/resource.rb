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
require 'pangea/resources/aws_iot_certificate/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS IoT Certificate with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] IoT Certificate attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_iot_certificate(name, attributes = {})
        # Validate attributes using dry-struct
        cert_attrs = Types::IotCertificateAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_iot_certificate, name) do
          # Certificate status
          active cert_attrs.active
          
          # Certificate signing request (if provided)
          csr cert_attrs.csr if cert_attrs.csr
          
          # Certificate PEM (if provided for bring your own cert)
          certificate_pem cert_attrs.certificate_pem if cert_attrs.certificate_pem
          
          # CA certificate PEM (if provided)
          ca_certificate_pem cert_attrs.ca_certificate_pem if cert_attrs.ca_certificate_pem
          
          # Apply tags if present
          if cert_attrs.tags.any?
            tags do
              cert_attrs.tags.each do |key, value|
                public_send(key, value)
              end
            end
          end
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_iot_certificate',
          name: name,
          resource_attributes: cert_attrs.to_h,
          outputs: {
            arn: "${aws_iot_certificate.#{name}.arn}",
            certificate_id: "${aws_iot_certificate.#{name}.certificate_id}",
            certificate_pem: "${aws_iot_certificate.#{name}.certificate_pem}",
            public_key: "${aws_iot_certificate.#{name}.public_key}",
            private_key: "${aws_iot_certificate.#{name}.private_key}",
            ca_certificate_pem: "${aws_iot_certificate.#{name}.ca_certificate_pem}",
            validity_start: "${aws_iot_certificate.#{name}.validity_start}",
            validity_end: "${aws_iot_certificate.#{name}.validity_end}",
            tags_all: "${aws_iot_certificate.#{name}.tags_all}"
          },
          computed_properties: {
            creation_method: cert_attrs.creation_method,
            using_custom_certificate: cert_attrs.using_custom_certificate?,
            using_ca_certificate: cert_attrs.using_ca_certificate?,
            certificate_status: cert_attrs.certificate_status,
            security_assessment: cert_attrs.security_assessment,
            recommended_policies: cert_attrs.recommended_policies,
            lifecycle_recommendations: cert_attrs.lifecycle_recommendations,
            compliance_info: cert_attrs.compliance_info,
            operational_metrics: cert_attrs.operational_metrics,
            integration_requirements: cert_attrs.integration_requirements
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)