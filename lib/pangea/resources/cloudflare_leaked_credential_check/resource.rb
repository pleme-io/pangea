# frozen_string_literal: true
require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/cloudflare_leaked_credential_check/types'
require 'pangea/resource_registry'

module Pangea::Resources
  module CloudflareLeakedCredentialCheck
    def cloudflare_leaked_credential_check(name, attributes = {})
      attrs = Cloudflare::Types::LeakedCredentialCheckAttributes.new(attributes)
      resource(:cloudflare_leaked_credential_check, name) do
        zone_id attrs.zone_id if attrs.zone_id
        account_id attrs.account_id if attrs.account_id
      end
      ResourceReference.new(
        type: 'cloudflare_leaked_credential_check',
        name: name,
        resource_attributes: attrs.to_h,
        outputs: { id: "${cloudflare_leaked_credential_check.\#{name}.id}" }
      )
    end
  end
  module Cloudflare
    include CloudflareLeakedCredentialCheck
  end
end
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
