# frozen_string_literal: true

require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/aws_iot_topic_rule_destination/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      def aws_iot_topic_rule_destination(name, attributes = {})
        dest_attrs = Types::IotTopicRuleDestinationAttributes.new(attributes)
        
        resource(:aws_iot_topic_rule_destination, name) do
          enabled dest_attrs.enabled
          
          vpc_configuration do
            vpc_id dest_attrs.vpc_configuration[:vpc_id]
            subnet_ids dest_attrs.vpc_configuration[:subnet_ids]
            security_group_ids dest_attrs.vpc_configuration[:security_group_ids]
            role_arn dest_attrs.vpc_configuration[:role_arn]
          end
          
          if dest_attrs.tags.any?
            tags do
              dest_attrs.tags.each { |k, v| public_send(k, v) }
            end
          end
        end
        
        ResourceReference.new(
          type: 'aws_iot_topic_rule_destination',
          name: name,
          resource_attributes: dest_attrs.to_h,
          outputs: {
            arn: "${aws_iot_topic_rule_destination.#{name}.arn}",
            confirmation_url: "${aws_iot_topic_rule_destination.#{name}.confirmation_url}",
            status: "${aws_iot_topic_rule_destination.#{name}.status}"
          },
          computed_properties: {
            vpc_subnet_count: dest_attrs.vpc_subnet_count,
            security_group_count: dest_attrs.security_group_count,
            is_multi_az: dest_attrs.is_multi_az?
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)