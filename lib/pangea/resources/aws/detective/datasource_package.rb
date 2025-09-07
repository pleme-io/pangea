# frozen_string_literal: true

require 'pangea/resources/base'
require 'pangea/resources/reference'

module Pangea
  module Resources
    module AWS
      module Detective
        # AWS Detective Datasource Package resource
        module DatasourcePackage
          def aws_detective_datasource_package(name, attributes = {})
            resource(:aws_detective_datasource_package, name) do
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
              type: 'aws_detective_datasource_package',
              name: name,
              resource_attributes: attributes,
              outputs: {
                id: "${aws_detective_datasource_package.#{name}.id}",
                last_ingest_state_change_time: "${aws_detective_datasource_package.#{name}.last_ingest_state_change_time}"
              }
            )
          end
        end
      end
    end
  end
end