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
require 'pangea/resources/aws_config_configuration_recorder/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS Config Configuration Recorder with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Configuration Recorder attributes
      # @option attributes [String] :name The name of the configuration recorder
      # @option attributes [String] :role_arn The ARN of the IAM role that AWS Config uses to record configuration changes
      # @option attributes [Hash] :recording_group The recording group configuration
      # @option attributes [Hash] :tags A map of tags to assign to the resource
      # @return [ResourceReference] Reference object with outputs and computed properties
      #
      # @example Basic configuration recorder
      #   config_recorder = aws_config_configuration_recorder(:main_recorder, {
      #     name: "main-config-recorder",
      #     role_arn: config_role.arn,
      #     tags: {
      #       Environment: "production",
      #       Purpose: "compliance"
      #     }
      #   })
      #
      # @example Configuration recorder with specific resource types
      #   config_recorder = aws_config_configuration_recorder(:ec2_recorder, {
      #     name: "ec2-resource-recorder",
      #     role_arn: config_role.arn,
      #     recording_group: {
      #       all_supported: false,
      #       include_global_resource_types: false,
      #       resource_types: [
      #         "AWS::EC2::Instance",
      #         "AWS::EC2::SecurityGroup",
      #         "AWS::EC2::Volume"
      #       ]
      #     },
      #     tags: {
      #       Environment: "production",
      #       Scope: "ec2-only"
      #     }
      #   })
      #
      # @example Configuration recorder for all resources with global types
      #   config_recorder = aws_config_configuration_recorder(:full_recorder, {
      #     name: "full-compliance-recorder",
      #     role_arn: config_role.arn,
      #     recording_group: {
      #       all_supported: true,
      #       include_global_resource_types: true
      #     },
      #     tags: {
      #       Environment: "production",
      #       Compliance: "sox-pci",
      #       Scope: "organization-wide"
      #     }
      #   })
      def aws_config_configuration_recorder(name, attributes = {})
        # Validate attributes using dry-struct
        recorder_attrs = Types::Types::ConfigConfigurationRecorderAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_config_configuration_recorder, name) do
          name recorder_attrs.name
          role_arn recorder_attrs.role_arn
          
          # Add recording group configuration if specified
          if recorder_attrs.has_recording_group?
            recording_group do
              if recorder_attrs.recording_group[:all_supported]
                all_supported recorder_attrs.recording_group[:all_supported]
              end
              
              if recorder_attrs.recording_group[:include_global_resource_types]
                include_global_resource_types recorder_attrs.recording_group[:include_global_resource_types]
              end
              
              if recorder_attrs.recording_group[:resource_types].is_a?(Array)
                resource_types recorder_attrs.recording_group[:resource_types]
              end
            end
          end
          
          # Apply tags if present
          if recorder_attrs.tags.any?
            tags do
              recorder_attrs.tags.each do |key, value|
                public_send(key, value)
              end
            end
          end
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_config_configuration_recorder',
          name: name,
          resource_attributes: recorder_attrs.to_h,
          outputs: {
            name: "${aws_config_configuration_recorder.#{name}.name}",
            role_arn: "${aws_config_configuration_recorder.#{name}.role_arn}",
            recording_group: "${aws_config_configuration_recorder.#{name}.recording_group}",
            tags_all: "${aws_config_configuration_recorder.#{name}.tags_all}"
          },
          computed_properties: {
            has_recording_group: recorder_attrs.has_recording_group?,
            records_all_resources: recorder_attrs.records_all_resources?,
            includes_global_resources: recorder_attrs.includes_global_resources?,
            has_specific_resource_types: recorder_attrs.has_specific_resource_types?,
            estimated_monthly_cost_usd: recorder_attrs.estimated_monthly_cost_usd
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)