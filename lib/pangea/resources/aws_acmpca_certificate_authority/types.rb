# frozen_string_literal: true

require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
      # Type-safe attributes for AWS ACM PCA Certificate Authority resources
      class AcmPcaCertificateAuthorityAttributes < Dry::Struct
        # Certificate authority configuration
        attribute :certificate_authority_configuration, Resources::Types::Hash.schema(
          key_algorithm: Types::String.enum('RSA_2048', 'RSA_4096', 'EC_prime256v1', 'EC_secp384r1'),
          signing_algorithm: Types::String.enum('SHA256WITHRSA', 'SHA384WITHRSA', 'SHA512WITHRSA', 'SHA256WITHECDSA', 'SHA384WITHECDSA', 'SHA512WITHECDSA'),
          subject: Types::Hash.schema(
            country?: Types::String.optional,
            organization?: Types::String.optional,
            organizational_unit?: Types::String.optional,
            distinguished_name_qualifier?: Types::String.optional,
            state?: Types::String.optional,
            common_name?: Types::String.optional,
            serial_number?: Types::String.optional,
            locality?: Types::String.optional,
            title?: Types::String.optional,
            surname?: Types::String.optional,
            given_name?: Types::String.optional,
            initials?: Types::String.optional,
            pseudonym?: Types::String.optional,
            generation_qualifier?: Types::String.optional
          )
        )

        # Certificate authority type
        attribute :type, Resources::Types::String.default('ROOT').enum('ROOT', 'SUBORDINATE')

        # Certificate authority status
        attribute :status, Resources::Types::String.enum('CREATING', 'PENDING_CERTIFICATE', 'ACTIVE', 'DELETED', 'DISABLED', 'EXPIRED', 'FAILED').optional

        # Permanent deletion time in days (7-30)
        attribute :permanent_deletion_time_in_days, Resources::Types::Integer.constrained(gteq: 7, lteq: 30).default(30)

        # Revocation configuration
        attribute :revocation_configuration, Resources::Types::Hash.schema(
          crl_configuration?: Types::Hash.schema(
            enabled: Types::Bool,
            expiration_in_days?: Types::Integer.optional,
            custom_cname?: Types::String.optional,
            s3_bucket_name?: Types::String.optional,
            s3_object_acl?: Types::String.enum('PUBLIC_READ', 'BUCKET_OWNER_FULL_CONTROL').optional
          ).optional,
          ocsp_configuration?: Types::Hash.schema(
            enabled: Types::Bool,
            ocsp_custom_cname?: Types::String.optional
          ).optional
        ).optional

        # Usage mode
        attribute :usage_mode, Resources::Types::String.enum('GENERAL_PURPOSE', 'SHORT_LIVED_CERTIFICATE').optional

        # Key storage security standard
        attribute :key_storage_security_standard, Resources::Types::String.enum('FIPS_140_2_LEVEL_2_OR_HIGHER', 'FIPS_140_2_LEVEL_3_OR_HIGHER').optional

        # Tags to apply to the certificate authority
        attribute :tags, Resources::Types::AwsTags.default({})

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)
          
          # Validate key algorithm and signing algorithm compatibility
          key_algo = attrs.certificate_authority_configuration[:key_algorithm]
          signing_algo = attrs.certificate_authority_configuration[:signing_algorithm]
          
          if key_algo.start_with?('RSA') && signing_algo.include?('ECDSA')
            raise Dry::Struct::Error, "RSA key algorithm incompatible with ECDSA signing algorithm"
          end
          
          if key_algo.start_with?('EC') && signing_algo.include?('RSA')
            raise Dry::Struct::Error, "EC key algorithm incompatible with RSA signing algorithm"
          end

          # Validate subject has at least common name or organization
          subject = attrs.certificate_authority_configuration[:subject]
          unless subject[:common_name] || subject[:organization]
            raise Dry::Struct::Error, "Certificate authority subject must have either common_name or organization"
          end

          # Validate S3 bucket name format if provided
          if attrs.revocation_configuration&.dig(:crl_configuration, :s3_bucket_name)
            bucket_name = attrs.revocation_configuration[:crl_configuration][:s3_bucket_name]
            unless bucket_name.match?(/\A[a-z0-9\-\.]{3,63}\z/)
              raise Dry::Struct::Error, "Invalid S3 bucket name format: #{bucket_name}"
            end
          end

          attrs
        end

        # Helper methods
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
          when 'RSA_2048'
            '2048'
          when 'RSA_4096'
            '4096'
          when 'EC_prime256v1'
            '256'
          when 'EC_secp384r1'
            '384'
          else
            'unknown'
          end
        end

        def signing_strength
          case certificate_authority_configuration[:signing_algorithm]
          when 'SHA256WITHRSA', 'SHA256WITHECDSA'
            'SHA256'
          when 'SHA384WITHRSA', 'SHA384WITHECDSA'
            'SHA384'
          when 'SHA512WITHRSA', 'SHA512WITHECDSA'
            'SHA512'
          else
            'unknown'
          end
        end

        def has_crl_distribution?
          revocation_configuration&.dig(:crl_configuration, :enabled) == true
        end

        def has_ocsp?
          revocation_configuration&.dig(:ocsp_configuration, :enabled) == true
        end

        def estimated_monthly_cost
          base_cost = root_ca? ? "$400/month" : "$50/month"
          certificate_cost = " + $0.75 per certificate"
          "#{base_cost}#{certificate_cost}"
        end

        def validate_configuration
          warnings = []
          
          if certificate_authority_configuration[:key_algorithm] == 'RSA_2048'
            warnings << "RSA 2048-bit keys are minimum recommended - consider RSA 4096 for higher security"
          end
          
          if signing_strength == 'SHA256' && root_ca?
            warnings << "SHA256 signing for root CA - consider SHA384 or SHA512 for enhanced security"
          end
          
          unless has_crl_distribution? || has_ocsp?
            warnings << "No revocation checking configured - consider enabling CRL or OCSP"
          end
          
          if permanent_deletion_time_in_days < 30
            warnings << "Short permanent deletion time - consider longer retention for recovery"
          end
          
          warnings
        end

        # Get security level assessment
        def security_level
          score = 0
          score += 2 if key_size.to_i >= 4096 || ec_key?
          score += 1 if signing_strength == 'SHA384' || signing_strength == 'SHA512'
          score += 1 if has_crl_distribution? || has_ocsp?
          score += 1 if key_storage_security_standard&.include?('LEVEL_3')
          
          case score
          when 4..5
            'high'
          when 2..3
            'medium'
          else
            'basic'
          end
        end

        # Check if suitable for production
        def production_ready?
          key_size.to_i >= 2048 && (has_crl_distribution? || has_ocsp?)
        end

        # Get CA hierarchy level
        def hierarchy_level
          root_ca? ? 'root' : 'intermediate'
        end
      end

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
end