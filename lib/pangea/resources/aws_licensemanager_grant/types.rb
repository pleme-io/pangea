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


require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
      # Type-safe attributes for AwsLicensemanagerGrant resources
      # Provides a License Manager grant resource.
      class LicensemanagerGrantAttributes < Dry::Struct
        attribute :name, Resources::Types::String
        attribute :allowed_operations, Resources::Types::Array.of(Types::String).default([].freeze)
        attribute :license_arn, Resources::Types::String
        attribute :principal, Resources::Types::String
        attribute :home_region, Resources::Types::String
        
        # Tags to apply to the resource
        attribute :tags, Resources::Types::AwsTags.default({}.freeze)

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)
          
          
          
          
          attrs
        end
        
        # TODO: Add computed properties specific to aws_licensemanager_grant

      end
    end
      end
    end
  end
end