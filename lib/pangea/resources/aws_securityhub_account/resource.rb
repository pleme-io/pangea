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


require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/aws_securityhub_account/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS Security Hub Account for centralized security dashboard
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Security Hub Account attributes
      # @return [ResourceReference] Reference object with outputs  
      def aws_securityhub_account(name, attributes = {})
        # Validate attributes using dry-struct
        account_attrs = Types::SecurityHubAccountAttributes.new(attributes)
        
        # Generate terraform resource block
        resource(:aws_securityhub_account, name) do
          enable_default_standards account_attrs.enable_default_standards
          control_finding_generator account_attrs.control_finding_generator
          auto_enable_controls account_attrs.auto_enable_controls
          
          # Apply tags if present
          if account_attrs.tags.any?
            tags do
              account_attrs.tags.each do |key, value|
                public_send(key, value)
              end
            end
          end
        end
        
        # Return resource reference
        ResourceReference.new(
          type: 'aws_securityhub_account',
          name: name,
          resource_attributes: account_attrs.to_h,
          outputs: {
            id: "${aws_securityhub_account.#{name}.id}",
            arn: "${aws_securityhub_account.#{name}.arn}",
            subscribed_at: "${aws_securityhub_account.#{name}.subscribed_at}"
          },
          computed: {
            comprehensive_setup: account_attrs.comprehensive_setup?,
            standards_enabled: account_attrs.standards_enabled?,
            uses_security_control_generator: account_attrs.uses_security_control_generator?,
            auto_enable_controls: account_attrs.auto_enable_controls,
            control_finding_generator: account_attrs.control_finding_generator
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)