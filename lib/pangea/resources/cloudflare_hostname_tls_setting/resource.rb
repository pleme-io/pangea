# frozen_string_literal: true
require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/cloudflare_hostname_tls_setting/types'
require 'pangea/resource_registry'

module Pangea::Resources
  module CloudflareHostnameTlsSetting
    def cloudflare_hostname_tls_setting(name, attributes = {})
      attrs = Cloudflare::Types::HostnameTlsSettingAttributes.new(attributes)
      resource(:cloudflare_hostname_tls_setting, name) do
        zone_id attrs.zone_id
      end
      ResourceReference.new(
        type: 'cloudflare_hostname_tls_setting',
        name: name,
        resource_attributes: attrs.to_h,
        outputs: { id: "${cloudflare_hostname_tls_setting.\#{name}.id}" }
      )
    end
  end
  module Cloudflare
    include CloudflareHostnameTlsSetting
  end
end
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
