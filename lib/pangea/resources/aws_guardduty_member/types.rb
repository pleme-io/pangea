# frozen_string_literal: true

require 'dry-struct'
require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
        # GuardDuty Member attributes with validation
        class GuardDutyMemberAttributes < Dry::Struct
          transform_keys(&:to_sym)
          
          attribute :account_id, Resources::Types::AwsAccountId
          attribute :detector_id, String
          attribute :email, Resources::Types::GuardDutyInvitationEmail
          attribute :invite, Resources::Types::Bool.default(true)
          attribute :invitation_message, String.constrained(max_size: 1000).optional
          attribute :disable_email_notification, Resources::Types::Bool.default(false)
          
          # Custom validation
          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}
            
            # If not inviting, email notification settings don't matter
            if attrs[:invite] == false && attrs[:disable_email_notification] == true
              # This is redundant but valid
            end
            
            super(attrs)
          end
          
          # Computed properties  
          def will_send_invitation?
            invite && !disable_email_notification
          end
          
          def invitation_enabled?
            invite
          end
        end
      end
    end
  end
end