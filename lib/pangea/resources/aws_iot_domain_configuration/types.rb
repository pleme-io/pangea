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

module Pangea
  module Resources
    # AWS IoT Domain Configuration Types
    # 
    # Domain configurations enable custom domain endpoints for IoT device connectivity.
    # They support custom certificates and domain names for production IoT applications
    # requiring branded endpoints and enhanced security.
    module AwsIotDomainConfigurationTypes
      # Authorizer configuration for domain
      class AuthorizerConfig < Dry::Struct
        schema schema.strict

        # Default authorizer name
        attribute :default_authorizer_name, Resources::Types::String.optional

        # Whether authorization is allowed without a default authorizer
        attribute :allow_authorizer_override, Resources::Types::Bool.optional
      end

      # Server certificate configuration
      class ServerCertificateConfig < Dry::Struct
        schema schema.strict

        # Enable OCSP (Online Certificate Status Protocol)
        attribute :enable_ocsp_check, Resources::Types::Bool.optional
      end

      # TLS configuration for domain
      class TlsConfig < Dry::Struct
        schema schema.strict

        # Security policy for TLS connections
        attribute :security_policy, Resources::Types::String.optional
      end

      # Main attributes for IoT domain configuration resource
      class Attributes < Dry::Struct
        schema schema.strict

        # Name of the domain configuration
        attribute :domain_configuration_name, Resources::Types::String

        # Domain name for the endpoint
        attribute :domain_name, Resources::Types::String.optional

        # List of server certificate ARNs
        attribute :server_certificate_arns, Resources::Types::Array.of(Types::String).optional

        # Validation certificate ARN for domain ownership
        attribute :validation_certificate_arn, Resources::Types::String.optional

        # Authorizer configuration
        attribute? :authorizer_config, AuthorizerConfig.optional

        # Server certificate configuration
        attribute? :server_certificate_config, ServerCertificateConfig.optional

        # Service type (DATA, CREDENTIAL_PROVIDER, JOBS)
        attribute :service_type, Resources::Types::String.enum('DATA', 'CREDENTIAL_PROVIDER', 'JOBS').optional

        # TLS configuration
        attribute? :tls_config, TlsConfig.optional

        # Resource tags
        attribute :tags, Resources::Types::Hash.map(Types::String, Types::String).optional
      end

      # Output attributes from domain configuration resource
      class Outputs < Dry::Struct
        schema schema.strict

        # The domain configuration ARN
        attribute :arn, Resources::Types::String

        # The domain configuration name
        attribute :domain_configuration_name, Resources::Types::String

        # The domain name
        attribute :domain_name, Resources::Types::String

        # The domain type (ENDPOINT, AWS_MANAGED)
        attribute :domain_type, Resources::Types::String

        # The server certificates
        attribute :server_certificates, Resources::Types::Array

        # The ID of the domain configuration
        attribute :id, Resources::Types::String
      end
    end
  end
end