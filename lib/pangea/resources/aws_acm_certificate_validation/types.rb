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
        # ACM Certificate Validation resource attributes with validation
        class AcmCertificateValidationAttributes < Dry::Struct
          transform_keys(&:to_sym)
          
          attribute :certificate_arn, CertificateArn
          attribute :validation_record_fqdns?, Resources::Types::Array.of(Resources::Types::String).optional
          attribute :timeouts?, AcmCertificateValidationTimeouts.optional
          
          # Custom validation logic
          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}
            
            # Validate certificate ARN format
            if attrs[:certificate_arn]
              validate_certificate_arn(attrs[:certificate_arn])
            end
            
            # Validate FQDN format if provided
            if attrs[:validation_record_fqdns]
              attrs[:validation_record_fqdns].each do |fqdn|
                validate_fqdn(fqdn)
              end
            end
            
            super(attrs)
          end
          
          # Certificate ARN validation helper
          def self.validate_certificate_arn(arn)
            unless arn.match?(/\Aarn:aws:acm:[a-z0-9-]+:\d{12}:certificate\/[a-f0-9-]{36}\z/)
              raise Dry::Struct::Error, "Invalid ACM certificate ARN format: #{arn}"
            end
          end
          
          # FQDN validation helper
          def self.validate_fqdn(fqdn)
            # Basic FQDN validation
            unless fqdn.match?(/\A[a-zA-Z0-9]([a-zA-Z0-9\-]*[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9\-]*[a-zA-Z0-9])?)*\.?\z/)
              raise Dry::Struct::Error, "Invalid FQDN format: #{fqdn}"
            end
            
            # Check for reasonable length limits
            if fqdn.length > 253
              raise Dry::Struct::Error, "FQDN too long: #{fqdn} (max 253 characters)"
            end
          end
          
          # Computed properties
          def validation_method
            validation_record_fqdns&.any? ? 'DNS' : 'EMAIL'
          end
          
          def validation_record_count
            validation_record_fqdns&.length || 0
          end
          
          def uses_dns_validation?
            validation_method == 'DNS'
          end
          
          def uses_email_validation?
            validation_method == 'EMAIL'
          end
          
          def estimated_validation_time
            case validation_method
            when 'DNS' then '5-10 minutes (after DNS records propagate)'
            when 'EMAIL' then '1-2 hours (after email confirmation)'
            else 'Unknown'
            end
          end
          
          def certificate_region
            # Extract region from ARN
            certificate_arn.split(':')[3]
          end
          
          def certificate_account_id
            # Extract account ID from ARN
            certificate_arn.split(':')[4]
          end
        end
        
        # Certificate ARN validation type
        CertificateArn = Resources::Types::String.constrained(
          format: /\Aarn:aws:acm:[a-z0-9-]+:\d{12}:certificate\/[a-f0-9-]{36}\z/
        )
        
        # ACM Certificate Validation timeouts configuration
        AcmCertificateValidationTimeouts = Resources::Types::Hash.schema(
          create?: Resources::Types::String.constrained(format: /\A\d+[smh]\z/).optional.default('5m'),
          update?: Resources::Types::String.constrained(format: /\A\d+[smh]\z/).optional
        ).constructor { |value|
          # Validate timeout formats and provide reasonable defaults
          if value[:create]
            timeout_value = parse_timeout(value[:create])
            if timeout_value > 600  # 10 minutes max for create
              raise Dry::Types::ConstraintError, "Certificate validation timeout too long: #{value[:create]} (max 10m)"
            end
          end
          
          value
        }
        
        private
        
        def self.parse_timeout(timeout_str)
          # Parse timeout string like "5m", "300s", "1h" into seconds
          if timeout_str.match?(/\A(\d+)s\z/)
            timeout_str.to_i
          elsif timeout_str.match?(/\A(\d+)m\z/)
            timeout_str.to_i * 60
          elsif timeout_str.match?(/\A(\d+)h\z/)
            timeout_str.to_i * 3600
          else
            300  # Default 5 minutes
          end
        end
      end
    end
  end
end