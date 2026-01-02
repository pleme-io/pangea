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
        # Spot instance-related EC2 resource functions
        # Includes spot fleet requests, spot instance requests, and datafeed subscriptions
        module Spot
          # Creates an EC2 spot fleet request for cost-optimized instance provisioning
          #
          # @param name [Symbol] Unique name for the spot fleet request resource
          # @param attributes [Hash] Configuration attributes for the spot fleet
          # @return [EC2::Ec2SpotFleetRequest::Ec2SpotFleetRequestReference] Reference to the created spot fleet
          def aws_ec2_spot_fleet_request(name, attributes = {})
            resource = EC2::Ec2SpotFleetRequest.new(
              name: name,
              synthesizer: synthesizer,
              attributes: EC2::Ec2SpotFleetRequest::Attributes.new(attributes)
            )
            resource.synthesize
            resource.reference
          end

          # Creates an EC2 spot datafeed subscription for spot instance activity logging
          #
          # @param name [Symbol] Unique name for the spot datafeed subscription resource
          # @param attributes [Hash] Configuration attributes for the datafeed
          # @return [EC2::Ec2SpotDatafeedSubscription::Ec2SpotDatafeedSubscriptionReference] Reference to the created datafeed
          def aws_ec2_spot_datafeed_subscription(name, attributes = {})
            resource = EC2::Ec2SpotDatafeedSubscription.new(
              name: name,
              synthesizer: synthesizer,
              attributes: EC2::Ec2SpotDatafeedSubscription::Attributes.new(attributes)
            )
            resource.synthesize
            resource.reference
          end

          # Creates an EC2 spot instance request for requesting spot instances
          #
          # @param name [Symbol] Unique name for the spot instance request resource
          # @param attributes [Hash] Configuration attributes for the spot request
          # @return [EC2::Ec2SpotInstanceRequest::Ec2SpotInstanceRequestReference] Reference to the created spot request
          def aws_ec2_spot_instance_request(name, attributes = {})
            resource = EC2::Ec2SpotInstanceRequest.new(
              name: name,
              synthesizer: synthesizer,
              attributes: EC2::Ec2SpotInstanceRequest::Attributes.new(attributes)
            )
            resource.synthesize
            resource.reference
          end
        end
      end
    end
  end
end
