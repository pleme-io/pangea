# frozen_string_literal: true

module Pangea
  module Resources
    module AWS
      module ControlTower
        # AWS Control Tower Control resource
        # This resource manages Control Tower controls which are governance rules that provide
        # ongoing monitoring and compliance for AWS resources in your organization.
        # Controls can be preventive or detective in nature.
        #
        # @see https://docs.aws.amazon.com/controltower/latest/userguide/controls.html
        module Control
          # Creates an AWS Control Tower Control
          #
          # @param name [Symbol] The unique name for this resource instance
          # @param attributes [Hash] The configuration options for the control
          # @option attributes [String] :control_identifier The Control Tower control identifier (required)
          # @option attributes [String] :target_identifier The identifier of the organizational unit to apply the control to (required)
          # @option attributes [Array<Hash>] :parameters Parameters for the control configuration
          #
          # @example Basic preventive control
          #   aws_controltower_control(:disallow_public_s3_buckets, {
          #     control_identifier: "AWS-GR_S3_BUCKET_PUBLIC_ACCESS_PROHIBITED",
          #     target_identifier: "ou-root-abcd1234"
          #   })
          #
          # @example Detective control with parameters
          #   aws_controltower_control(:cloudtrail_enabled, {
          #     control_identifier: "AWS-GR_CLOUDTRAIL_ENABLED",
          #     target_identifier: ref(:aws_organizations_organizational_unit, :security_ou, :id),
          #     parameters: [
          #       {
          #         key: "AllowedRegions",
          #         value: "us-east-1,us-west-2"
          #       }
          #     ]
          #   })
          #
          # @example Control on multiple OUs
          #   ["ou-root-prod123", "ou-root-staging456", "ou-root-dev789"].each_with_index do |ou_id, index|
          #     aws_controltower_control(:"mfa_required_#{index}", {
          #       control_identifier: "AWS-GR_MFA_ENABLED_FOR_IAM_CONSOLE_ACCESS",
          #       target_identifier: ou_id
          #     })
          #   end
          #
          # @return [ControlResource] The control resource
          def aws_controltower_control(name, attributes = {})
            resource :aws_controltower_control, name do
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