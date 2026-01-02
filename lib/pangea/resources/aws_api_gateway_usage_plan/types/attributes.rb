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

module Pangea
  module Resources
    module AWS
      module Types
        # Type-safe attributes for AWS API Gateway Usage Plan resources
        class ApiGatewayUsagePlanAttributes < Dry::Struct
          include ApiGatewayUsagePlanHelpers

          # Name for the usage plan
          attribute :name, Resources::Types::String

          # Description of the usage plan
          attribute :description, Resources::Types::String.optional

          # API stages this usage plan applies to
          attribute :api_stages, ApiStagesType

          # Throttling settings
          attribute :throttle_settings, ThrottleSettingsType

          # Quota settings
          attribute :quota_settings, QuotaSettingsType

          # Product code for billing
          attribute :product_code, Resources::Types::String.optional

          # Tags to apply to the usage plan
          attribute :tags, Resources::Types::AwsTags.default({}.freeze)

          # Custom validation
          def self.new(attributes = {})
            attrs = super(attributes)

            ApiGatewayUsagePlanValidation.validate_all(attrs)

            # Set default description if not provided
            unless attrs.description
              default_desc = ApiGatewayUsagePlanValidation.generate_default_description(attrs)
              attrs = attrs.copy_with(description: default_desc)
            end

            attrs
          end
        end
      end
    end
  end
end
