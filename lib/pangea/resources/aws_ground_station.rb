# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

require_relative 'aws_ground_station/contact'
require_relative 'aws_ground_station/mission_profile'
require_relative 'aws_ground_station/config'
require_relative 'aws_ground_station/dataflow_endpoint_group'

module Pangea
  module Resources
    module AWS
      # AWS Ground Station - Satellite communications service
      # Ground Station provides satellite communications capabilities to control
      # satellite communications, downlink and process satellite data, and scale
      # satellite operations

      include GroundStationContact
      include GroundStationMissionProfile
      include GroundStationConfig
      include GroundStationDataflowEndpointGroup
    end
  end
end
