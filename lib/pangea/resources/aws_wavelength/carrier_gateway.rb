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

module Pangea
  module Resources
    module AWS
      # Create a Carrier Gateway for Wavelength Zones
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Carrier gateway attributes
      # @option attributes [String] :vpc_id (required) The VPC ID
      # @option attributes [Hash<String,String>] :tags Resource tags
      # @return [ResourceReference] Reference object with outputs
      def aws_ec2_carrier_gateway(name, attributes = {})
        required_attrs = %i[vpc_id]
        optional_attrs = {
          tags: {}
        }

        cgw_attrs = optional_attrs.merge(attributes)

        required_attrs.each do |attr|
          raise ArgumentError, "Missing required attribute: #{attr}" unless cgw_attrs.key?(attr)
        end

        resource(:aws_ec2_carrier_gateway, name) do
          vpc_id cgw_attrs[:vpc_id]

          if cgw_attrs[:tags].any?
            tags cgw_attrs[:tags]
          end
        end

        ResourceReference.new(
          type: 'aws_ec2_carrier_gateway',
          name: name,
          resource_attributes: cgw_attrs,
          outputs: {
            id: "${aws_ec2_carrier_gateway.#{name}.id}",
            arn: "${aws_ec2_carrier_gateway.#{name}.arn}",
            owner_id: "${aws_ec2_carrier_gateway.#{name}.owner_id}",
            state: "${aws_ec2_carrier_gateway.#{name}.state}",
            vpc_id: "${aws_ec2_carrier_gateway.#{name}.vpc_id}"
          }
        )
      end
    end
  end
end
