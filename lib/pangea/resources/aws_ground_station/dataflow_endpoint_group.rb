# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

module Pangea
  module Resources
    module AWS
      # Ground Station Dataflow Endpoint Group methods
      module GroundStationDataflowEndpointGroup
        # Create a Ground Station dataflow endpoint group
        def aws_groundstation_dataflow_endpoint_group(name, attributes = {})
          required_attrs = %i[endpoints_details]
          optional_attrs = {
            contact_pre_pass_duration_seconds: 120,
            contact_post_pass_duration_seconds: 180,
            tags: {}
          }

          group_attrs = optional_attrs.merge(attributes)

          required_attrs.each do |attr|
            raise ArgumentError, "Missing required attribute: #{attr}" unless group_attrs.key?(attr)
          end

          resource(:aws_groundstation_dataflow_endpoint_group, name) do
            endpoints_details group_attrs[:endpoints_details]
            contact_pre_pass_duration_seconds group_attrs[:contact_pre_pass_duration_seconds]
            contact_post_pass_duration_seconds group_attrs[:contact_post_pass_duration_seconds]
            tags group_attrs[:tags] if group_attrs[:tags].any?
          end

          ResourceReference.new(
            type: 'aws_groundstation_dataflow_endpoint_group',
            name: name,
            resource_attributes: group_attrs,
            outputs: {
              id: "${aws_groundstation_dataflow_endpoint_group.#{name}.id}",
              arn: "${aws_groundstation_dataflow_endpoint_group.#{name}.arn}",
              endpoints_details: "${aws_groundstation_dataflow_endpoint_group.#{name}.endpoints_details}"
            }
          )
        end
      end
    end
  end
end
