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
require 'pangea/resources/aws_inspector2_enabler/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS Inspector v2 Enabler for vulnerability scanning
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Inspector v2 Enabler attributes
      # @return [ResourceReference] Reference object with outputs
      def aws_inspector2_enabler(name, attributes = {})
        # Validate attributes using dry-struct
        enabler_attrs = Types::Inspector2EnablerAttributes.new(attributes)
        
        # Generate terraform resource block
        resource(:aws_inspector2_enabler, name) do
          account_ids enabler_attrs.account_ids
          resource_types enabler_attrs.resource_types
        end
        
        # Return resource reference
        ResourceReference.new(
          type: 'aws_inspector2_enabler',
          name: name,
          resource_attributes: enabler_attrs.to_h,
          outputs: {
            id: "${aws_inspector2_enabler.#{name}.id}"
          },
          computed: {
            account_count: enabler_attrs.account_count,
            resource_type_count: enabler_attrs.resource_type_count,
            covers_ec2: enabler_attrs.covers_ec2?,
            covers_ecr: enabler_attrs.covers_ecr?,
            comprehensive_coverage: enabler_attrs.comprehensive_coverage?,
            single_account: enabler_attrs.single_account?,
            multi_account: enabler_attrs.multi_account?,
            enabled_accounts: enabler_attrs.account_ids,
            enabled_resource_types: enabler_attrs.resource_types
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)