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
    module AWS
      module Types
        # ACM Certificate resource attributes with validation
        class AcmCertificateAttributes < Dry::Struct
          transform_keys(&:to_sym)
          
          attribute :domain_name, Resources::Types::DomainName
          attribute :subject_alternative_names?, Resources::Types::Array.of(Resources::Types::DomainName | Resources::Types::WildcardDomainName).optional
          attribute :validation_method, Resources::Types::AcmValidationMethod.default('DNS')
          attribute :key_algorithm?, Resources::Types::AcmKeyAlgorithm.optional.default('RSA-2048')
          attribute :certificate_transparency_logging_preference?, Resources::Types::CertificateTransparencyLogging.optional
          attribute :validation_options?, Resources::Types::Array.of(Resources::Types::AcmValidationOption).optional
          attribute :tags?, Resources::Types::AwsTags.optional
          attribute :lifecycle?, AcmCertificateLifecycle.optional
          
          # Custom validation logic
          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}
            
            # Validate domain name patterns
            if attrs[:domain_name]
              validate_domain_name(attrs[:domain_name])
            end
            
            # Validate SAN entries
            if attrs[:subject_alternative_names]
              attrs[:subject_alternative_names].each do |san|
                validate_domain_name(san)
              end
              
              # Check for duplicate domains
              all_domains = [attrs[:domain_name], *attrs[:subject_alternative_names]]
              if all_domains.uniq.length != all_domains.length
                raise Dry::Struct::Error, "Duplicate domains found in certificate request"
              end
              
              # AWS limit: max 100 domain names per certificate
              if all_domains.length > 100
                raise Dry::Struct::Error, "ACM certificate supports maximum 100 domain names (including primary domain)"
              end
            end
            
            # Validate validation options match domains
            if attrs[:validation_options]
              domains = [attrs[:domain_name], *attrs[:subject_alternative_names]].compact
              validation_domains = attrs[:validation_options].map { |vo| vo[:domain_name] }
              
              # Each validation option must match a requested domain
              validation_domains.each do |vd|
                unless domains.include?(vd)
                  raise Dry::Struct::Error, "Validation option domain '#{vd}' not found in certificate domains"
                end
              end
            end
            
            super(attrs)
          end
          
          # Domain name validation helper
          def self.validate_domain_name(domain)
            # Check for valid wildcard usage
            if domain.include?('*')
              # Wildcard must be at start and only one level
              unless domain.match?(/\A\*\.[a-z0-9.-]+\z/i)
                raise Dry::Struct::Error, "Invalid wildcard domain: #{domain}. Wildcards must be at the start (*.example.com)"
              end
              
              # Cannot have multiple wildcards
              if domain.count('*') > 1
                raise Dry::Struct::Error, "Domain cannot contain multiple wildcards: #{domain}"
              end
            end
            
            # Validate domain length (ACM limit: 64 characters per label, 253 total)
            if domain.length > 253
              raise Dry::Struct::Error, "Domain name too long: #{domain} (max 253 characters)"
            end
            
            # Validate each label (between dots)
            labels = domain.gsub(/^\*\./, '').split('.')
            labels.each do |label|
              if label.length > 64
                raise Dry::Struct::Error, "Domain label too long: #{label} (max 64 characters)"
              end
            end
          end
          
          # Computed properties
          def is_wildcard_certificate?
            domain_name.start_with?('*.')
          end
          
          def total_domain_count
            1 + (subject_alternative_names&.length || 0)
          end
          
          def uses_dns_validation?
            validation_method == 'DNS'
          end
          
          def uses_email_validation?
            validation_method == 'EMAIL'
          end
          
          def estimated_validation_time
            case validation_method
            when 'DNS' then '5-10 minutes (after DNS records are created)'
            when 'EMAIL' then '1-2 hours (after email confirmation)'
            else 'Unknown'
            end
          end
          
          def certificate_scope
            if is_wildcard_certificate?
              "Wildcard certificate for #{domain_name}"
            elsif subject_alternative_names&.any?
              "Multi-domain certificate covering #{total_domain_count} domains"
            else
              "Single domain certificate"
            end
          end
        end
        
        # ACM Certificate lifecycle configuration
        AcmCertificateLifecycle = Resources::Types::Hash.schema(
          create_before_destroy?: Resources::Types::Bool.default(true),
          prevent_destroy?: Resources::Types::Bool.default(false)
        )
      end
    end
  end
end