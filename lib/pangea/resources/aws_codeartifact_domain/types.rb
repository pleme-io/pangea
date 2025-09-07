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
        # CodeArtifact Domain resource attributes with validation
        class CodeArtifactDomainAttributes < Dry::Struct
          transform_keys(&:to_sym)
          
          # Required attributes
          attribute :domain, Resources::Types::String
          
          # Optional attributes
          attribute :encryption_key, Resources::Types::String.optional.default(nil)
          attribute :tags, Resources::Types::AwsTags
          
          # Validate attributes
          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}
            
            # Validate domain name
            if attrs[:domain]
              domain = attrs[:domain]
              
              # Domain name validation (AWS CodeArtifact rules)
              unless domain.match?(/^[a-z][a-z0-9\-]{1,48}[a-z0-9]$/)
                raise Dry::Struct::Error, "domain must be 2-50 characters, start with letter, end with letter or number, contain only lowercase letters, numbers, and hyphens"
              end
              
              if domain.include?('--')
                raise Dry::Struct::Error, "domain cannot contain consecutive hyphens"
              end
              
              if domain.length < 2 || domain.length > 50
                raise Dry::Struct::Error, "domain must be between 2 and 50 characters"
              end
            end
            
            # Validate encryption key if provided
            if attrs[:encryption_key] && !attrs[:encryption_key].empty?
              key = attrs[:encryption_key]
              unless key.match?(/^arn:aws[a-z\-]*:kms:/) || key.match?(/^\$\{/) || key.match?(/^alias\//)
                raise Dry::Struct::Error, "encryption_key must be a valid KMS key ARN, alias, or terraform reference"
              end
            end
            
            super(attrs)
          end
          
          # Computed properties
          def domain_owner_template
            "${aws_codeartifact_domain.%{name}.owner}"
          end
          
          def repository_endpoint_template(format)
            case format.to_s.downcase
            when 'npm'
              "${aws_codeartifact_domain.%{name}.repository_endpoint}"
            when 'pypi'
              "${aws_codeartifact_domain.%{name}.repository_endpoint}"
            when 'maven'
              "${aws_codeartifact_domain.%{name}.repository_endpoint}"
            when 'nuget'
              "${aws_codeartifact_domain.%{name}.repository_endpoint}"
            else
              "${aws_codeartifact_domain.%{name}.repository_endpoint}"
            end
          end
          
          def uses_custom_encryption?
            encryption_key && !encryption_key.empty?
          end
          
          def uses_default_encryption?
            !uses_custom_encryption?
          end
          
          def is_kms_arn?
            encryption_key && encryption_key.start_with?('arn:aws')
          end
          
          def is_kms_alias?
            encryption_key && encryption_key.start_with?('alias/')
          end
          
          def domain_url_template
            "https://#{domain}.d.codeartifact.%{region}.amazonaws.com"
          end
          
          def estimated_monthly_base_cost
            # Base cost for domain (minimal, mostly storage-based)
            5.0
          end
          
          def supports_package_formats
            %w[npm pypi maven nuget]
          end
          
          def to_h
            hash = {
              domain: domain,
              tags: tags
            }
            
            hash[:encryption_key] = encryption_key if encryption_key
            
            hash.compact
          end
        end
      end
    end
  end
end