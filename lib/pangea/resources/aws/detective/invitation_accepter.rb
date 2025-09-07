# frozen_string_literal: true

require 'pangea/resources/base'
require 'pangea/resources/reference'

module Pangea
  module Resources
    module AWS
      module Detective
        # AWS Detective Invitation Accepter resource
        module InvitationAccepter
          def aws_detective_invitation_accepter(name, attributes = {})
            resource(:aws_detective_invitation_accepter, name) do
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
              type: 'aws_detective_invitation_accepter',
              name: name,
              resource_attributes: attributes,
              outputs: {
                id: "${aws_detective_invitation_accepter.#{name}.id}"
              }
            )
          end
        end
      end
    end
  end
end