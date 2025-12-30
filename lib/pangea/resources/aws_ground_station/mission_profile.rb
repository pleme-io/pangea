# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

module Pangea
  module Resources
    module AWS
      # Ground Station Mission Profile methods
      module GroundStationMissionProfile
        # Create a Ground Station mission profile
        def aws_groundstation_mission_profile(name, attributes = {})
          required_attrs = %i[profile_name minimum_viable_contact_duration_seconds dataflow_edge_pairs]
          optional_attrs = {
            tracking_config_arn: nil,
            contact_pre_pass_duration_seconds: 120,
            contact_post_pass_duration_seconds: 180,
            tags: {}
          }

          profile_attrs = optional_attrs.merge(attributes)

          required_attrs.each do |attr|
            raise ArgumentError, "Missing required attribute: #{attr}" unless profile_attrs.key?(attr)
          end

          resource(:aws_groundstation_mission_profile, name) do
            name profile_attrs[:profile_name]
            minimum_viable_contact_duration_seconds profile_attrs[:minimum_viable_contact_duration_seconds]
            dataflow_edge_pairs profile_attrs[:dataflow_edge_pairs]
            tracking_config_arn profile_attrs[:tracking_config_arn] if profile_attrs[:tracking_config_arn]
            contact_pre_pass_duration_seconds profile_attrs[:contact_pre_pass_duration_seconds]
            contact_post_pass_duration_seconds profile_attrs[:contact_post_pass_duration_seconds]
            tags profile_attrs[:tags] if profile_attrs[:tags].any?
          end

          ResourceReference.new(
            type: 'aws_groundstation_mission_profile',
            name: name,
            resource_attributes: profile_attrs,
            outputs: {
              id: "${aws_groundstation_mission_profile.#{name}.id}",
              arn: "${aws_groundstation_mission_profile.#{name}.arn}",
              mission_profile_id: "${aws_groundstation_mission_profile.#{name}.mission_profile_id}"
            }
          )
        end
      end
    end
  end
end
