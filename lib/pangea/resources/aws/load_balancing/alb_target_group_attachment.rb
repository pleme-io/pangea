# frozen_string_literal: true

require 'pangea/resources/base'
require 'pangea/resources/reference'

module Pangea
  module Resources
    module AWS
      module LoadBalancing
        # AWS LoadBalancing AlbTargetGroupAttachment resource
        module AlbTargetGroupAttachment
          def aws_load_balancing_alb_target_group_attachment(name, attributes = {})
            resource(:aws_load_balancing_alb_target_group_attachment, name) do
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
              type: 'aws_load_balancing_alb_target_group_attachment',
              name: name,
              resource_attributes: attributes,
              outputs: {
                id: "${aws_load_balancing_alb_target_group_attachment.#{name}.id}",
                arn: "${aws_load_balancing_alb_target_group_attachment.#{name}.arn}"
              }
            )
          end
        end
      end
    end
  end
end
