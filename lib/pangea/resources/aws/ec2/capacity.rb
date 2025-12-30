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

module Pangea
  module Resources
    module AWS
      module EC2
        # Capacity-related EC2 resource functions
        # Includes availability zones, capacity reservations, and fleet management
        module Capacity
          # Creates an EC2 availability zone group for managing AZ access
          #
          # @param name [Symbol] Unique name for the availability zone group resource
          # @param attributes [Hash] Configuration attributes for the AZ group
          # @return [EC2::Ec2AvailabilityZoneGroup::Ec2AvailabilityZoneGroupReference] Reference to the created AZ group
          def aws_ec2_availability_zone_group(name, attributes = {})
            resource = EC2::Ec2AvailabilityZoneGroup.new(
              name: name,
              synthesizer: synthesizer,
              attributes: EC2::Ec2AvailabilityZoneGroup::Attributes.new(attributes)
            )
            resource.synthesize
            resource.reference
          end

          # Creates an EC2 capacity reservation for guaranteed compute capacity
          #
          # @param name [Symbol] Unique name for the capacity reservation resource
          # @param attributes [Hash] Configuration attributes for the reservation
          # @return [EC2::Ec2CapacityReservation::Ec2CapacityReservationReference] Reference to the created reservation
          def aws_ec2_capacity_reservation(name, attributes = {})
            resource = EC2::Ec2CapacityReservation.new(
              name: name,
              synthesizer: synthesizer,
              attributes: EC2::Ec2CapacityReservation::Attributes.new(attributes)
            )
            resource.synthesize
            resource.reference
          end

          # Creates an EC2 capacity block reservation for high-performance computing workloads
          #
          # @param name [Symbol] Unique name for the capacity block reservation resource
          # @param attributes [Hash] Configuration attributes for the block reservation
          # @return [EC2::Ec2CapacityBlockReservation::Ec2CapacityBlockReservationReference] Reference to the created block reservation
          def aws_ec2_capacity_block_reservation(name, attributes = {})
            resource = EC2::Ec2CapacityBlockReservation.new(
              name: name,
              synthesizer: synthesizer,
              attributes: EC2::Ec2CapacityBlockReservation::Attributes.new(attributes)
            )
            resource.synthesize
            resource.reference
          end

          # Creates an EC2 fleet for launching multiple instance types across multiple AZs
          #
          # @param name [Symbol] Unique name for the EC2 fleet resource
          # @param attributes [Hash] Configuration attributes for the fleet
          # @return [EC2::Ec2Fleet::Ec2FleetReference] Reference to the created fleet
          def aws_ec2_fleet(name, attributes = {})
            resource = EC2::Ec2Fleet.new(
              name: name,
              synthesizer: synthesizer,
              attributes: EC2::Ec2Fleet::Attributes.new(attributes)
            )
            resource.synthesize
            resource.reference
          end
        end
      end
    end
  end
end
