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


require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/aws_guardduty_member/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS GuardDuty Member for multi-account threat detection
      #
      # @param name [Symbol] The resource name  
      # @param attributes [Hash] GuardDuty Member attributes
      # @return [ResourceReference] Reference object with outputs
      def aws_guardduty_member(name, attributes = {})
        # Validate attributes using dry-struct
        member_attrs = Types::GuardDutyMemberAttributes.new(attributes)
        
        # Generate terraform resource block
        resource(:aws_guardduty_member, name) do
          account_id member_attrs.account_id
          detector_id member_attrs.detector_id
          email member_attrs.email
          invite member_attrs.invite
          
          if member_attrs.invitation_message
            invitation_message member_attrs.invitation_message
          end
          
          disable_email_notification member_attrs.disable_email_notification
        end
        
        # Return resource reference
        ResourceReference.new(
          type: 'aws_guardduty_member',
          name: name,
          resource_attributes: member_attrs.to_h,
          outputs: {
            id: "${aws_guardduty_member.#{name}.id}",
            detector_id: "${aws_guardduty_member.#{name}.detector_id}", 
            account_id: "${aws_guardduty_member.#{name}.account_id}",
            relationship_status: "${aws_guardduty_member.#{name}.relationship_status}"
          },
          computed: {
            will_send_invitation: member_attrs.will_send_invitation?,
            invitation_enabled: member_attrs.invitation_enabled?,
            member_account: member_attrs.account_id,
            email_address: member_attrs.email
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)