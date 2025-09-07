# frozen_string_literal: true

require 'pangea/resources/base'
require 'pangea/resources/reference'

module Pangea
  module Resources
    module AWS
      module Code
        # AWS codedeploy deployment config resource
        module CodedeployDeploymentConfig
          def aws_codedeploy_deployment_config(name, attributes = {})
            resource(:aws_codedeploy_deployment_config, name) do
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
              type: 'aws_codedeploy_deployment_config',
              name: name,
              resource_attributes: attributes,
              outputs: {
                id: "${aws_codedeploy_deployment_config.#{name}.id}",
                arn: "${aws_codedeploy_deployment_config.#{name}.arn}"
              }
            )
          end
        end
      end
    end
  end
end
