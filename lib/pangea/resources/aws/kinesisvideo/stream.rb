# frozen_string_literal: true

require 'pangea/resources/base'
require 'pangea/resources/reference'

module Pangea
  module Resources
    module AWS
      module Kinesisvideo
        # AWS Kinesisvideo Stream resource
        module Stream
          def aws_kinesisvideo_stream(name, attributes = {})
            resource(:aws_kinesisvideo_stream, name) do
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
              type: 'aws_kinesisvideo_stream',
              name: name,
              resource_attributes: attributes,
              outputs: {
                id: "${aws_kinesisvideo_stream.#{name}.id}",
                arn: "${aws_kinesisvideo_stream.#{name}.arn}"
              }
            )
          end
        end
      end
    end
  end
end
