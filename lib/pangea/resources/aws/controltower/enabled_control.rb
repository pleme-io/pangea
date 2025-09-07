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
      module ControlTower
        # AWS Control Tower Enabled Control resource
        # This resource enables specific controls on organizational units within
        # Control Tower. It provides a way to apply governance rules to specific
        # parts of your organization.
        #
        # @see https://docs.aws.amazon.com/controltower/latest/userguide/enabled-controls.html
        module EnabledControl
          # Creates an AWS Control Tower Enabled Control
          #
          # @param name [Symbol] The unique name for this resource instance
          # @param attributes [Hash] The configuration options for the enabled control
          # @option attributes [String] :control_identifier The Control Tower control identifier (required)
          # @option attributes [String] :target_identifier The identifier of the organizational unit (required)
          # @option attributes [Array<Hash>] :parameters Parameters for the control configuration
          #
          # @example Enable basic control
          #   aws_controltower_enabled_control(:s3_bucket_encryption, {
          #     control_identifier: "AWS-GR_S3_BUCKET_DEFAULT_ENCRYPTION_ENABLED",
          #     target_identifier: "ou-root-abcd1234"
          #   })
          #
          # @example Enable control with parameters
          #   aws_controltower_enabled_control(:cloudtrail_encryption, {
          #     control_identifier: "AWS-GR_CLOUDTRAIL_ENCRYPTION_ENABLED",
          #     target_identifier: ref(:aws_organizations_organizational_unit, :security_ou, :id),
          #     parameters: [
          #       {
          #         key: "AllowedRegions",
          #         value: "us-east-1,us-west-2,eu-west-1"
          #       }
          #     ]
          #   })
          #
          # @return [EnabledControlResource] The enabled control resource
          def aws_controltower_enabled_control(name, attributes = {})
            resource :aws_controltower_enabled_control, name do
              control_identifier attributes[:control_identifier] if attributes[:control_identifier]
              target_identifier attributes[:target_identifier] if attributes[:target_identifier]
              
              if attributes[:parameters]
                attributes[:parameters].each do |param|
                  parameters do
                    key param[:key]
                    value param[:value]
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end