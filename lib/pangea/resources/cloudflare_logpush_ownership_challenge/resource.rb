# frozen_string_literal: true
require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/cloudflare_logpush_ownership_challenge/types'
require 'pangea/resource_registry'

module Pangea::Resources
  module CloudflareLogpushOwnershipChallenge
    def cloudflare_logpush_ownership_challenge(name, attributes = {})
      attrs = Cloudflare::Types::LogpushOwnershipChallengeAttributes.new(attributes)
      resource(:cloudflare_logpush_ownership_challenge, name) do
        zone_id attrs.zone_id if attrs.zone_id
        account_id attrs.account_id if attrs.account_id
      end
      ResourceReference.new(
        type: 'cloudflare_logpush_ownership_challenge',
        name: name,
        resource_attributes: attrs.to_h,
        outputs: { id: "${cloudflare_logpush_ownership_challenge.\#{name}.id}" }
      )
    end
  end
  module Cloudflare
    include CloudflareLogpushOwnershipChallenge
  end
end
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
