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
        # SES Domain Identity resource attributes
        class SesDomainIdentityAttributes < Dry::Struct
          transform_keys(&:to_sym)

          attribute :domain, Resources::Types::DomainName

          # Custom validation
          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}

            # Validate domain is not a wildcard domain for SES
            if attrs[:domain]&.start_with?('*.')
              raise Dry::Struct::Error, "SES domain identity cannot be a wildcard domain: #{attrs[:domain]}"
            end

            super(attrs)
          end

          # Check if this is a subdomain
          def is_subdomain?
            domain.count('.') > 1
          end

          # Get parent domain
          def parent_domain
            return nil unless is_subdomain?
            domain.split('.', 2)[1]
          end

          # Get domain parts for validation records
          def domain_parts
            domain.split('.')
          end
        end
      end
    end
  end
end