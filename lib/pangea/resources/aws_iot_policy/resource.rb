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
require 'pangea/resources/aws_iot_policy/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      def aws_iot_policy(name, attributes = {})
        policy_attrs = Types::IotPolicyAttributes.new(attributes)
        
        resource(:aws_iot_policy, name) do
          name policy_attrs.name
          policy policy_attrs.policy
          
          if policy_attrs.tags.any?
            tags do
              policy_attrs.tags.each { |k, v| public_send(k, v) }
            end
          end
        end
        
        ResourceReference.new(
          type: 'aws_iot_policy',
          name: name,
          resource_attributes: policy_attrs.to_h,
          outputs: {
            name: "${aws_iot_policy.#{name}.name}",
            arn: "${aws_iot_policy.#{name}.arn}",
            policy: "${aws_iot_policy.#{name}.policy}",
            default_version_id: "${aws_iot_policy.#{name}.default_version_id}",
            tags_all: "${aws_iot_policy.#{name}.tags_all}"
          },
          computed_properties: {
            policy_version: policy_attrs.policy_version,
            security_analysis: policy_attrs.security_analysis,
            iot_actions_analysis: policy_attrs.iot_actions_analysis,
            policy_recommendations: policy_attrs.policy_recommendations
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)