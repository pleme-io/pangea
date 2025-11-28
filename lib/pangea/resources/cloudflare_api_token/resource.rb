# frozen_string_literal: true
require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/cloudflare_api_token/types'
require 'pangea/resource_registry'

module Pangea::Resources
  module CloudflareApiToken
    def cloudflare_api_token(name, attributes = {})
      attrs = Cloudflare::Types::ApiTokenAttributes.new(attributes)
      resource(:cloudflare_api_token, name) do
        name attrs.name
        policy attrs.policy
        condition attrs.condition if attrs.condition
        expires_on attrs.expires_on if attrs.expires_on
        not_before attrs.not_before if attrs.not_before
      end
      ResourceReference.new(
        type: 'cloudflare_api_token',
        name: name,
        resource_attributes: attrs.to_h,
        outputs: {
          id: "${cloudflare_api_token.#{name}.id}",
          value: "${cloudflare_api_token.#{name}.value}"
        }
      )
    end
  end
  module Cloudflare
    include CloudflareApiToken
  end
end
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
