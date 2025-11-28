# frozen_string_literal: true
require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/cloudflare_account_dns_settings/types'
require 'pangea/resource_registry'

module Pangea::Resources
  module CloudflareAccountDnsSettings
    def cloudflare_account_dns_settings(name, attributes = {})
      attrs = Cloudflare::Types::AccountDnsSettingsAttributes.new(attributes)
      resource(:cloudflare_account_dns_settings, name) do
        account_id attrs.account_id if attrs.account_id
        zone_id attrs.zone_id if attrs.zone_id
      end
      ResourceReference.new(
        type: 'cloudflare_account_dns_settings',
        name: name,
        resource_attributes: attrs.to_h,
        outputs: { id: "${cloudflare_account_dns_settings.\#{name}.id}" }
      )
    end
  end
  module Cloudflare
    include CloudflareAccountDnsSettings
  end
end
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
