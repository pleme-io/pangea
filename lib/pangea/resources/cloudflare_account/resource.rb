# frozen_string_literal: true
require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/cloudflare_account/types'
require 'pangea/resource_registry'

module Pangea::Resources
  module CloudflareAccount
    def cloudflare_account(name, attributes = {})
      attrs = Cloudflare::Types::AccountAttributes.new(attributes)
      resource(:cloudflare_account, name) do
        name attrs.name
        type attrs.type if attrs.type
        enforce_twofactor attrs.enforce_twofactor if !attrs.enforce_twofactor.nil?
      end
      ResourceReference.new(
        type: 'cloudflare_account',
        name: name,
        resource_attributes: attrs.to_h,
        outputs: { id: "${cloudflare_account.#{name}.id}" }
      )
    end
  end
  module Cloudflare
    include CloudflareAccount
  end
end
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
