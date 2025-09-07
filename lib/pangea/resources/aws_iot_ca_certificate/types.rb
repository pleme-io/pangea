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
    # AWS IoT CA Certificate Types
    # 
    # CA (Certificate Authority) certificates enable device certificate validation and just-in-time
    # registration (JITR) for large-scale IoT deployments. They establish trust chains for device
    # certificates and enable automated device onboarding.
    module AwsIotCaCertificateTypes
      # Registration configuration for just-in-time registration
      class RegistrationConfig < Dry::Struct
        schema schema.strict

        # IoT policy template for JITR devices
        attribute :template_body, Resources::Types::String.optional

        # Template name for the registration template
        attribute :template_name, Resources::Types::String.optional

        # IAM role ARN for provisioning operations
        attribute :role_arn, Resources::Types::String.optional
      end

      # Main attributes for IoT CA certificate resource
      class Attributes < Dry::Struct
        schema schema.strict

        # Whether the CA certificate is active
        attribute :active, Resources::Types::Bool

        # Set to true to allow auto-registration of device certificates
        attribute :allow_auto_registration, Resources::Types::Bool.optional

        # PEM-encoded CA certificate body
        attribute :ca_certificate_pem, Resources::Types::String

        # PEM-encoded certificate revocation list (optional)
        attribute :certificate_mode, Resources::Types::String.enum('DEFAULT', 'SNI_ONLY').optional

        # Registration configuration for JITR
        attribute? :registration_config, RegistrationConfig.optional

        # Optional tags for organization and billing
        attribute :tags, Resources::Types::Hash.map(Types::String, Types::String).optional

        # PEM-encoded verification certificate (for ownership proof)
        attribute :verification_certificate_pem, Resources::Types::String.optional
      end

      # Output attributes from CA certificate resource
      class Outputs < Dry::Struct
        schema schema.strict

        # The CA certificate ARN
        attribute :arn, Resources::Types::String

        # The CA certificate ID
        attribute :id, Resources::Types::String

        # The customer version of the CA certificate
        attribute :customer_version, Resources::Types::Integer

        # The generation ID of the CA certificate
        attribute :generation_id, Resources::Types::String

        # The status of the CA certificate (ACTIVE, INACTIVE)
        attribute :status, Resources::Types::String

        # Validity period information
        class Validity < Dry::Struct
          schema schema.strict

          # Certificate not valid before this date
          attribute :not_before, Resources::Types::String

          # Certificate not valid after this date  
          attribute :not_after, Resources::Types::String
        end

        attribute :validity, Validity
      end
    end
  end
end