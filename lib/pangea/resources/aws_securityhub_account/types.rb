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