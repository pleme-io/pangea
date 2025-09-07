# frozen_string_literal: true

require 'pangea/resources/base'
require 'pangea/resources/reference'

module Pangea
  module Resources
    module AWS
      module Ec2
        # AWS Ec2 Ec2SpotInstanceRequest resource
        module Ec2SpotInstanceRequest
          def aws_ec2_ec2_spot_instance_request(name, attributes = {})
            resource(:aws_ec2_ec2_spot_instance_request, name) do
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
              type: 'aws_ec2_ec2_spot_instance_request',
              name: name,
              resource_attributes: attributes,
              outputs: {
                id: "${aws_ec2_ec2_spot_instance_request.#{name}.id}",
                arn: "${aws_ec2_ec2_spot_instance_request.#{name}.arn}"
              }
            )
          end
        end
      end
    end
  end
end
