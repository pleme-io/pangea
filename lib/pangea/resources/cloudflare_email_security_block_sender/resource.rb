# frozen_string_literal: true
require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/cloudflare_email_security_block_sender/types'
require 'pangea/resource_registry'

module Pangea::Resources
  module CloudflareEmailSecurityBlockSender
    def cloudflare_email_security_block_sender(name, attributes = {})
      attrs = Cloudflare::Types::EmailSecurityBlockSenderAttributes.new(attributes)
      resource(:cloudflare_email_security_block_sender, name) do
        account_id attrs.account_id if attrs.account_id
        zone_id attrs.zone_id if attrs.zone_id
      end
      ResourceReference.new(
        type: 'cloudflare_email_security_block_sender',
        name: name,
        resource_attributes: attrs.to_h,
        outputs: { id: "${cloudflare_email_security_block_sender.\#{name}.id}" }
      )
    end
  end
  module Cloudflare
    include CloudflareEmailSecurityBlockSender
  end
end
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
