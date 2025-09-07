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
require 'pangea/resources/aws_iam_user/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS IAM User with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] IAM user attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_iam_user(name, attributes = {})
        # Validate attributes using dry-struct
        user_attrs = Types::IamUserAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_iam_user, name) do
          name user_attrs.name
          path user_attrs.path
          permissions_boundary user_attrs.permissions_boundary if user_attrs.permissions_boundary
          force_destroy user_attrs.force_destroy
          
          # Apply tags if present
          if user_attrs.tags.any?
            tags do
              user_attrs.tags.each do |key, value|
                public_send(key, value)
              end
            end
          end
        end
        
        # Return resource reference with available outputs
        ref = ResourceReference.new(
          type: 'aws_iam_user',
          name: name,
          resource_attributes: user_attrs.to_h,
          outputs: {
            id: "${aws_iam_user.#{name}.id}",
            arn: "${aws_iam_user.#{name}.arn}",
            name: "${aws_iam_user.#{name}.name}",
            path: "${aws_iam_user.#{name}.path}",
            permissions_boundary: "${aws_iam_user.#{name}.permissions_boundary}",
            unique_id: "${aws_iam_user.#{name}.unique_id}",
            tags_all: "${aws_iam_user.#{name}.tags_all}"
          }
        )
        
        # Add computed properties via method delegation
        ref.define_singleton_method(:administrative_user?) { user_attrs.administrative_user? }
        ref.define_singleton_method(:service_user?) { user_attrs.service_user? }
        ref.define_singleton_method(:human_user?) { user_attrs.human_user? }
        ref.define_singleton_method(:organizational_path?) { user_attrs.organizational_path? }
        ref.define_singleton_method(:organizational_unit) { user_attrs.organizational_unit }
        ref.define_singleton_method(:user_category) { user_attrs.user_category }
        ref.define_singleton_method(:security_risk_level) { user_attrs.security_risk_level }
        ref.define_singleton_method(:has_permissions_boundary?) { user_attrs.has_permissions_boundary? }
        ref.define_singleton_method(:permissions_boundary_policy_name) { user_attrs.permissions_boundary_policy_name }
        
        ref
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)