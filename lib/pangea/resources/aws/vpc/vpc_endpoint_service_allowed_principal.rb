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
      module Vpc
        # AWS Vpc VpcEndpointServiceAllowedPrincipal resource
        module VpcEndpointServiceAllowedPrincipal
          def aws_vpc_vpc_endpoint_service_allowed_principal(name, attributes = {})
            resource(:aws_vpc_vpc_endpoint_service_allowed_principal, name) do
              attributes.each do |key, value|
                if value.is_a?(Hash) && !value.empty?
                  send(key) do
                    value.each { |k, v| send(k, v) if v }
                  end
                elsif value.is_a?(Array) && !value.empty?
                  value.each { |item| send(key, item) }
                elsif value && !value.is_a?(Array) && !value.is_a?(Hash)
                  send(key, value)
                end
              end
            end
            
            ResourceReference.new(
              type: 'aws_vpc_vpc_endpoint_service_allowed_principal',
              name: name,
              resource_attributes: attributes,
              outputs: {
                id: "${aws_vpc_vpc_endpoint_service_allowed_principal.#{name}.id}",
                arn: "${aws_vpc_vpc_endpoint_service_allowed_principal.#{name}.arn}"
              }
            )
          end
        end
      end
    end
  end
end
