# frozen_string_literal: true

require 'dry-struct'
require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
        # Security Hub Account attributes with validation
        class SecurityHubAccountAttributes < Dry::Struct
          transform_keys(&:to_sym)
          
          attribute :enable_default_standards, Resources::Types::Bool.default(true)
          attribute :control_finding_generator, String.enum('STANDARD_CONTROL', 'SECURITY_CONTROL').default('STANDARD_CONTROL')
          attribute :auto_enable_controls, Resources::Types::Bool.default(true)
          attribute :tags, Resources::Types::AwsTags
          
          # Custom validation  
          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}
            
            # If default standards are disabled, auto enable controls might not be relevant
            if attrs[:enable_default_standards] == false && attrs[:auto_enable_controls] == true
              # Still valid - controls can be auto-enabled even without default standards
            end
            
            super(attrs)
          end
          
          # Computed properties
          def comprehensive_setup?
            enable_default_standards && auto_enable_controls
          end
          
          def standards_enabled?
            enable_default_standards
          end
          
          def uses_security_control_generator?
            control_finding_generator == 'SECURITY_CONTROL'
          end
        end
      end
    end
  end
end