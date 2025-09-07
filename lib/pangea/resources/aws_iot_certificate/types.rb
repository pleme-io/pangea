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

module Pangea
  module Resources
    module AWS
      module Types
      # Type-safe attributes for AWS IoT Certificate resources
      class IotCertificateAttributes < Dry::Struct
        # Certificate status (optional - defaults to ACTIVE)
        attribute :active, Resources::Types::Bool.default(true)
        
        # Certificate signing request (optional)
        attribute :csr, Resources::Types::String.optional
        
        # Certificate PEM format (optional - for bring your own cert)
        attribute :certificate_pem, Resources::Types::String.optional
        
        # CA certificate PEM format (optional - for bring your own CA cert)
        attribute :ca_certificate_pem, Resources::Types::String.optional
        
        # Tags (optional)
        attribute :tags, Resources::Types::AwsTags.default({})
        
        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)
          
          # Validate certificate creation method
          has_csr = attrs.csr && !attrs.csr.empty?
          has_cert_pem = attrs.certificate_pem && !attrs.certificate_pem.empty?
          has_ca_cert = attrs.ca_certificate_pem && !attrs.ca_certificate_pem.empty?
          
          # Can't have both CSR and certificate PEM
          if has_csr && has_cert_pem
            raise Dry::Struct::Error, "Cannot specify both CSR and certificate_pem - choose one creation method"
          end
          
          # If providing CA cert, must also provide certificate PEM
          if has_ca_cert && !has_cert_pem
            raise Dry::Struct::Error, "ca_certificate_pem requires certificate_pem to be provided"
          end
          
          # Validate CSR format if provided
          if has_csr && !valid_csr_format?(attrs.csr)
            raise Dry::Struct::Error, "CSR must be in valid PEM format starting with -----BEGIN CERTIFICATE REQUEST-----"
          end
          
          # Validate certificate PEM format if provided
          if has_cert_pem && !valid_certificate_pem_format?(attrs.certificate_pem)
            raise Dry::Struct::Error, "Certificate PEM must be in valid PEM format starting with -----BEGIN CERTIFICATE-----"
          end
          
          # Validate CA certificate PEM format if provided
          if has_ca_cert && !valid_certificate_pem_format?(attrs.ca_certificate_pem)
            raise Dry::Struct::Error, "CA Certificate PEM must be in valid PEM format starting with -----BEGIN CERTIFICATE-----"
          end
          
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
          active? ? "ACTIVE" : "INACTIVE"
        end
        
        # Security level assessment
        def security_assessment
          assessment = {
            creation_method: creation_method,
            security_level: "standard"
          }
          
          case creation_method
          when :aws_generated
            assessment[:security_level] = "high"
            assessment[:notes] = ["AWS-generated certificates use secure key generation", "Private key never leaves AWS"]
          when :csr
            assessment[:security_level] = "high"
            assessment[:notes] = ["Private key remains under your control", "CSR ensures proper key ownership"]
          when :certificate_pem
            assessment[:security_level] = "medium"
            assessment[:notes] = ["External certificate management required", "Ensure proper private key protection"]
          end
          
          if using_ca_certificate?
            assessment[:ca_certificate] = "present"
            assessment[:notes] << "CA certificate provided for chain validation"
          end
          
          assessment
        end
        
        # Recommended policies for this certificate type
        def recommended_policies
          policies = []
          
          case creation_method
          when :aws_generated, :csr
            policies << "Allow device registration and authentication"
            policies << "Permit MQTT publish/subscribe for device topics"
            policies << "Enable device shadow access"
          when :certificate_pem
            policies << "Verify certificate chain and validity"
            policies << "Implement certificate revocation checking"
            policies << "Define appropriate device permissions"
          end
          
          policies << "Implement certificate rotation strategy" if active?
          
          policies
        end
        
        # Certificate lifecycle recommendations
        def lifecycle_recommendations
          recommendations = []
          
          recommendations << "Set up certificate rotation before expiration"
          recommendations << "Monitor certificate status and validity"
          recommendations << "Implement certificate revocation procedures"
          
          if creation_method == :certificate_pem
            recommendations << "Maintain secure backup of private key"
            recommendations << "Verify certificate chain integrity regularly"
          end
          
          if using_ca_certificate?
            recommendations << "Monitor CA certificate validity and renewal"
            recommendations << "Implement CA certificate rotation procedures"
          end
          
          recommendations << "Audit certificate usage and access patterns"
          
          recommendations
        end
        
        # Generate certificate ARN pattern
        def certificate_arn_pattern(region, account_id, certificate_id)
          "arn:aws:iot:#{region}:#{account_id}:cert/#{certificate_id}"
        end
        
        # Compliance and audit information
        def compliance_info
          info = {
            pki_standards: ["X.509"],
            encryption: "RSA or ECDSA based on certificate",
            key_management: creation_method == :aws_generated ? "AWS managed" : "Customer managed"
          }
          
          if using_ca_certificate?
            info[:certificate_chain] = "CA certificate provided for validation"
          end
          
          info[:audit_trail] = "Certificate operations logged in CloudTrail"
          info[:rotation_support] = "Manual rotation required before expiration"
          
          info
        end
        
        # Performance and operational metrics
        def operational_metrics
          {
            creation_time: "Immediate for AWS generated, depends on validation for custom",
            validation_time: using_custom_certificate? ? "Up to several minutes" : "Immediate",
            activation_time: "Immediate upon creation",
            revocation_time: "Immediate when status changed to INACTIVE"
          }
        end
        
        # Integration requirements
        def integration_requirements
          requirements = []
          
          requirements << "Associate certificate with IoT policy for device permissions"
          requirements << "Attach certificate to IoT thing for device identity"
          
          if creation_method == :csr
            requirements << "Provide valid Certificate Signing Request in PEM format"
          elsif creation_method == :certificate_pem
            requirements << "Ensure certificate is valid and properly formatted"
            requirements << "Verify certificate chain if using intermediate CAs"
          end
          
          requirements << "Configure MQTT client with certificate and private key"
          requirements << "Implement certificate refresh mechanism in device code"
          
          requirements
        end
        
        private
        
        def self.valid_csr_format?(csr)
          csr.strip.start_with?("-----BEGIN CERTIFICATE REQUEST-----") &&
            csr.strip.end_with?("-----END CERTIFICATE REQUEST-----")
        end
        
        def self.valid_certificate_pem_format?(cert_pem)
          cert_pem.strip.start_with?("-----BEGIN CERTIFICATE-----") &&
            cert_pem.strip.end_with?("-----END CERTIFICATE-----")
        end
      end
    end
      end
    end
  end
end