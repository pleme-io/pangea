# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

module Pangea
  module Resources
    module AWS
      # Ground Station Contact methods
      module GroundStationContact
        # Create a Ground Station contact for satellite communications
        def aws_groundstation_contact(name, attributes = {})
          required_attrs = %i[mission_profile_arn satellite_arn start_time end_time]
          optional_attrs = { ground_station: nil, tags: {} }

          contact_attrs = optional_attrs.merge(attributes)

          required_attrs.each do |attr|
            raise ArgumentError, "Missing required attribute: #{attr}" unless contact_attrs.key?(attr)
          end

          resource(:aws_groundstation_contact, name) do
            mission_profile_arn contact_attrs[:mission_profile_arn]
            satellite_arn contact_attrs[:satellite_arn]
            start_time contact_attrs[:start_time]
            end_time contact_attrs[:end_time]
            ground_station contact_attrs[:ground_station] if contact_attrs[:ground_station]
            tags contact_attrs[:tags] if contact_attrs[:tags].any?
          end

          ResourceReference.new(
            type: 'aws_groundstation_contact',
            name: name,
            resource_attributes: contact_attrs,
            outputs: {
              id: "${aws_groundstation_contact.#{name}.id}",
              arn: "${aws_groundstation_contact.#{name}.arn}",
              contact_status: "${aws_groundstation_contact.#{name}.contact_status}",
              error_message: "${aws_groundstation_contact.#{name}.error_message}",
              maximum_elevation: "${aws_groundstation_contact.#{name}.maximum_elevation}",
              post_pass_end_time: "${aws_groundstation_contact.#{name}.post_pass_end_time}",
              pre_pass_start_time: "${aws_groundstation_contact.#{name}.pre_pass_start_time}"
            }
          )
        end
      end
    end
  end
end
