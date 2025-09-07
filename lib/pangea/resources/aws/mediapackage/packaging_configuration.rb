# frozen_string_literal: true

require 'pangea/resources/base'
require 'pangea/resources/reference'

module Pangea
  module Resources
    module AWS
      module Mediapackage
        # AWS Mediapackage PackagingConfiguration resource
        module PackagingConfiguration
          def aws_mediapackage_packaging_configuration(name, attributes = {})
            resource(:aws_mediapackage_packaging_configuration, name) do
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
              type: 'aws_mediapackage_packaging_configuration',
              name: name,
              resource_attributes: attributes,
              outputs: {
                id: "${aws_mediapackage_packaging_configuration.#{name}.id}",
                arn: "${aws_mediapackage_packaging_configuration.#{name}.arn}"
              }
            )
          end
        end
      end
    end
  end
end
