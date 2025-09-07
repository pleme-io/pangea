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
        # SES TLS policy
        SesTlsPolicy = String.enum('Require', 'Optional')

        # SES delivery options
        SesDeliveryOptions = Hash.schema(
          tls_policy?: SesTlsPolicy.optional
        )

        # SES reputation tracking
        SesReputationMetricsEnabled = Resources::Types::Bool.default(false)

        # SES Configuration Set resource attributes
        class SesConfigurationSetAttributes < Dry::Struct
          transform_keys(&:to_sym)

          attribute :name, Resources::Types::String.constrained(
            format: /\A[a-zA-Z0-9_-]+\z/,
            size: 1..64
          )

          attribute? :delivery_options, SesDeliveryOptions.optional
          
          attribute? :reputation_metrics_enabled, SesReputationMetricsEnabled
          
          attribute? :sending_enabled, Resources::Types::Bool.default(true)

          # Custom validation
          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}

            # Validate configuration set name
            if attrs[:name]
              name = attrs[:name]
              
              # Cannot start or end with hyphen or underscore
              if name.start_with?('-', '_') || name.end_with?('-', '_')
                raise Dry::Struct::Error, "Configuration set name cannot start or end with hyphen or underscore: #{name}"
              end
              
              # Cannot contain consecutive hyphens or underscores
              if name.include?('--') || name.include?('__') || name.include?('-_') || name.include?('_-')
                raise Dry::Struct::Error, "Configuration set name cannot contain consecutive special characters: #{name}"
              end
            end

            super(attrs)
          end
        end
      end
    end
  end
end