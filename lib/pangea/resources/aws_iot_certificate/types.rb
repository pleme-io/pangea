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

require 'pangea/resources/types'
require_relative 'types/validators'
require_relative 'types/helpers'

module Pangea
  module Resources
    module AWS
      module Types
        # Type-safe attributes for AWS IoT Certificate resources
        class IotCertificateAttributes < Dry::Struct
          include IotCertificateHelpers

          # Certificate status (optional - defaults to ACTIVE)
          attribute :active, Resources::Types::Bool.default(true)

          # Certificate signing request (optional)
          attribute :csr, Resources::Types::String.optional

          # Certificate PEM format (optional - for bring your own cert)
          attribute :certificate_pem, Resources::Types::String.optional

          # CA certificate PEM format (optional - for bring your own CA cert)
          attribute :ca_certificate_pem, Resources::Types::String.optional

          # Tags (optional)
          attribute :tags, Resources::Types::AwsTags.default({}.freeze)

          # Custom validation
          def self.new(attributes = {})
            attrs = super(attributes)
            IotCertificateValidators.validate_creation_method!(attrs)
            attrs
          end

          # Certificate creation method detection
          def creation_method
            return :csr if csr && !csr.empty?
            return :certificate_pem if certificate_pem && !certificate_pem.empty?

            :aws_generated
          end

          # Check if using custom certificate
          def using_custom_certificate?
            creation_method != :aws_generated
          end

          # Check if using CA certificate
          def using_ca_certificate?
            ca_certificate_pem && !ca_certificate_pem.empty?
          end

          # Get certificate status
          def certificate_status
            active? ? 'ACTIVE' : 'INACTIVE'
          end
        end
      end
    end
  end
end
