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
require 'pangea/resources/aws_licensemanager_grant/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Provides a License Manager grant resource.
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Resource attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_licensemanager_grant(name, attributes = {})
        # Validate attributes using dry-struct
        attrs = Types::LicensemanagerGrantAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_licensemanager_grant, name) do
          name attrs.name if attrs.name
          allowed_operations attrs.allowed_operations if attrs.allowed_operations
          license_arn attrs.license_arn if attrs.license_arn
          principal attrs.principal if attrs.principal
          home_region attrs.home_region if attrs.home_region
          
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
          type: 'aws_licensemanager_grant',
          name: name,
          resource_attributes: attrs.to_h,
          outputs: {
            id: "${aws_licensemanager_grant.#{name}.id}",
            arn: "${aws_licensemanager_grant.#{name}.arn}",
            status: "${aws_licensemanager_grant.#{name}.status}",
            version: "${aws_licensemanager_grant.#{name}.version}"
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