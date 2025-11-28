# frozen_string_literal: true
require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/cloudflare_web_analytics_site/types'
require 'pangea/resource_registry'

module Pangea::Resources
  module CloudflareWebAnalyticsSite
    def cloudflare_web_analytics_site(name, attributes = {})
      attrs = Cloudflare::Types::WebAnalyticsSiteAttributes.new(attributes)
      resource(:cloudflare_web_analytics_site, name) do
        account_id attrs.account_id
        auto_install attrs.auto_install
        host attrs.host if attrs.host
        zone_tag attrs.zone_tag if attrs.zone_tag
      end
      ResourceReference.new(
        type: 'cloudflare_web_analytics_site',
        name: name,
        resource_attributes: attrs.to_h,
        outputs: {
          id: "${cloudflare_web_analytics_site.#{name}.id}",
          site_tag: "${cloudflare_web_analytics_site.#{name}.site_tag}",
          site_token: "${cloudflare_web_analytics_site.#{name}.site_token}"
        }
      )
    end
  end
  module Cloudflare
    include CloudflareWebAnalyticsSite
  end
end
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
