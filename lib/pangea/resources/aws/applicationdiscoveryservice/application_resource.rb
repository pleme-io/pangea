# frozen_string_literal: true

require 'pangea/resources/base'
require 'pangea/resources/reference'

module Pangea
  module Resources
    module AWS
      module Applicationdiscoveryservice
        # AWS Applicationdiscoveryservice ApplicationResource resource
        module ApplicationResource
          def aws_applicationdiscoveryservice_application_resource(name, attributes = {})
            resource(:aws_applicationdiscoveryservice_application_resource, name) do
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
              type: 'aws_applicationdiscoveryservice_application_resource',
              name: name,
              resource_attributes: attributes,
              outputs: {
                id: "${aws_applicationdiscoveryservice_application_resource.#{name}.id}",
                arn: "${aws_applicationdiscoveryservice_application_resource.#{name}.arn}"
              }
            )
          end
        end
      end
    end
  end
end
