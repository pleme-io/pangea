# frozen_string_literal: true

require 'pangea/resources/base'
require 'pangea/resources/reference'

module Pangea
  module Resources
    module AWS
      module Detective
        # AWS Detective Member resource
        module Member
          def aws_detective_member(name, attributes = {})
            resource(:aws_detective_member, name) do
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
              type: 'aws_detective_member',
              name: name,
              resource_attributes: attributes,
              outputs: {
                id: "${aws_detective_member.#{name}.id}",
                administrator_id: "${aws_detective_member.#{name}.administrator_id}",
                status: "${aws_detective_member.#{name}.status}",
                invited_time: "${aws_detective_member.#{name}.invited_time}",
                updated_time: "${aws_detective_member.#{name}.updated_time}",
                volume_usage_in_bytes: "${aws_detective_member.#{name}.volume_usage_in_bytes}"
              }
            )
          end
        end
      end
    end
  end
end