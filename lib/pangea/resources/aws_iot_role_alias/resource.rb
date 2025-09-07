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
    # AWS IoT Role Alias Resource
    # 
    # Role aliases enable IoT devices to securely access AWS services by assuming IAM roles
    # without embedding long-term credentials. Devices use X.509 certificates for authentication
    # and receive temporary STS credentials through the role alias mechanism.
    #
    # @example Basic role alias for device access
    #   aws_iot_role_alias(:device_s3_access, {
    #     alias: "DeviceS3Access",
    #     role_arn: "arn:aws:iam::123456789012:role/IoTDeviceRole"
    #   })
    #
    # @example Role alias with custom credential duration
    #   aws_iot_role_alias(:long_running_access, {
    #     alias: "LongRunningDeviceAccess",
    #     role_arn: "arn:aws:iam::123456789012:role/IoTLongRunningRole",
    #     credential_duration_seconds: 7200  # 2 hours
    #   })
    #
    # @example Role alias with tags for organization
    #   aws_iot_role_alias(:production_device_access, {
    #     alias: "ProductionDeviceAccess",
    #     role_arn: iam_role_ref.arn,
    #     credential_duration_seconds: 3600,
    #     tags: {
    #       "Environment" => "Production",
    #       "Application" => "SmartSensors",
    #       "CostCenter" => "IoT-Operations"
    #     }
    #   })
    #
    # @example Role alias for specific device groups
    #   aws_iot_role_alias(:sensor_data_writer, {
    #     alias: "SensorDataWriter",
    #     role_arn: "arn:aws:iam::123456789012:role/SensorDataRole",
    #     credential_duration_seconds: 1800,  # 30 minutes for frequent updates
    #     tags: {
    #       "DeviceType" => "Sensor",
    #       "Access" => "WriteOnly"
    #     }
    #   })
    module AwsIotRoleAlias
      include AwsIotRoleAliasTypes

      # Creates an AWS IoT role alias for device IAM role assumption
      #
      # @param name [Symbol] Logical name for the role alias resource
      # @param attributes [Hash] Role alias configuration attributes
      # @return [Reference] Resource reference for use in other resources
      def aws_iot_role_alias(name, attributes = {})
        validated_attributes = Attributes[attributes]
        
        resource :aws_iot_role_alias, name do
          send(:alias, validated_attributes.alias)
          role_arn validated_attributes.role_arn
          credential_duration_seconds validated_attributes.credential_duration_seconds if validated_attributes.credential_duration_seconds
          tags validated_attributes.tags if validated_attributes.tags
        end

        Reference.new(
          type: :aws_iot_role_alias,
          name: name,
          attributes: Outputs.new(
            arn: "${aws_iot_role_alias.#{name}.arn}",
            alias: "${aws_iot_role_alias.#{name}.alias}",
            role_arn: "${aws_iot_role_alias.#{name}.role_arn}",
            credential_duration_seconds: "${aws_iot_role_alias.#{name}.credential_duration_seconds}",
            id: "${aws_iot_role_alias.#{name}.id}"
          )
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)