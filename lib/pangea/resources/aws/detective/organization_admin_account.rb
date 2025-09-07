# frozen_string_literal: true

require 'pangea/resources/base'
require 'pangea/resources/reference'

module Pangea
  module Resources
    module AWS
      module Detective
        # AWS Detective Organization Admin Account resource
        module OrganizationAdminAccount
          def aws_detective_organization_admin_account(name, attributes = {})
            resource(:aws_detective_organization_admin_account, name) do
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
              type: 'aws_detective_organization_admin_account',
              name: name,
              resource_attributes: attributes,
              outputs: {
                id: "${aws_detective_organization_admin_account.#{name}.id}"
              }
            )
          end
        end
      end
    end
  end
end