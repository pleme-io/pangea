# frozen_string_literal: true

require 'pangea/resources/base'
require 'pangea/resources/reference'

module Pangea
  module Resources
    module AWS
      module Opensearch
        # AWS OpenSearch Domain resource
        module Domain
          def aws_opensearch_domain(name, attributes = {})
            resource(:aws_opensearch_domain, name) do
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
              type: 'aws_opensearch_domain',
              name: name,
              resource_attributes: attributes,
              outputs: {
                id: "${aws_opensearch_domain.#{name}.id}",
                arn: "${aws_opensearch_domain.#{name}.arn}",
                domain_name: "${aws_opensearch_domain.#{name}.domain_name}",
                domain_id: "${aws_opensearch_domain.#{name}.domain_id}",
                endpoint: "${aws_opensearch_domain.#{name}.endpoint}",
                dashboards_endpoint: "${aws_opensearch_domain.#{name}.dashboards_endpoint}"
              }
            )
          end
        end
      end
    end
  end
end