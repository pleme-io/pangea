# frozen_string_literal: true
require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/cloudflare_image_variant/types'
require 'pangea/resource_registry'

module Pangea::Resources
  module CloudflareImageVariant
    def cloudflare_image_variant(name, attributes = {})
      attrs = Cloudflare::Types::ImageVariantAttributes.new(attributes)
      resource(:cloudflare_image_variant, name) do
        account_id attrs.account_id
      end
      ResourceReference.new(
        type: 'cloudflare_image_variant',
        name: name,
        resource_attributes: attrs.to_h,
        outputs: { id: "${cloudflare_image_variant.#{name}.id}" }
      )
    end
  end
  module Cloudflare
    include CloudflareImageVariant
  end
end
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
