# frozen_string_literal: true

require 'pangea/resources/base'
require 'pangea/resources/reference'

module Pangea
  module Resources
    module AWS
      module DataPipeline
        # AWS DataPipeline PipelineDefinition resource
        module PipelineDefinition
          def aws_data_pipeline_pipeline_definition(name, attributes = {})
            resource(:aws_data_pipeline_pipeline_definition, name) do
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
              type: 'aws_data_pipeline_pipeline_definition',
              name: name,
              resource_attributes: attributes,
              outputs: {
                id: "${aws_data_pipeline_pipeline_definition.#{name}.id}",
                arn: "${aws_data_pipeline_pipeline_definition.#{name}.arn}"
              }
            )
          end
        end
      end
    end
  end
end
