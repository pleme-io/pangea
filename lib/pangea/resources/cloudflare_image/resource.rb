# frozen_string_literal: true
require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/cloudflare_image/types'
require 'pangea/resource_registry'

module Pangea::Resources
  module CloudflareImage
    def cloudflare_image(name, attributes = {})
      attrs = Cloudflare::Types::ImageAttributes.new(attributes)
      resource(:cloudflare_image, name) do
        account_id attrs.account_id if attrs.account_id
        zone_id attrs.zone_id if attrs.zone_id
      end
      ResourceReference.new(
        type: 'cloudflare_image',
        name: name,
        resource_attributes: attrs.to_h,
        outputs: { id: "${cloudflare_image.\#{name}.id}" }
      )
    end
  end
  module Cloudflare
    include CloudflareImage
  end
end
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
