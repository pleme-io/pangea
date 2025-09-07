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
require 'pangea/resources/aws_iot_device_defender_security_profile/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      def aws_iot_device_defender_security_profile(name, attributes = {})
        defender_attrs = Types::IotDeviceDefenderSecurityProfileAttributes.new(attributes)
        
        resource(:aws_iot_device_defender_security_profile, name) do
          security_profile_name defender_attrs.security_profile_name
          security_profile_description defender_attrs.security_profile_description if defender_attrs.security_profile_description
          target_arns defender_attrs.target_arns if defender_attrs.target_arns.any?
          
          defender_attrs.behaviors.each do |behavior|
            behaviors do
              name behavior[:name]
              metric behavior[:metric] if behavior[:metric]
              criteria behavior[:criteria] if behavior[:criteria]
              suppress_alerts behavior[:suppress_alerts] if behavior.key?(:suppress_alerts)
            end
          end
          
          if defender_attrs.alert_targets
            alert_targets do
              defender_attrs.alert_targets.each { |k, v| public_send(k, v) }
            end
          end
          
          if defender_attrs.tags.any?
            tags do
              defender_attrs.tags.each { |k, v| public_send(k, v) }
            end
          end
        end
        
        ResourceReference.new(
          type: 'aws_iot_device_defender_security_profile',
          name: name,
          resource_attributes: defender_attrs.to_h,
          outputs: {
            security_profile_name: "${aws_iot_device_defender_security_profile.#{name}.security_profile_name}",
            security_profile_arn: "${aws_iot_device_defender_security_profile.#{name}.security_profile_arn}",
            version: "${aws_iot_device_defender_security_profile.#{name}.version}"
          },
          computed_properties: {
            target_count: defender_attrs.target_count,
            behavior_count: defender_attrs.behavior_count,
            has_ml_behaviors: defender_attrs.has_ml_behaviors?,
            defender_coverage_level: defender_attrs.defender_coverage_level
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)