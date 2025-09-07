# frozen_string_literal: true

require 'pangea/resources/base'
require 'pangea/resources/reference'

module Pangea
  module Resources
    module AWS
      module Vpc
        # AWS Vpc VpcNetworkPerformanceMetricSubscription resource
        module VpcNetworkPerformanceMetricSubscription
          def aws_vpc_vpc_network_performance_metric_subscription(name, attributes = {})
            resource(:aws_vpc_vpc_network_performance_metric_subscription, name) do
              attributes.each do |key, value|
                if value.is_a?(Hash) && !value.empty?
                  send(key) do
                    value.each { |k, v| send(k, v) if v }
                  end
                elsif value.is_a?(Array) && !value.empty?
                  value.each { |item| send(key, item) }
                elsif value && !value.is_a?(Array) && !value.is_a?(Hash)
                  send(key, value)
                end
              end
            end
            
            ResourceReference.new(
              type: 'aws_vpc_vpc_network_performance_metric_subscription',
              name: name,
              resource_attributes: attributes,
              outputs: {
                id: "${aws_vpc_vpc_network_performance_metric_subscription.#{name}.id}",
                arn: "${aws_vpc_vpc_network_performance_metric_subscription.#{name}.arn}"
              }
            )
          end
        end
      end
    end
  end
end
