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
    # AWS IoT Provisioning Template Types
    # 
    # Provisioning templates define how devices should be configured during the registration process.
    # They enable automated device onboarding with consistent configuration, policies, and resources
    # for fleet management at scale.
    module AwsIotProvisioningTemplateTypes
      # Pre-provisioning hook configuration for custom validation
      class PreProvisioningHook < Dry::Struct
        schema schema.strict

        # ARN of Lambda function to call for pre-provisioning validation
        attribute :target_arn, Resources::Types::String

        # Optional payload template for the Lambda function
        attribute :payload_version, Resources::Types::String.optional
      end

      # Main attributes for IoT provisioning template resource
      class Attributes < Dry::Struct
        schema schema.strict

        # Name of the provisioning template
        attribute :name, Resources::Types::String

        # JSON template body defining device configuration
        attribute :template_body, Resources::Types::String

        # Description of the provisioning template
        attribute :description, Resources::Types::String.optional

        # Whether the template is enabled for provisioning
        attribute :enabled, Resources::Types::Bool.optional

        # Type of provisioning (FLEET_PROVISIONING or JITP)
        attribute :type, Resources::Types::String.enum('FLEET_PROVISIONING', 'JITP').optional

        # ARN of IAM role for provisioning operations
        attribute :provisioning_role_arn, Resources::Types::String

        # Pre-provisioning hook for custom validation
        attribute? :pre_provisioning_hook, PreProvisioningHook.optional

        # Resource tags for organization and billing
        attribute :tags, Resources::Types::Hash.map(Types::String, Types::String).optional
      end

      # Output attributes from provisioning template resource
      class Outputs < Dry::Struct
        schema schema.strict

        # The provisioning template ARN
        attribute :arn, Resources::Types::String

        # The provisioning template name
        attribute :name, Resources::Types::String

        # The default version ID of the template
        attribute :default_version_id, Resources::Types::Integer

        # The template ID
        attribute :id, Resources::Types::String

        # The type of provisioning template
        attribute :type, Resources::Types::String
      end
    end
  end
end