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
        # Helper methods for IoT Certificate attributes
        module IotCertificateHelpers
          # Security level assessment
          def security_assessment
            assessment = { creation_method: creation_method, security_level: 'standard' }
            apply_security_notes!(assessment)
            assessment
          end

          # Recommended policies for this certificate type
          def recommended_policies
            policies = creation_method_policies
            policies << 'Implement certificate rotation strategy' if active?
            policies
          end

          # Certificate lifecycle recommendations
          def lifecycle_recommendations
            recommendations = base_lifecycle_recommendations
            recommendations.concat(custom_certificate_recommendations)
            recommendations.concat(ca_certificate_recommendations)
            recommendations << 'Audit certificate usage and access patterns'
            recommendations
          end

          # Generate certificate ARN pattern
          def certificate_arn_pattern(region, account_id, certificate_id)
            "arn:aws:iot:#{region}:#{account_id}:cert/#{certificate_id}"
          end

          # Compliance and audit information
          def compliance_info
            info = base_compliance_info
            info[:certificate_chain] = 'CA certificate provided for validation' if using_ca_certificate?
            info[:audit_trail] = 'Certificate operations logged in CloudTrail'
            info[:rotation_support] = 'Manual rotation required before expiration'
            info
          end

          # Performance and operational metrics
          def operational_metrics
            {
              creation_time: 'Immediate for AWS generated, depends on validation for custom',
              validation_time: using_custom_certificate? ? 'Up to several minutes' : 'Immediate',
              activation_time: 'Immediate upon creation',
              revocation_time: 'Immediate when status changed to INACTIVE'
            }
          end

          # Integration requirements
          def integration_requirements
            requirements = base_integration_requirements
            requirements.concat(creation_method_requirements)
            requirements << 'Configure MQTT client with certificate and private key'
            requirements << 'Implement certificate refresh mechanism in device code'
            requirements
          end

          private

          def apply_security_notes!(assessment)
            assessment[:notes] = security_notes_for_method
            return unless using_ca_certificate?

            assessment[:ca_certificate] = 'present'
            assessment[:notes] << 'CA certificate provided for chain validation'
          end

          def security_notes_for_method
            case creation_method
            when :aws_generated
              ['AWS-generated certificates use secure key generation', 'Private key never leaves AWS']
            when :csr
              ['Private key remains under your control', 'CSR ensures proper key ownership']
            when :certificate_pem
              ['External certificate management required', 'Ensure proper private key protection']
            else
              []
            end
          end

          def creation_method_policies
            case creation_method
            when :aws_generated, :csr
              ['Allow device registration and authentication',
               'Permit MQTT publish/subscribe for device topics',
               'Enable device shadow access']
            when :certificate_pem
              ['Verify certificate chain and validity',
               'Implement certificate revocation checking',
               'Define appropriate device permissions']
            else
              []
            end
          end

          def base_lifecycle_recommendations
            ['Set up certificate rotation before expiration',
             'Monitor certificate status and validity',
             'Implement certificate revocation procedures']
          end

          def custom_certificate_recommendations
            return [] unless creation_method == :certificate_pem

            ['Maintain secure backup of private key',
             'Verify certificate chain integrity regularly']
          end

          def ca_certificate_recommendations
            return [] unless using_ca_certificate?

            ['Monitor CA certificate validity and renewal',
             'Implement CA certificate rotation procedures']
          end

          def base_compliance_info
            {
              pki_standards: ['X.509'],
              encryption: 'RSA or ECDSA based on certificate',
              key_management: creation_method == :aws_generated ? 'AWS managed' : 'Customer managed'
            }
          end

          def base_integration_requirements
            ['Associate certificate with IoT policy for device permissions',
             'Attach certificate to IoT thing for device identity']
          end

          def creation_method_requirements
            case creation_method
            when :csr
              ['Provide valid Certificate Signing Request in PEM format']
            when :certificate_pem
              ['Ensure certificate is valid and properly formatted',
               'Verify certificate chain if using intermediate CAs']
            else
              []
            end
          end
        end
      end
    end
  end
end
