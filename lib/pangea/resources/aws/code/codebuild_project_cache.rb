# frozen_string_literal: true

require 'pangea/resources/base'
require 'pangea/resources/reference'

module Pangea
  module Resources
    module AWS
      module Code
        # AWS codebuild project cache resource
        module CodebuildProjectCache
          def aws_codebuild_project_cache(name, attributes = {})
            resource(:aws_codebuild_project_cache, name) do
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
              type: 'aws_codebuild_project_cache',
              name: name,
              resource_attributes: attributes,
              outputs: {
                id: "${aws_codebuild_project_cache.#{name}.id}",
                arn: "${aws_codebuild_project_cache.#{name}.arn}"
              }
            )
          end
        end
      end
    end
  end
end
