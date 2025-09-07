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
require 'pangea/resources/aws_guardduty_detector/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS GuardDuty Detector for threat detection and monitoring
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] GuardDuty Detector attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_guardduty_detector(name, attributes = {})
        # Validate attributes using dry-struct
        detector_attrs = Types::GuardDutyDetectorAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_guardduty_detector, name) do
          enable detector_attrs.enable
          finding_publishing_frequency detector_attrs.finding_publishing_frequency
          
          # Data sources configuration
          if detector_attrs.datasources.any?
            datasources do
              if detector_attrs.datasources[:s3_logs]
                s3_logs do
                  enable detector_attrs.datasources[:s3_logs][:enable]
                end
              end
              
              if detector_attrs.datasources[:kubernetes]
                kubernetes do
                  audit_logs do
                    enable detector_attrs.datasources[:kubernetes][:audit_logs][:enable]
                  end
                end
              end
              
              if detector_attrs.datasources[:malware_protection]
                malware_protection do
                  scan_ec2_instance_with_findings do
                    ebs_volumes do
                      enable detector_attrs.datasources[:malware_protection][:scan_ec2_instance_with_findings][:ebs_volumes][:enable]
                    end
                  end
                end
              end
            end
          end
          
          # Apply tags if present
          if detector_attrs.tags.any?
            tags do
              detector_attrs.tags.each do |key, value|
                public_send(key, value)
              end
            end
          end
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_guardduty_detector',
          name: name,
          resource_attributes: detector_attrs.to_h,
          outputs: {
            id: "${aws_guardduty_detector.#{name}.id}",
            arn: "${aws_guardduty_detector.#{name}.arn}",
            account_id: "${aws_guardduty_detector.#{name}.account_id}"
          },
          computed: {
            enabled: detector_attrs.enable,
            publishing_frequency: detector_attrs.finding_publishing_frequency,
            has_s3_protection: detector_attrs.has_s3_protection?,
            has_kubernetes_protection: detector_attrs.has_kubernetes_protection?,
            has_malware_protection: detector_attrs.has_malware_protection?,
            enabled_datasources: detector_attrs.enabled_datasources,
            comprehensive_protection: detector_attrs.comprehensive_protection?
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)