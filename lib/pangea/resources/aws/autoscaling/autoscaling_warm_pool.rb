# frozen_string_literal: true

require 'pangea/resources/base'
require 'pangea/resources/reference'

module Pangea
  module Resources
    module AWS
      module Autoscaling
        # AWS Autoscaling AutoscalingWarmPool resource
        module AutoscalingWarmPool
          def aws_autoscaling_autoscaling_warm_pool(name, attributes = {})
            resource(:aws_autoscaling_autoscaling_warm_pool, name) do
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
              type: 'aws_autoscaling_autoscaling_warm_pool',
              name: name,
              resource_attributes: attributes,
              outputs: {
                id: "${aws_autoscaling_autoscaling_warm_pool.#{name}.id}",
                arn: "${aws_autoscaling_autoscaling_warm_pool.#{name}.arn}"
              }
            )
          end
        end
      end
    end
  end
end
