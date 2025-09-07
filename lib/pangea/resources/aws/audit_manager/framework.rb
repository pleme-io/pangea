# frozen_string_literal: true

require 'pangea/resources/base'
require 'pangea/resources/reference'

module Pangea
  module Resources
    module AWS
      module AuditManager
        # AWS AuditManager Framework resource
        module Framework
          def aws_audit_manager_framework(name, attributes = {})
            resource(:aws_audit_manager_framework, name) do
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
              type: 'aws_audit_manager_framework',
              name: name,
              resource_attributes: attributes,
              outputs: {
                id: "${aws_audit_manager_framework.#{name}.id}",
                arn: "${aws_audit_manager_framework.#{name}.arn}"
              }
            )
          end
        end
      end
    end
  end
end
