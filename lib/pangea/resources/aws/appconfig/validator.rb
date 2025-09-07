# frozen_string_literal: true

require 'pangea/resources/base'
require 'pangea/resources/reference'

module Pangea
  module Resources
    module AWS
      module AppConfig
        # AWS AppConfig validator resource
        module Validator
          def aws_appconfig_validator(name, attributes = {})
            resource(:aws_appconfig_validator, name) do
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
              type: 'aws_appconfig_validator',
              name: name,
              resource_attributes: attributes,
              outputs: {
                id: "${aws_appconfig_validator.#{name}.id}",
                arn: "${aws_appconfig_validator.#{name}.arn}"
              }
            )
          end
        end
      end
    end
  end
end
