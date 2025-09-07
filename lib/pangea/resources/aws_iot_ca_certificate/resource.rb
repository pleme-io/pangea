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


require_relative 'types'
require 'pangea/resources/base'

module Pangea
  module Resources
    # AWS IoT CA Certificate Resource
    # 
    # CA certificates establish trust chains for device certificates and enable just-in-time
    # registration (JITR) for automated device onboarding in large-scale IoT deployments.
    # This is essential for managing device identity and implementing zero-touch provisioning.
    #
    # @example Basic CA certificate
    #   aws_iot_ca_certificate(:company_ca, {
    #     active: true,
    #     ca_certificate_pem: File.read("ca-certificate.pem"),
    #     verification_certificate_pem: File.read("verification-cert.pem")
    #   })
    #
    # @example CA certificate with JITR (just-in-time registration)
    #   aws_iot_ca_certificate(:jitr_ca, {
    #     active: true,
    #     allow_auto_registration: true,
    #     ca_certificate_pem: ca_cert_content,
    #     registration_config: {
    #       template_body: JSON.generate({
    #         "templateBody": policy_template,
    #         "deviceTemplate": device_template,
    #         "roleArn": provisioning_role_arn
    #       }),
    #       role_arn: "arn:aws:iam::123456789012:role/IoTProvisioningRole"
    #     }
    #   })
    #
    # @example Production CA certificate with SNI
    #   aws_iot_ca_certificate(:production_ca, {
    #     active: true,
    #     allow_auto_registration: false,
    #     ca_certificate_pem: production_ca_pem,
    #     certificate_mode: "SNI_ONLY",
    #     tags: {
    #       "Environment" => "Production",
    #       "Purpose" => "DeviceAuthentication",
    #       "Owner" => "SecurityTeam"
    #     }
    #   })
    #
    # @example CA certificate for fleet management
    #   aws_iot_ca_certificate(:fleet_ca, {
    #     active: true,
    #     allow_auto_registration: true,
    #     ca_certificate_pem: fleet_ca_certificate,
    #     registration_config: {
    #       template_name: "FleetProvisioningTemplate",
    #       role_arn: fleet_provisioning_role.arn
    #     },
    #     tags: {
    #       "FleetType" => "Industrial",
    #       "AutoRegistration" => "Enabled"
    #     }
    #   })
    module AwsIotCaCertificate
      include AwsIotCaCertificateTypes

      # Creates an AWS IoT CA certificate for device trust chain establishment
      #
      # @param name [Symbol] Logical name for the CA certificate resource
      # @param attributes [Hash] CA certificate configuration attributes
      # @return [Reference] Resource reference for use in other resources
      def aws_iot_ca_certificate(name, attributes = {})
        validated_attributes = Attributes[attributes]
        
        resource :aws_iot_ca_certificate, name do
          active validated_attributes.active
          allow_auto_registration validated_attributes.allow_auto_registration if validated_attributes.allow_auto_registration
          ca_certificate_pem validated_attributes.ca_certificate_pem
          certificate_mode validated_attributes.certificate_mode if validated_attributes.certificate_mode

          if validated_attributes.registration_config
            registration_config do
              template_body validated_attributes.registration_config.template_body if validated_attributes.registration_config.template_body
              template_name validated_attributes.registration_config.template_name if validated_attributes.registration_config.template_name
              role_arn validated_attributes.registration_config.role_arn if validated_attributes.registration_config.role_arn
            end
          end

          tags validated_attributes.tags if validated_attributes.tags
          verification_certificate_pem validated_attributes.verification_certificate_pem if validated_attributes.verification_certificate_pem
        end

        Reference.new(
          type: :aws_iot_ca_certificate,
          name: name,
          attributes: Outputs.new(
            arn: "${aws_iot_ca_certificate.#{name}.arn}",
            id: "${aws_iot_ca_certificate.#{name}.id}",
            customer_version: "${aws_iot_ca_certificate.#{name}.customer_version}",
            generation_id: "${aws_iot_ca_certificate.#{name}.generation_id}",
            status: "${aws_iot_ca_certificate.#{name}.status}",
            validity: Outputs::Validity.new(
              not_before: "${aws_iot_ca_certificate.#{name}.validity[0].not_before}",
              not_after: "${aws_iot_ca_certificate.#{name}.validity[0].not_after}"
            )
          )
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)