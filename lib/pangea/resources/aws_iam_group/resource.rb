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
require 'pangea/resources/aws_iam_group/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS IAM Group with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] IAM group attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_iam_group(name, attributes = {})
        # Validate attributes using dry-struct
        group_attrs = Types::IamGroupAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_iam_group, name) do
          name group_attrs.name
          path group_attrs.path
        end
        
        # Return resource reference with available outputs
        ref = ResourceReference.new(
          type: 'aws_iam_group',
          name: name,
          resource_attributes: group_attrs.to_h,
          outputs: {
            id: "${aws_iam_group.#{name}.id}",
            arn: "${aws_iam_group.#{name}.arn}",
            name: "${aws_iam_group.#{name}.name}",
            path: "${aws_iam_group.#{name}.path}",
            unique_id: "${aws_iam_group.#{name}.unique_id}"
          }
        )
        
        # Add computed properties via method delegation
        ref.define_singleton_method(:administrative_group?) { group_attrs.administrative_group? }
        ref.define_singleton_method(:developer_group?) { group_attrs.developer_group? }
        ref.define_singleton_method(:operations_group?) { group_attrs.operations_group? }
        ref.define_singleton_method(:readonly_group?) { group_attrs.readonly_group? }
        ref.define_singleton_method(:department_group?) { group_attrs.department_group? }
        ref.define_singleton_method(:environment_group?) { group_attrs.environment_group? }
        ref.define_singleton_method(:organizational_path?) { group_attrs.organizational_path? }
        ref.define_singleton_method(:organizational_unit) { group_attrs.organizational_unit }
        ref.define_singleton_method(:group_category) { group_attrs.group_category }
        ref.define_singleton_method(:security_risk_level) { group_attrs.security_risk_level }
        ref.define_singleton_method(:suggested_access_level) { group_attrs.suggested_access_level }
        ref.define_singleton_method(:follows_naming_convention?) { group_attrs.follows_naming_convention? }
        ref.define_singleton_method(:naming_convention_score) { group_attrs.naming_convention_score }
        ref.define_singleton_method(:extract_environment_from_name) { group_attrs.extract_environment_from_name }
        ref.define_singleton_method(:extract_department_from_name) { group_attrs.extract_department_from_name }
        
        ref
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)