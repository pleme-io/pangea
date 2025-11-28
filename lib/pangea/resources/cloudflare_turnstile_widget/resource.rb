# frozen_string_literal: true
require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/cloudflare_turnstile_widget/types'
require 'pangea/resource_registry'

module Pangea::Resources
  module CloudflareTurnstileWidget
    def cloudflare_turnstile_widget(name, attributes = {})
      attrs = Cloudflare::Types::TurnstileWidgetAttributes.new(attributes)
      resource(:cloudflare_turnstile_widget, name) do
        account_id attrs.account_id
        name attrs.name
        domains attrs.domains
        mode attrs.mode
        region attrs.region if attrs.region
        offlabel attrs.offlabel if attrs.offlabel
      end
      ResourceReference.new(
        type: 'cloudflare_turnstile_widget',
        name: name,
        resource_attributes: attrs.to_h,
        outputs: {
          id: "${cloudflare_turnstile_widget.#{name}.id}",
          secret: "${cloudflare_turnstile_widget.#{name}.secret}"
        }
      )
    end
  end
  module Cloudflare
    include CloudflareTurnstileWidget
  end
end
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
