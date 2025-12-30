# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

module Pangea
  module Resources
    module AWS
      module OutpostsSite
        # Create an Outposts site
        #
        # @param name [Symbol] The resource name
        # @param attributes [Hash] Site attributes
        # @option attributes [String] :site_name (required) The site name
        # @option attributes [String] :description Description of the site
        # @option attributes [String] :notes Notes about the site
        # @option attributes [Hash] :operating_address Site operating address
        # @option attributes [Hash] :shipping_address Site shipping address
        # @option attributes [Hash] :rack_physical_properties Rack physical properties
        # @option attributes [Hash<String,String>] :tags Resource tags
        # @return [ResourceReference] Reference object with outputs
        def aws_outposts_site(name, attributes = {})
          required_attrs = %i[site_name]
          optional_attrs = {
            description: nil,
            notes: nil,
            operating_address: {},
            shipping_address: {},
            rack_physical_properties: {},
            tags: {}
          }

          site_attrs = optional_attrs.merge(attributes)

          required_attrs.each do |attr|
            raise ArgumentError, "Missing required attribute: #{attr}" unless site_attrs.key?(attr)
          end

          resource(:aws_outposts_site, name) do
            name site_attrs[:site_name]
            description site_attrs[:description] if site_attrs[:description]
            notes site_attrs[:notes] if site_attrs[:notes]

            if site_attrs[:operating_address].any?
              operating_address site_attrs[:operating_address]
            end

            if site_attrs[:shipping_address].any?
              shipping_address site_attrs[:shipping_address]
            end

            if site_attrs[:rack_physical_properties].any?
              rack_physical_properties site_attrs[:rack_physical_properties]
            end

            if site_attrs[:tags].any?
              tags site_attrs[:tags]
            end
          end

          ResourceReference.new(
            type: 'aws_outposts_site',
            name: name,
            resource_attributes: site_attrs,
            outputs: {
              id: "${aws_outposts_site.#{name}.id}",
              account_id: "${aws_outposts_site.#{name}.account_id}",
              description: "${aws_outposts_site.#{name}.description}",
              name: "${aws_outposts_site.#{name}.name}"
            }
          )
        end
      end
    end
  end
end
