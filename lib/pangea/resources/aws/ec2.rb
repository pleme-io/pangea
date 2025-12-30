# frozen_string_literal: true

# Copyright 2025 The Pangea Authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Individual EC2 resource modules
require_relative 'ec2/ec2_availability_zone_group'
require_relative 'ec2/ec2_capacity_reservation'
require_relative 'ec2/ec2_capacity_block_reservation'
require_relative 'ec2/ec2_fleet'
require_relative 'ec2/ec2_spot_fleet_request'
require_relative 'ec2/ec2_spot_datafeed_subscription'
require_relative 'ec2/ec2_spot_instance_request'
require_relative 'ec2/ec2_dedicated_host'
require_relative 'ec2/ec2_host_resource_group_association'
require_relative 'ec2/ec2_instance_metadata_defaults'
require_relative 'ec2/ec2_serial_console_access'
require_relative 'ec2/ec2_image_block_public_access'
require_relative 'ec2/ec2_ami_launch_permission'
require_relative 'ec2/ec2_snapshot_block_public_access'
require_relative 'ec2/ec2_tag'
require_relative 'ec2/ec2_transit_gateway_multicast_domain'
require_relative 'ec2/ec2_transit_gateway_multicast_domain_association'
require_relative 'ec2/ec2_transit_gateway_multicast_group_member'

# Concern-based modules
require_relative 'ec2/capacity'
require_relative 'ec2/spot'
require_relative 'ec2/host'
require_relative 'ec2/account_settings'
require_relative 'ec2/access_control'
require_relative 'ec2/transit_gateway_multicast'

module Pangea
  module Resources
    module AWS
      # AWS EC2 Extended service module
      # Provides type-safe resource functions for advanced EC2 compute and networking
      #
      # This module includes sub-modules organized by concern:
      # - Capacity: Availability zones, capacity reservations, fleets
      # - Spot: Spot fleet requests, spot instance requests, datafeed subscriptions
      # - Host: Dedicated hosts, host resource group associations
      # - AccountSettings: Instance metadata defaults, serial console access
      # - AccessControl: AMI/snapshot public access blocking, launch permissions
      # - TransitGatewayMulticast: Multicast domains, associations, group members
      module EC2
        include Capacity
        include Spot
        include Host
        include AccountSettings
        include AccessControl
        include TransitGatewayMulticast

        # Creates an EC2 tag for resource tagging
        #
        # @param name [Symbol] Unique name for the EC2 tag resource
        # @param attributes [Hash] Configuration attributes for the tag
        # @return [EC2::Ec2Tag::Ec2TagReference] Reference to the created tag
        def aws_ec2_tag(name, attributes = {})
          resource = EC2::Ec2Tag.new(
            name: name,
            synthesizer: synthesizer,
            attributes: EC2::Ec2Tag::Attributes.new(attributes)
          )
          resource.synthesize
          resource.reference
        end
      end
    end
  end
end
