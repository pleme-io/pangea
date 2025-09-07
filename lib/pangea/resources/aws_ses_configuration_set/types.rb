# frozen_string_literal: true

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