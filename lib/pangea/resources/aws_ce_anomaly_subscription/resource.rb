# frozen_string_literal: true

require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/aws_ce_anomaly_subscription/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      def aws_ce_anomaly_subscription(name, attributes = {})
        subscription_attrs = Types::AnomalySubscriptionAttributes.new(attributes)
        
        resource(:aws_ce_anomaly_subscription, name) do
          name subscription_attrs.name
          frequency subscription_attrs.frequency
          monitor_arn_list subscription_attrs.monitor_arn_list
          subscribers subscription_attrs.subscribers
          threshold_expression subscription_attrs.threshold_expression if subscription_attrs.threshold_expression
          
          if subscription_attrs.tags&.any?
            tags do
              subscription_attrs.tags.each { |k, v| public_send(k, v) }
            end
          end
        end
        
        ResourceReference.new(
          type: 'aws_ce_anomaly_subscription',
          name: name,
          resource_attributes: subscription_attrs.to_h,
          outputs: {
            arn: "${aws_ce_anomaly_subscription.#{name}.arn}",
            name: "${aws_ce_anomaly_subscription.#{name}.name}",
            frequency: "${aws_ce_anomaly_subscription.#{name}.frequency}",
            subscriber_count: subscription_attrs.subscriber_count,
            monitor_count: subscription_attrs.monitor_count,
            is_immediate: subscription_attrs.is_immediate?,
            has_threshold: subscription_attrs.has_threshold?
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)