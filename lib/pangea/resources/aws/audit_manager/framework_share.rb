# frozen_string_literal: true

require 'pangea/resources/base'
require 'pangea/resources/reference'

module Pangea
  module Resources
    module AWS
      module AuditManager
        # AWS AuditManager FrameworkShare resource
        module FrameworkShare
          def aws_audit_manager_framework_share(name, attributes = {})
            resource(:aws_audit_manager_framework_share, name) do
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
              type: 'aws_audit_manager_framework_share',
              name: name,
              resource_attributes: attributes,
              outputs: {
                id: "${aws_audit_manager_framework_share.#{name}.id}",
                arn: "${aws_audit_manager_framework_share.#{name}.arn}"
              }
            )
          end
        end
      end
    end
  end
end
