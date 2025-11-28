# frozen_string_literal: true
require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/cloudflare_snippet/types'
require 'pangea/resource_registry'

module Pangea::Resources
  module CloudflareSnippet
    def cloudflare_snippet(name, attributes = {})
      attrs = Cloudflare::Types::SnippetAttributes.new(attributes)
      resource(:cloudflare_snippet, name) do
        account_id attrs.account_id if attrs.account_id
        zone_id attrs.zone_id if attrs.zone_id
      end
      ResourceReference.new(
        type: 'cloudflare_snippet',
        name: name,
        resource_attributes: attrs.to_h,
        outputs: { id: "${cloudflare_snippet.\#{name}.id}" }
      )
    end
  end
  module Cloudflare
    include CloudflareSnippet
  end
end
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
