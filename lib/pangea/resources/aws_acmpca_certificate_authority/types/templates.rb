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
        # Common ACM PCA Certificate Authority configurations
        module AcmPcaCertificateAuthorityConfigs
          # Root CA with RSA 4096 for maximum security
          def self.secure_root_ca(organization, country = 'US')
            {
              certificate_authority_configuration: {
                key_algorithm: 'RSA_4096',
                signing_algorithm: 'SHA384WITHRSA',
                subject: {
                  country: country,
                  organization: organization,
                  common_name: "#{organization} Root CA"
                }
              },
              type: 'ROOT',
              revocation_configuration: {
                crl_configuration: {
                  enabled: true,
                  expiration_in_days: 7
                },
                ocsp_configuration: {
                  enabled: true
                }
              },
              key_storage_security_standard: 'FIPS_140_2_LEVEL_3_OR_HIGHER',
              tags: {
                Purpose: 'Root Certificate Authority',
                SecurityLevel: 'high',
                Organization: organization
              }
            }
          end

          # Intermediate CA for issuing end-entity certificates
          def self.intermediate_ca(organization, parent_ca_name, country = 'US')
            {
              certificate_authority_configuration: {
                key_algorithm: 'RSA_2048',
                signing_algorithm: 'SHA256WITHRSA',
                subject: {
                  country: country,
                  organization: organization,
                  organizational_unit: 'IT Security',
                  common_name: "#{organization} Intermediate CA"
                }
              },
              type: 'SUBORDINATE',
              revocation_configuration: {
                crl_configuration: {
                  enabled: true,
                  expiration_in_days: 1
                }
              },
              tags: {
                Purpose: 'Intermediate Certificate Authority',
                ParentCA: parent_ca_name,
                Organization: organization
              }
            }
          end

          # Development CA with shorter validity
          def self.development_ca(project_name)
            {
              certificate_authority_configuration: {
                key_algorithm: 'RSA_2048',
                signing_algorithm: 'SHA256WITHRSA',
                subject: {
                  organization: 'Development',
                  organizational_unit: project_name,
                  common_name: "#{project_name} Development CA"
                }
              },
              type: 'ROOT',
              permanent_deletion_time_in_days: 7,
              usage_mode: 'SHORT_LIVED_CERTIFICATE',
              tags: {
                Environment: 'development',
                Project: project_name,
                AutoDelete: 'true'
              }
            }
          end

          # Corporate internal CA
          def self.corporate_internal_ca(organization, department)
            {
              certificate_authority_configuration: {
                key_algorithm: 'RSA_4096',
                signing_algorithm: 'SHA384WITHRSA',
                subject: {
                  organization: organization,
                  organizational_unit: department,
                  common_name: "#{organization} #{department} Internal CA"
                }
              },
              type: 'SUBORDINATE',
              revocation_configuration: {
                crl_configuration: {
                  enabled: true,
                  expiration_in_days: 1
                },
                ocsp_configuration: {
                  enabled: true
                }
              },
              key_storage_security_standard: 'FIPS_140_2_LEVEL_2_OR_HIGHER',
              tags: {
                Organization: organization,
                Department: department,
                Purpose: 'Internal PKI',
                CriticalityLevel: 'high'
              }
            }
          end
        end
      end
    end
  end
end
