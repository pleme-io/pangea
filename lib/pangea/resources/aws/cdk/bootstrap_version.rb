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
      module CDK
        # AWS CDK Bootstrap Version resource
        # Manages CDK bootstrap version information for environments.
        module BootstrapVersion
          def aws_cdk_bootstrap_version(name, attributes = {})
            resource(:aws_cdk_bootstrap_version, name) do
              bootstrap_version attributes[:bootstrap_version] if attributes[:bootstrap_version]
              qualifier attributes[:qualifier] if attributes[:qualifier]
            end
            
            ResourceReference.new(
              type: 'aws_cdk_bootstrap_version',
              name: name,
              resource_attributes: attributes,
              outputs: {
                id: "${aws_cdk_bootstrap_version.#{name}.id}",
                version: "${aws_cdk_bootstrap_version.#{name}.version}"
              }
            )
          end
        end
      end
    end
  end
end