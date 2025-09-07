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
        # AWS CDK docker image asset resource
        module UdockerUimageUasset
          def aws_cdk_docker_image_asset(name, attributes = {})
            resource(:aws_cdk_docker_image_asset, name) do
              attributes.each do |key, value|
                send(key, value) if value
              end
            end
            
            ResourceReference.new(
              type: 'aws_cdk_docker_image_asset',
              name: name,
              resource_attributes: attributes,
              outputs: {
                id: "${aws_cdk_docker_image_asset.#{name}.id}"
              }
            )
          end
        end
      end
    end
  end
end
