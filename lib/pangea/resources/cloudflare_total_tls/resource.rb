# frozen_string_literal: true
require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/cloudflare_total_tls/types'
require 'pangea/resource_registry'

module Pangea::Resources
  module CloudflareTotalTls
    def cloudflare_total_tls(name, attributes = {})
      attrs = Cloudflare::Types::TotalTlsAttributes.new(attributes)
      resource(:cloudflare_total_tls, name) do
        zone_id attrs.zone_id
      end
      ResourceReference.new(
        type: 'cloudflare_total_tls',
        name: name,
        resource_attributes: attrs.to_h,
        outputs: { id: "${cloudflare_total_tls.\#{name}.id}" }
      )
    end
  end
  module Cloudflare
    include CloudflareTotalTls
  end
end
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
