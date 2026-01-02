# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

module Pangea
  module Resources
    module AWS
      module OutpostsOutpost
        # Create an Outposts outpost
        #
        # @param name [Symbol] The resource name
        # @param attributes [Hash] Outpost attributes
        # @option attributes [String] :outpost_name (required) The outpost name
        # @option attributes [String] :site_id (required) The site ID
        # @option attributes [String] :availability_zone The availability zone
        # @option attributes [String] :availability_zone_id The availability zone ID
        # @option attributes [String] :description Description of the outpost
        # @option attributes [Hash<String,String>] :tags Resource tags
        # @return [ResourceReference] Reference object with outputs
        def aws_outposts_outpost(name, attributes = {})
          required_attrs = %i[outpost_name site_id]
          optional_attrs = {
            availability_zone: nil,
            availability_zone_id: nil,
            description: nil,
            tags: {}
          }

          outpost_attrs = optional_attrs.merge(attributes)

          required_attrs.each do |attr|
            raise ArgumentError, "Missing required attribute: #{attr}" unless outpost_attrs.key?(attr)
          end

          resource(:aws_outposts_outpost, name) do
            name outpost_attrs[:outpost_name]
            site_id outpost_attrs[:site_id]
            availability_zone outpost_attrs[:availability_zone] if outpost_attrs[:availability_zone]
            availability_zone_id outpost_attrs[:availability_zone_id] if outpost_attrs[:availability_zone_id]
            description outpost_attrs[:description] if outpost_attrs[:description]

            if outpost_attrs[:tags].any?
              tags outpost_attrs[:tags]
            end
          end

          ResourceReference.new(
            type: 'aws_outposts_outpost',
            name: name,
            resource_attributes: outpost_attrs,
            outputs: {
              id: "${aws_outposts_outpost.#{name}.id}",
              arn: "${aws_outposts_outpost.#{name}.arn}",
              availability_zone: "${aws_outposts_outpost.#{name}.availability_zone}",
              availability_zone_id: "${aws_outposts_outpost.#{name}.availability_zone_id}",
              owner_id: "${aws_outposts_outpost.#{name}.owner_id}",
              site_arn: "${aws_outposts_outpost.#{name}.site_arn}"
            }
          )
        end
      end
    end
  end
end
