# frozen_string_literal: true
require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/cloudflare_account_member/types'
require 'pangea/resource_registry'

module Pangea::Resources
  module CloudflareAccountMember
    def cloudflare_account_member(name, attributes = {})
      attrs = Cloudflare::Types::AccountMemberAttributes.new(attributes)
      resource(:cloudflare_account_member, name) do
        account_id attrs.account_id
        email_address attrs.email_address
        role_ids attrs.role_ids
        status attrs.status if attrs.status
      end
      ResourceReference.new(
        type: 'cloudflare_account_member',
        name: name,
        resource_attributes: attrs.to_h,
        outputs: { id: "${cloudflare_account_member.#{name}.id}" }
      )
    end
  end
  module Cloudflare
    include CloudflareAccountMember
  end
end
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
