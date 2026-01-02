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
        class AcmPcaCertificateAuthorityAttributes < Dry::Struct
          # Custom validation
          def self.new(attributes = {})
            attrs = super(attributes)

            validate_algorithm_compatibility!(attrs)
            validate_subject!(attrs)
            validate_s3_bucket!(attrs)

            attrs
          end

          class << self
            private

            def validate_algorithm_compatibility!(attrs)
              key_algo = attrs.certificate_authority_configuration[:key_algorithm]
              signing_algo = attrs.certificate_authority_configuration[:signing_algorithm]

              if key_algo.start_with?('RSA') && signing_algo.include?('ECDSA')
                raise Dry::Struct::Error, 'RSA key algorithm incompatible with ECDSA signing algorithm'
              end

              return unless key_algo.start_with?('EC') && signing_algo.include?('RSA')

              raise Dry::Struct::Error, 'EC key algorithm incompatible with RSA signing algorithm'
            end

            def validate_subject!(attrs)
              subject = attrs.certificate_authority_configuration[:subject]
              return if subject[:common_name] || subject[:organization]

              raise Dry::Struct::Error,
                    'Certificate authority subject must have either common_name or organization'
            end

            def validate_s3_bucket!(attrs)
              return unless attrs.revocation_configuration&.dig(:crl_configuration, :s3_bucket_name)

              bucket_name = attrs.revocation_configuration[:crl_configuration][:s3_bucket_name]
              return if bucket_name.match?(/\A[a-z0-9\-\.]{3,63}\z/)

              raise Dry::Struct::Error, "Invalid S3 bucket name format: #{bucket_name}"
            end
          end
        end
      end
    end
  end
end
