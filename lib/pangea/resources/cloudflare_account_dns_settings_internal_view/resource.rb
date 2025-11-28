# frozen_string_literal: true
require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/cloudflare_account_dns_settings_internal_view/types'
require 'pangea/resource_registry'

module Pangea::Resources
  module CloudflareAccountDnsSettingsInternalView
    def cloudflare_account_dns_settings_internal_view(name, attributes = {})
      attrs = Cloudflare::Types::AccountDnsSettingsInternalViewAttributes.new(attributes)
      resource(:cloudflare_account_dns_settings_internal_view, name) do
        account_id attrs.account_id if attrs.account_id
        zone_id attrs.zone_id if attrs.zone_id
      end
      ResourceReference.new(
        type: 'cloudflare_account_dns_settings_internal_view',
        name: name,
        resource_attributes: attrs.to_h,
        outputs: { id: "${cloudflare_account_dns_settings_internal_view.\#{name}.id}" }
      )
    end
  end
  module Cloudflare
    include CloudflareAccountDnsSettingsInternalView
  end
end
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
