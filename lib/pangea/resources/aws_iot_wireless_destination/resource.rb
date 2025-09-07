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
    # AWS IoT Wireless Destination Resource
    # 
    # Wireless destinations route messages from LoRaWAN devices to AWS services.
    # They enable integration with IoT Core, analytics services, and custom processing pipelines.
    #
    # @example Basic wireless destination for IoT Core
    #   aws_iot_wireless_destination(:sensor_data, {
    #     name: "SensorDataDestination",
    #     expression_type: "MqttTopic",
    #     expression: "lorawan/uplink",
    #     description: "Route sensor data to IoT Core MQTT topic",
    #     role_arn: iot_wireless_role.arn
    #   })
    #
    # @example Destination with IoT rule integration
    #   aws_iot_wireless_destination(:analytics_pipeline, {
    #     name: "AnalyticsPipeline",
    #     expression_type: "RuleName",
    #     expression: "ProcessSensorData",
    #     description: "Route to IoT Analytics via IoT Rule",
    #     tags: {
    #       "Application" => "SmartCity",
    #       "DataType" => "Sensor"
    #     }
    #   })
    module AwsIotWirelessDestination
      include AwsIotWirelessDestinationTypes

      # Creates an AWS IoT wireless destination for LoRaWAN message routing
      #
      # @param name [Symbol] Logical name for the wireless destination resource
      # @param attributes [Hash] Destination configuration attributes
      # @return [Reference] Resource reference for use in other resources
      def aws_iot_wireless_destination(name, attributes = {})
        validated_attributes = Attributes[attributes]
        
        resource :aws_iot_wireless_destination, name do
          name validated_attributes.name
          expression_type validated_attributes.expression_type
          expression validated_attributes.expression
          description validated_attributes.description if validated_attributes.description
          role_arn validated_attributes.role_arn if validated_attributes.role_arn
          tags validated_attributes.tags if validated_attributes.tags
        end

        Reference.new(
          type: :aws_iot_wireless_destination,
          name: name,
          attributes: Outputs.new(
            arn: "${aws_iot_wireless_destination.#{name}.arn}",
            name: "${aws_iot_wireless_destination.#{name}.name}",
            id: "${aws_iot_wireless_destination.#{name}.id}"
          )
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)