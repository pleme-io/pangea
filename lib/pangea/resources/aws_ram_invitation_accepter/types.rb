# frozen_string_literal: true

require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
      # Type-safe attributes for AwsRamInvitationAccepter resources
      # Accepts a Resource Access Manager (RAM) resource share invitation.
      class RamInvitationAccepterAttributes < Dry::Struct
        attribute :share_arn, Resources::Types::String
        
        # Tags to apply to the resource
        attribute :tags, Resources::Types::AwsTags.default({})

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)
          
          
          
          
          attrs
        end
        
        # TODO: Add computed properties specific to aws_ram_invitation_accepter

      end
    end
      end
    end
  end
end