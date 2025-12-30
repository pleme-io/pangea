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
        # Domain validation helpers
        module DomainValidation
          # Validate domain availability (would typically check via AWS API)
          def self.domain_available?(_domain)
            # In real implementation, this would make AWS API call
            # to check domain availability
            true
          end

          # Generate suggested domain names if preferred is not available
          def self.suggest_domains(base_name, count = 5)
            suggestions = [base_name]

            (1..count - 1).each do |i|
              suggestions << "#{base_name}-#{i}"
              suggestions << "#{base_name}#{i}"
            end

            suggestions
          end

          # Validate certificate compatibility
          def self.certificate_compatible?(certificate_arn, _domain)
            # In real implementation, this would validate that the certificate
            # matches the domain and is in the correct region
            return false unless certificate_arn

            # Certificate must be in us-east-1 for CloudFront distribution
            certificate_arn.include?(':us-east-1:')
          end

          # Extract domain components
          def self.parse_domain(domain)
            if domain.include?('.')
              parts = domain.split('.')
              {
                subdomain: parts.first,
                root_domain: parts[1..].join('.'),
                tld: parts.last,
                type: :custom
              }
            else
              {
                prefix: domain,
                type: :cognito
              }
            end
          end
        end
      end
    end
  end
end
