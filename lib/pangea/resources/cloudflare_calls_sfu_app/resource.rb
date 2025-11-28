# frozen_string_literal: true
require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/cloudflare_calls_sfu_app/types'
require 'pangea/resource_registry'

module Pangea::Resources
  module CloudflareCallsSfuApp
    def cloudflare_calls_sfu_app(name, attributes = {})
      attrs = Cloudflare::Types::CallsSfuAppAttributes.new(attributes)
      resource(:cloudflare_calls_sfu_app, name) do
        account_id attrs.account_id if attrs.account_id
        zone_id attrs.zone_id if attrs.zone_id
      end
      ResourceReference.new(
        type: 'cloudflare_calls_sfu_app',
        name: name,
        resource_attributes: attrs.to_h,
        outputs: { id: "${cloudflare_calls_sfu_app.\#{name}.id}" }
      )
    end
  end
  module Cloudflare
    include CloudflareCallsSfuApp
  end
end
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
