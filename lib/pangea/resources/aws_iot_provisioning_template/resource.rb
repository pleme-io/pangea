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
    # AWS IoT Provisioning Template Resource
    # 
    # Provisioning templates automate device onboarding by defining how devices should be
    # configured during registration. This enables consistent, scalable device provisioning
    # with automated policy assignment, certificate creation, and resource allocation.
    #
    # @example Basic fleet provisioning template
    #   template_body = JSON.generate({
    #     "Parameters" => {
    #       "ThingName" => { "Type" => "String" },
    #       "SerialNumber" => { "Type" => "String" }
    #     },
    #     "Resources" => {
    #       "thing" => {
    #         "Type" => "AWS::IoT::Thing",
    #         "Properties" => {
    #           "ThingName" => { "Ref" => "ThingName" },
    #           "AttributePayload" => {
    #             "version" => "v1",
    #             "serialNumber" => { "Ref" => "SerialNumber" }
    #           }
    #         }
    #       },
    #       "certificate" => {
    #         "Type" => "AWS::IoT::Certificate",
    #         "Properties" => {
    #           "CertificateId" => { "Ref" => "AWS::IoT::Certificate::Id" },
    #           "Status" => "ACTIVE"
    #         }
    #       }
    #     }
    #   })
    #   
    #   aws_iot_provisioning_template(:fleet_template, {
    #     name: "FleetProvisioningTemplate",
    #     template_body: template_body,
    #     provisioning_role_arn: "arn:aws:iam::123456789012:role/IoTProvisioningRole",
    #     enabled: true
    #   })
    #
    # @example Template with pre-provisioning validation
    #   aws_iot_provisioning_template(:validated_provisioning, {
    #     name: "ValidatedDeviceProvisioning",
    #     template_body: device_template_json,
    #     provisioning_role_arn: provisioning_role.arn,
    #     pre_provisioning_hook: {
    #       target_arn: "arn:aws:lambda:us-east-1:123456789012:function:validate-device",
    #       payload_version: "2020-04-01"
    #     },
    #     enabled: true,
    #     description: "Device provisioning with validation hook"
    #   })
    #
    # @example JITP (Just-in-Time Provisioning) template
    #   aws_iot_provisioning_template(:jitp_template, {
    #     name: "JustInTimeProvisioning", 
    #     template_body: jitp_template_body,
    #     provisioning_role_arn: jitp_role_arn,
    #     type: "JITP",
    #     description: "Automatic provisioning for CA-signed certificates",
    #     tags: {
    #       "ProvisioningType" => "JITP",
    #       "Environment" => "Production"
    #     }
    #   })
    module AwsIotProvisioningTemplate
      include AwsIotProvisioningTemplateTypes

      # Creates an AWS IoT provisioning template for automated device onboarding
      #
      # @param name [Symbol] Logical name for the provisioning template resource
      # @param attributes [Hash] Provisioning template configuration attributes
      # @return [Reference] Resource reference for use in other resources
      def aws_iot_provisioning_template(name, attributes = {})
        validated_attributes = Attributes[attributes]
        
        resource :aws_iot_provisioning_template, name do
          name validated_attributes.name
          template_body validated_attributes.template_body
          description validated_attributes.description if validated_attributes.description
          enabled validated_attributes.enabled if validated_attributes.enabled
          type validated_attributes.type if validated_attributes.type
          provisioning_role_arn validated_attributes.provisioning_role_arn

          if validated_attributes.pre_provisioning_hook
            pre_provisioning_hook do
              target_arn validated_attributes.pre_provisioning_hook.target_arn
              payload_version validated_attributes.pre_provisioning_hook.payload_version if validated_attributes.pre_provisioning_hook.payload_version
            end
          end

          tags validated_attributes.tags if validated_attributes.tags
        end

        Reference.new(
          type: :aws_iot_provisioning_template,
          name: name,
          attributes: Outputs.new(
            arn: "${aws_iot_provisioning_template.#{name}.arn}",
            name: "${aws_iot_provisioning_template.#{name}.name}",
            default_version_id: "${aws_iot_provisioning_template.#{name}.default_version_id}",
            id: "${aws_iot_provisioning_template.#{name}.id}",
            type: "${aws_iot_provisioning_template.#{name}.type}"
          )
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)