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
    # AWS IoT Domain Configuration Resource
    # 
    # Domain configurations provide custom domain endpoints for IoT device connectivity,
    # enabling branded endpoints, custom certificates, and enhanced security for production
    # IoT applications.
    #
    # @example Basic domain configuration with custom domain
    #   aws_iot_domain_configuration(:custom_endpoint, {
    #     domain_configuration_name: "ProductionEndpoint",
    #     domain_name: "iot.mycompany.com",
    #     server_certificate_arns: [acm_certificate.arn],
    #     service_type: "DATA"
    #   })
    #
    # @example Domain configuration with custom authorizer
    #   aws_iot_domain_configuration(:secure_endpoint, {
    #     domain_configuration_name: "SecureCustomEndpoint",
    #     domain_name: "secure-iot.mycompany.com",
    #     server_certificate_arns: [ssl_certificate.arn],
    #     authorizer_config: {
    #       default_authorizer_name: "CustomAuthenticator",
    #       allow_authorizer_override: false
    #     },
    #     server_certificate_config: {
    #       enable_ocsp_check: true
    #     },
    #     tags: {
    #       "Environment" => "Production",
    #       "Security" => "Enhanced"
    #     }
    #   })
    #
    # @example Credential provider domain configuration
    #   aws_iot_domain_configuration(:credential_provider, {
    #     domain_configuration_name: "CredentialProviderEndpoint",
    #     domain_name: "credentials.iot.mycompany.com",
    #     server_certificate_arns: [credential_cert.arn],
    #     service_type: "CREDENTIAL_PROVIDER",
    #     tls_config: {
    #       security_policy: "Policy-2016-03"
    #     }
    #   })
    module AwsIotDomainConfiguration
      include AwsIotDomainConfigurationTypes

      # Creates an AWS IoT domain configuration for custom endpoints
      #
      # @param name [Symbol] Logical name for the domain configuration resource
      # @param attributes [Hash] Domain configuration attributes
      # @return [Reference] Resource reference for use in other resources
      def aws_iot_domain_configuration(name, attributes = {})
        validated_attributes = Attributes[attributes]
        
        resource :aws_iot_domain_configuration, name do
          domain_configuration_name validated_attributes.domain_configuration_name
          domain_name validated_attributes.domain_name if validated_attributes.domain_name
          server_certificate_arns validated_attributes.server_certificate_arns if validated_attributes.server_certificate_arns
          validation_certificate_arn validated_attributes.validation_certificate_arn if validated_attributes.validation_certificate_arn

          if validated_attributes.authorizer_config
            authorizer_config do
              default_authorizer_name validated_attributes.authorizer_config.default_authorizer_name if validated_attributes.authorizer_config.default_authorizer_name
              allow_authorizer_override validated_attributes.authorizer_config.allow_authorizer_override if validated_attributes.authorizer_config.allow_authorizer_override
            end
          end

          if validated_attributes.server_certificate_config
            server_certificate_config do
              enable_ocsp_check validated_attributes.server_certificate_config.enable_ocsp_check if validated_attributes.server_certificate_config.enable_ocsp_check
            end
          end

          service_type validated_attributes.service_type if validated_attributes.service_type

          if validated_attributes.tls_config
            tls_config do
              security_policy validated_attributes.tls_config.security_policy if validated_attributes.tls_config.security_policy
            end
          end

          tags validated_attributes.tags if validated_attributes.tags
        end

        Reference.new(
          type: :aws_iot_domain_configuration,
          name: name,
          attributes: Outputs.new(
            arn: "${aws_iot_domain_configuration.#{name}.arn}",
            domain_configuration_name: "${aws_iot_domain_configuration.#{name}.domain_configuration_name}",
            domain_name: "${aws_iot_domain_configuration.#{name}.domain_name}",
            domain_type: "${aws_iot_domain_configuration.#{name}.domain_type}",
            server_certificates: "${aws_iot_domain_configuration.#{name}.server_certificates}",
            id: "${aws_iot_domain_configuration.#{name}.id}"
          )
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)