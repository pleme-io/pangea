# frozen_string_literal: true

require 'pangea/resources/base'
require 'pangea/resources/reference'

module Pangea
  module Resources
    module AWS
      module Batch
        # AWS Batch Job resource
        module Job
          def aws_batch_job(name, attributes = {})
            resource(:aws_batch_job, name) do
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
              type: 'aws_batch_job',
              name: name,
              resource_attributes: attributes,
              outputs: {
                id: "${aws_batch_job.#{name}.id}",
                arn: "${aws_batch_job.#{name}.arn}"
              }
            )
          end
        end
      end
    end
  end
end
