# frozen_string_literal: true

require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
      # Type-safe attributes for AwsRamResourceShareInvitation resources
      # Manages a Resource Access Manager (RAM) resource share invitation.
      class RamResourceShareInvitationAttributes < Dry::Struct
        attribute :resource_share_arn, Resources::Types::String
        attribute :receiver_account_id, Resources::Types::String
        
        # Tags to apply to the resource
        attribute :tags, Resources::Types::AwsTags.default({})

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)
          
          
          
          
          attrs
        end
        
        # TODO: Add computed properties specific to aws_ram_resource_share_invitation

      end
    end
      end
    end
  end
end