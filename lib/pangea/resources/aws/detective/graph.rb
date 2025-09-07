# frozen_string_literal: true

require 'pangea/resources/base'
require 'pangea/resources/reference'

module Pangea
  module Resources
    module AWS
      module Detective
        # AWS Detective Graph resource
        module Graph
          def aws_detective_graph(name, attributes = {})
            resource(:aws_detective_graph, name) do
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
              type: 'aws_detective_graph',
              name: name,
              resource_attributes: attributes,
              outputs: {
                id: "${aws_detective_graph.#{name}.id}",
                arn: "${aws_detective_graph.#{name}.arn}",
                graph_arn: "${aws_detective_graph.#{name}.graph_arn}",
                created_time: "${aws_detective_graph.#{name}.created_time}",
                status: "${aws_detective_graph.#{name}.status}"
              }
            )
          end
        end
      end
    end
  end
end