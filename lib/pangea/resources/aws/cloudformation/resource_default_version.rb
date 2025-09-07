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
      module CloudFormation
        # AWS CloudFormation Resource Default Version resource
        # Sets the default version of a CloudFormation resource type.
        module ResourceDefaultVersion
          def aws_cloudformation_resource_default_version(name, attributes = {})
            resource(:aws_cloudformation_resource_default_version, name) do
              type_name attributes[:type_name] if attributes[:type_name]
              type_version_arn attributes[:type_version_arn] if attributes[:type_version_arn]
              version_id attributes[:version_id] if attributes[:version_id]
            end
            
            ResourceReference.new(
              type: 'aws_cloudformation_resource_default_version',
              name: name,
              resource_attributes: attributes,
              outputs: {
                id: "${aws_cloudformation_resource_default_version.#{name}.id}",
                arn: "${aws_cloudformation_resource_default_version.#{name}.arn}"
              }
            )
          end
        end
      end
    end
  end
end