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


require_relative 'types'
require 'pangea/resources/base'

module Pangea
  module Resources
    # AWS IoT Policy Attachment Resource
    # 
    # Attaches IoT policies to certificates or other principals, defining the permissions
    # and access controls for IoT devices. This is critical for implementing security
    # in IoT deployments by controlling what actions devices can perform.
    #
    # @example Attach policy to certificate
    #   aws_iot_policy_attachment(:device_permissions, {
    #     policy: "DeviceBasicPolicy",
    #     target: "arn:aws:iot:us-east-1:123456789012:cert/abcd1234"
    #   })
    #
    # @example Using policy and certificate references
    #   device_policy = aws_iot_policy(:device_policy, {
    #     name: "DeviceOperationsPolicy",
    #     policy: policy_document
    #   })
    #   
    #   device_cert = aws_iot_certificate(:device_cert, {
    #     active: true
    #   })
    #   
    #   aws_iot_policy_attachment(:secure_device, {
    #     policy: device_policy.name,
    #     target: device_cert.arn
    #   })
    #
    # @example Multiple policies per certificate
    #   # Basic connectivity policy
    #   aws_iot_policy_attachment(:basic_connectivity, {
    #     policy: "BasicConnectivityPolicy",
    #     target: certificate_arn
    #   })
    #   
    #   # Application-specific policy
    #   aws_iot_policy_attachment(:app_permissions, {
    #     policy: "SensorDataPolicy",
    #     target: certificate_arn
    #   })
    #
    # @example Policy attached to thing group
    #   aws_iot_policy_attachment(:group_policy, {
    #     policy: "ProductionDevicesPolicy",
    #     target: "arn:aws:iot:us-east-1:123456789012:thinggroup/production-sensors"
    #   })
    module AwsIotPolicyAttachment
      include AwsIotPolicyAttachmentTypes

      # Creates an AWS IoT policy attachment
      #
      # @param name [Symbol] Logical name for the policy attachment resource
      # @param attributes [Hash] Policy attachment configuration attributes
      # @return [Reference] Resource reference for use in other resources
      def aws_iot_policy_attachment(name, attributes = {})
        validated_attributes = Attributes[attributes]
        
        resource :aws_iot_policy_attachment, name do
          policy validated_attributes.policy
          target validated_attributes.target
        end

        Reference.new(
          type: :aws_iot_policy_attachment,
          name: name,
          attributes: Outputs.new(
            id: "${aws_iot_policy_attachment.#{name}.id}",
            policy: "${aws_iot_policy_attachment.#{name}.policy}",
            target: "${aws_iot_policy_attachment.#{name}.target}"
          )
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)