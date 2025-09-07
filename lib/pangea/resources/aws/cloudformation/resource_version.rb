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
        # AWS CloudFormation Resource Version resource
        # Registers a new version of a CloudFormation resource type.
        module ResourceVersion
          def aws_cloudformation_resource_version(name, attributes = {})
            resource(:aws_cloudformation_resource_version, name) do
              schema_handler_package attributes[:schema_handler_package] if attributes[:schema_handler_package]
              type_name attributes[:type_name] if attributes[:type_name]
              execution_role_arn attributes[:execution_role_arn] if attributes[:execution_role_arn]
              
              if attributes[:logging_config]
                logging_config do
                  log_group_name attributes[:logging_config][:log_group_name] if attributes[:logging_config][:log_group_name]
                  log_role_arn attributes[:logging_config][:log_role_arn] if attributes[:logging_config][:log_role_arn]
                end
              end
            end
            
            ResourceReference.new(
              type: 'aws_cloudformation_resource_version',
              name: name,
              resource_attributes: attributes,
              outputs: {
                id: "${aws_cloudformation_resource_version.#{name}.id}",
                arn: "${aws_cloudformation_resource_version.#{name}.arn}",
                version_id: "${aws_cloudformation_resource_version.#{name}.version_id}"
              }
            )
          end
        end
      end
    end
  end
end