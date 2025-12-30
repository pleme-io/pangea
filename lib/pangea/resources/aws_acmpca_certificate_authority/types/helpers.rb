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
          def root_ca?
            type == 'ROOT'
          end

          def subordinate_ca?
            type == 'SUBORDINATE'
          end

          def rsa_key?
            certificate_authority_configuration[:key_algorithm].start_with?('RSA')
          end

          def ec_key?
            certificate_authority_configuration[:key_algorithm].start_with?('EC')
          end

          def key_size
            case certificate_authority_configuration[:key_algorithm]
            when 'RSA_2048' then '2048'
            when 'RSA_4096' then '4096'
            when 'EC_prime256v1' then '256'
            when 'EC_secp384r1' then '384'
            else 'unknown'
            end
          end

          def signing_strength
            case certificate_authority_configuration[:signing_algorithm]
            when 'SHA256WITHRSA', 'SHA256WITHECDSA' then 'SHA256'
            when 'SHA384WITHRSA', 'SHA384WITHECDSA' then 'SHA384'
            when 'SHA512WITHRSA', 'SHA512WITHECDSA' then 'SHA512'
            else 'unknown'
            end
          end

          def has_crl_distribution?
            revocation_configuration&.dig(:crl_configuration, :enabled) == true
          end

          def has_ocsp?
            revocation_configuration&.dig(:ocsp_configuration, :enabled) == true
          end

          def estimated_monthly_cost
            base_cost = root_ca? ? '$400/month' : '$50/month'
            certificate_cost = ' + $0.75 per certificate'
            "#{base_cost}#{certificate_cost}"
          end

          def validate_configuration
            warnings = []

            if certificate_authority_configuration[:key_algorithm] == 'RSA_2048'
              warnings << 'RSA 2048-bit keys are minimum recommended - consider RSA 4096 for higher security'
            end

            if signing_strength == 'SHA256' && root_ca?
              warnings << 'SHA256 signing for root CA - consider SHA384 or SHA512 for enhanced security'
            end

            unless has_crl_distribution? || has_ocsp?
              warnings << 'No revocation checking configured - consider enabling CRL or OCSP'
            end

            if permanent_deletion_time_in_days < 30
              warnings << 'Short permanent deletion time - consider longer retention for recovery'
            end

            warnings
          end

          def security_level
            score = 0
            score += 2 if key_size.to_i >= 4096 || ec_key?
            score += 1 if signing_strength == 'SHA384' || signing_strength == 'SHA512'
            score += 1 if has_crl_distribution? || has_ocsp?
            score += 1 if key_storage_security_standard&.include?('LEVEL_3')

            case score
            when 4..5 then 'high'
            when 2..3 then 'medium'
            else 'basic'
            end
          end

          def production_ready?
            key_size.to_i >= 2048 && (has_crl_distribution? || has_ocsp?)
          end

          def hierarchy_level
            root_ca? ? 'root' : 'intermediate'
          end
        end
      end
    end
  end
end
