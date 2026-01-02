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
        # Access control-related EC2 resource functions
        # Includes AMI/snapshot public access blocking and launch permissions
        module AccessControl
          # Manages EC2 image block public access settings for AMI sharing control
          #
          # @param name [Symbol] Unique name for the image block public access resource
          # @param attributes [Hash] Configuration attributes for public access blocking
          # @return [EC2::Ec2ImageBlockPublicAccess::Ec2ImageBlockPublicAccessReference] Reference to the created access block
          def aws_ec2_image_block_public_access(name, attributes = {})
            resource = EC2::Ec2ImageBlockPublicAccess.new(
              name: name,
              synthesizer: synthesizer,
              attributes: EC2::Ec2ImageBlockPublicAccess::Attributes.new(attributes)
            )
            resource.synthesize
            resource.reference
          end

          # Creates an EC2 AMI launch permission for controlling AMI access
          #
          # @param name [Symbol] Unique name for the AMI launch permission resource
          # @param attributes [Hash] Configuration attributes for the launch permission
          # @return [EC2::Ec2AmiLaunchPermission::Ec2AmiLaunchPermissionReference] Reference to the created permission
          def aws_ec2_ami_launch_permission(name, attributes = {})
            resource = EC2::Ec2AmiLaunchPermission.new(
              name: name,
              synthesizer: synthesizer,
              attributes: EC2::Ec2AmiLaunchPermission::Attributes.new(attributes)
            )
            resource.synthesize
            resource.reference
          end

          # Manages EC2 snapshot block public access settings for snapshot sharing control
          #
          # @param name [Symbol] Unique name for the snapshot block public access resource
          # @param attributes [Hash] Configuration attributes for public access blocking
          # @return [EC2::Ec2SnapshotBlockPublicAccess::Ec2SnapshotBlockPublicAccessReference] Reference to the created access block
          def aws_ec2_snapshot_block_public_access(name, attributes = {})
            resource = EC2::Ec2SnapshotBlockPublicAccess.new(
              name: name,
              synthesizer: synthesizer,
              attributes: EC2::Ec2SnapshotBlockPublicAccess::Attributes.new(attributes)
            )
            resource.synthesize
            resource.reference
          end
        end
      end
    end
  end
end
