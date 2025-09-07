# frozen_string_literal: true

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