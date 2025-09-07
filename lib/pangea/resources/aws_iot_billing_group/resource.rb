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
    # AWS IoT Billing Group Resource
    # 
    # Billing groups provide cost allocation and usage tracking for IoT devices.
    # They enable detailed billing insights and cost management for device fleets.
    #
    # @example Basic billing group for cost tracking
    #   aws_iot_billing_group(:production_devices, {
    #     billing_group_name: "production-devices",
    #     billing_group_properties: {
    #       description: "Production device fleet for cost allocation"
    #     },
    #     tags: {
    #       "CostCenter" => "IoT-Operations",
    #       "Environment" => "Production"
    #     }
    #   })
    #
    # @example Billing group for department cost allocation
    #   aws_iot_billing_group(:manufacturing_sensors, {
    #     billing_group_name: "manufacturing-sensors",
    #     billing_group_properties: {
    #       description: "Manufacturing department sensor devices"
    #     },
    #     tags: {
    #       "Department" => "Manufacturing",
    #       "Project" => "SmartFactory",
    #       "BudgetCode" => "MFG-2024-IOT"
    #     }
    #   })
    module AwsIotBillingGroup
      include AwsIotBillingGroupTypes

      # Creates an AWS IoT billing group for cost allocation
      #
      # @param name [Symbol] Logical name for the billing group resource
      # @param attributes [Hash] Billing group configuration attributes
      # @return [Reference] Resource reference for use in other resources
      def aws_iot_billing_group(name, attributes = {})
        validated_attributes = Attributes[attributes]
        
        resource :aws_iot_billing_group, name do
          billing_group_name validated_attributes.billing_group_name

          if validated_attributes.billing_group_properties
            billing_group_properties do
              description validated_attributes.billing_group_properties.description if validated_attributes.billing_group_properties.description
            end
          end

          tags validated_attributes.tags if validated_attributes.tags
        end

        Reference.new(
          type: :aws_iot_billing_group,
          name: name,
          attributes: Outputs.new(
            arn: "${aws_iot_billing_group.#{name}.arn}",
            id: "${aws_iot_billing_group.#{name}.id}",
            billing_group_name: "${aws_iot_billing_group.#{name}.billing_group_name}",
            version: "${aws_iot_billing_group.#{name}.version}",
            metadata: Outputs::Metadata.new(
              creation_date: "${aws_iot_billing_group.#{name}.metadata[0].creation_date}"
            )
          )
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)