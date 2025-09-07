# frozen_string_literal: true

require 'pangea/resources/base'
require 'pangea/resources/reference'

module Pangea
  module Resources
    module AWS
      module SecurityLake
        # AWS SecurityLake DataLake resource
        module DataLake
          def aws_security_lake_data_lake(name, attributes = {})
            resource(:aws_security_lake_data_lake, name) do
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
              type: 'aws_security_lake_data_lake',
              name: name,
              resource_attributes: attributes,
              outputs: {
                id: "${aws_security_lake_data_lake.#{name}.id}",
                arn: "${aws_security_lake_data_lake.#{name}.arn}"
              }
            )
          end
        end
      end
    end
  end
end
