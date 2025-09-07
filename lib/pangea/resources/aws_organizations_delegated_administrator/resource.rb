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

module Pangea
  module Resources
    module AWS
      # Type-safe resource function for AWS Organizations Delegated Administrator
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Resource attributes following AWS provider schema
      # @return [Pangea::Resources::Reference] Resource reference for chaining
      # 
      # @see https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_delegated_administrator
      #
      # @example Delegate Config service administration
      #   aws_organizations_delegated_administrator(:config_admin, {
      #     account_id: "123456789012",
      #     service_principal: "config.amazonaws.com"
      #   })
      #
      # @example Delegate CloudTrail administration
      #   aws_organizations_delegated_administrator(:cloudtrail_admin, {
      #     account_id: security_account_id,
      #     service_principal: "cloudtrail.amazonaws.com"
      #   })
      #
      # @example Delegate GuardDuty administration
      #   aws_organizations_delegated_administrator(:guardduty_admin, {
      #     account_id: "987654321098",
      #     service_principal: "guardduty.amazonaws.com"
      #   })
      def aws_organizations_delegated_administrator(name, attributes)
        transformed = Base.transform_attributes(attributes, {
          account_id: {
            description: "Account ID to designate as delegated administrator",
            type: :string,
            required: true
          },
          service_principal: {
            description: "Service principal for the AWS service",
            type: :string,
            required: true
          }
        })

        resource_block = resource(:aws_organizations_delegated_administrator, name, transformed)
        
        Reference.new(
          type: :aws_organizations_delegated_administrator,
          name: name,
          attributes: {
            id: "#{resource_block}.id",
            arn: "#{resource_block}.arn",
            delegation_enabled_date: "#{resource_block}.delegation_enabled_date",
            email: "#{resource_block}.email",
            name: "#{resource_block}.name"
          },
          resource: resource_block
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)