# frozen_string_literal: true
require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/cloudflare_snippet_rules/types'
require 'pangea/resource_registry'

module Pangea::Resources
  module CloudflareSnippetRules
    def cloudflare_snippet_rules(name, attributes = {})
      attrs = Cloudflare::Types::SnippetRulesAttributes.new(attributes)
      resource(:cloudflare_snippet_rules, name) do
        account_id attrs.account_id if attrs.account_id
        zone_id attrs.zone_id if attrs.zone_id
      end
      ResourceReference.new(
        type: 'cloudflare_snippet_rules',
        name: name,
        resource_attributes: attrs.to_h,
        outputs: { id: "${cloudflare_snippet_rules.\#{name}.id}" }
      )
    end
  end
  module Cloudflare
    include CloudflareSnippetRules
  end
end
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
