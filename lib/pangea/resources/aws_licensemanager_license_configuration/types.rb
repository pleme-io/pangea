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
      # Type-safe attributes for AwsLicensemanagerLicenseConfiguration resources
      # Provides a License Manager license configuration resource.
      class LicensemanagerLicenseConfigurationAttributes < Dry::Struct
        attribute :name, Resources::Types::String
        attribute :license_counting_type, Resources::Types::String
        attribute :description, Resources::Types::String.optional
        attribute :license_count, Resources::Types::Integer.optional
        attribute :license_count_hard_limit, Resources::Types::Bool.optional
        attribute :license_rules, Resources::Types::Array.of(Types::String).default([].freeze).optional
        
        # Tags to apply to the resource
        attribute :tags, Resources::Types::AwsTags.default({}.freeze)

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)
          
          
          
          
          attrs
        end
        
        # TODO: Add computed properties specific to aws_licensemanager_license_configuration

      end
    end
      end
    end
  end
end