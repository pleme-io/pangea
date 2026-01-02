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

module Pangea
  module Resources
    module AWS
      module Types
        # Validation helpers for IoT Certificate attributes
        module IotCertificateValidators
          module_function

          # Validate CSR format
          def valid_csr_format?(csr)
            csr.strip.start_with?('-----BEGIN CERTIFICATE REQUEST-----') &&
              csr.strip.end_with?('-----END CERTIFICATE REQUEST-----')
          end

          # Validate certificate PEM format
          def valid_certificate_pem_format?(cert_pem)
            cert_pem.strip.start_with?('-----BEGIN CERTIFICATE-----') &&
              cert_pem.strip.end_with?('-----END CERTIFICATE-----')
          end

          # Validate certificate creation method
          def validate_creation_method!(attrs)
            has_csr = attrs.csr && !attrs.csr.empty?
            has_cert_pem = attrs.certificate_pem && !attrs.certificate_pem.empty?
            has_ca_cert = attrs.ca_certificate_pem && !attrs.ca_certificate_pem.empty?

            validate_exclusive_creation_method!(has_csr, has_cert_pem)
            validate_ca_certificate_requirements!(has_ca_cert, has_cert_pem)
            validate_pem_formats!(attrs, has_csr, has_cert_pem, has_ca_cert)
          end

          # Can't have both CSR and certificate PEM
          def validate_exclusive_creation_method!(has_csr, has_cert_pem)
            return unless has_csr && has_cert_pem

            raise Dry::Struct::Error,
                  'Cannot specify both CSR and certificate_pem - choose one creation method'
          end

          # If providing CA cert, must also provide certificate PEM
          def validate_ca_certificate_requirements!(has_ca_cert, has_cert_pem)
            return unless has_ca_cert && !has_cert_pem

            raise Dry::Struct::Error,
                  'ca_certificate_pem requires certificate_pem to be provided'
          end

          # Validate PEM formats
          def validate_pem_formats!(attrs, has_csr, has_cert_pem, has_ca_cert)
            if has_csr && !valid_csr_format?(attrs.csr)
              raise Dry::Struct::Error,
                    'CSR must be in valid PEM format starting with -----BEGIN CERTIFICATE REQUEST-----'
            end

            if has_cert_pem && !valid_certificate_pem_format?(attrs.certificate_pem)
              raise Dry::Struct::Error,
                    'Certificate PEM must be in valid PEM format starting with -----BEGIN CERTIFICATE-----'
            end

            return unless has_ca_cert && !valid_certificate_pem_format?(attrs.ca_certificate_pem)

            raise Dry::Struct::Error,
                  'CA Certificate PEM must be in valid PEM format starting with -----BEGIN CERTIFICATE-----'
          end
        end
      end
    end
  end
end
