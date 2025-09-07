# frozen_string_literal: true

require 'pangea/resources/base'
require 'pangea/resources/reference'

module Pangea
  module Resources
    module AWS
      module Code
        # AWS codepipeline webhook resource
        module CodepipelineWebhook
          def aws_codepipeline_webhook(name, attributes = {})
            resource(:aws_codepipeline_webhook, name) do
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
              type: 'aws_codepipeline_webhook',
              name: name,
              resource_attributes: attributes,
              outputs: {
                id: "${aws_codepipeline_webhook.#{name}.id}",
                arn: "${aws_codepipeline_webhook.#{name}.arn}"
              }
            )
          end
        end
      end
    end
  end
end
