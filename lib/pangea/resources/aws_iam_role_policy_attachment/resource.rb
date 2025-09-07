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
require 'pangea/resources/aws_iam_role_policy_attachment/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS IAM Role Policy Attachment with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] IAM role policy attachment attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_iam_role_policy_attachment(name, attributes = {})
        # Validate attributes using dry-struct
        attachment_attrs = Types::IamRolePolicyAttachmentAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_iam_role_policy_attachment, name) do
          role attachment_attrs.role
          policy_arn attachment_attrs.policy_arn
        end
        
        # Return resource reference with available outputs
        ref = ResourceReference.new(
          type: 'aws_iam_role_policy_attachment',
          name: name,
          resource_attributes: attachment_attrs.to_h,
          outputs: {
            id: "${aws_iam_role_policy_attachment.#{name}.id}",
            role: "${aws_iam_role_policy_attachment.#{name}.role}",
            policy_arn: "${aws_iam_role_policy_attachment.#{name}.policy_arn}"
          }
        )
        
        # Add computed properties via method delegation
        ref.define_singleton_method(:aws_managed_policy?) { attachment_attrs.aws_managed_policy? }
        ref.define_singleton_method(:customer_managed_policy?) { attachment_attrs.customer_managed_policy? }
        ref.define_singleton_method(:policy_name) { attachment_attrs.policy_name }
        ref.define_singleton_method(:policy_account_id) { attachment_attrs.policy_account_id }
        ref.define_singleton_method(:role_name) { attachment_attrs.role_name }
        ref.define_singleton_method(:role_specified_by_arn?) { attachment_attrs.role_specified_by_arn? }
        ref.define_singleton_method(:attachment_id) { attachment_attrs.attachment_id }
        ref.define_singleton_method(:potentially_dangerous?) { attachment_attrs.potentially_dangerous? }
        ref.define_singleton_method(:policy_category) { attachment_attrs.policy_category }
        ref.define_singleton_method(:security_risk_level) { attachment_attrs.security_risk_level }
        
        ref
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)