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
require 'pangea/resources/aws_licensemanager_grant_accepter/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Provides a License Manager grant accepter resource.
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Resource attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_licensemanager_grant_accepter(name, attributes = {})
        # Validate attributes using dry-struct
        attrs = Types::LicensemanagerGrantAccepterAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_licensemanager_grant_accepter, name) do
          grant_arn attrs.grant_arn if attrs.grant_arn
          
          # Apply tags if present
          if attrs.tags.any?
            tags do
              attrs.tags.each do |key, value|
                public_send(key, value)
              end
            end
          end
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_licensemanager_grant_accepter',
          name: name,
          resource_attributes: attrs.to_h,
          outputs: {
            id: "${aws_licensemanager_grant_accepter.#{name}.id}",
            name: "${aws_licensemanager_grant_accepter.#{name}.name}",
            allowed_operations: "${aws_licensemanager_grant_accepter.#{name}.allowed_operations}",
            license_arn: "${aws_licensemanager_grant_accepter.#{name}.license_arn}",
            principal: "${aws_licensemanager_grant_accepter.#{name}.principal}",
            home_region: "${aws_licensemanager_grant_accepter.#{name}.home_region}",
            status: "${aws_licensemanager_grant_accepter.#{name}.status}",
            version: "${aws_licensemanager_grant_accepter.#{name}.version}"
          },
          computed_properties: {
            # Computed properties from type definitions
          }
        )
      end
    end
  end
end


# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)