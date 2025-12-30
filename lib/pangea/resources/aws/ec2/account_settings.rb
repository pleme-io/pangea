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
        # Account-level EC2 settings resource functions
        # Includes instance metadata defaults and serial console access
        module AccountSettings
          # Manages EC2 instance metadata defaults for account-level metadata service configuration
          #
          # @param name [Symbol] Unique name for the instance metadata defaults resource
          # @param attributes [Hash] Configuration attributes for metadata defaults
          # @return [EC2::Ec2InstanceMetadataDefaults::Ec2InstanceMetadataDefaultsReference] Reference to the created defaults
          def aws_ec2_instance_metadata_defaults(name, attributes = {})
            resource = EC2::Ec2InstanceMetadataDefaults.new(
              name: name,
              synthesizer: synthesizer,
              attributes: EC2::Ec2InstanceMetadataDefaults::Attributes.new(attributes)
            )
            resource.synthesize
            resource.reference
          end

          # Manages EC2 serial console access configuration for debugging instances
          #
          # @param name [Symbol] Unique name for the serial console access resource
          # @param attributes [Hash] Configuration attributes for console access
          # @return [EC2::Ec2SerialConsoleAccess::Ec2SerialConsoleAccessReference] Reference to the created console access
          def aws_ec2_serial_console_access(name, attributes = {})
            resource = EC2::Ec2SerialConsoleAccess.new(
              name: name,
              synthesizer: synthesizer,
              attributes: EC2::Ec2SerialConsoleAccess::Attributes.new(attributes)
            )
            resource.synthesize
            resource.reference
          end
        end
      end
    end
  end
end
