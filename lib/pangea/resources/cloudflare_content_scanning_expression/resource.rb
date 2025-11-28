# frozen_string_literal: true
require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/cloudflare_content_scanning_expression/types'
require 'pangea/resource_registry'

module Pangea::Resources
  module CloudflareContentScanningExpression
    def cloudflare_content_scanning_expression(name, attributes = {})
      attrs = Cloudflare::Types::ContentScanningExpressionAttributes.new(attributes)
      resource(:cloudflare_content_scanning_expression, name) do
        account_id attrs.account_id if attrs.account_id
        zone_id attrs.zone_id if attrs.zone_id
      end
      ResourceReference.new(
        type: 'cloudflare_content_scanning_expression',
        name: name,
        resource_attributes: attrs.to_h,
        outputs: { id: "${cloudflare_content_scanning_expression.\#{name}.id}" }
      )
    end
  end
  module Cloudflare
    include CloudflareContentScanningExpression
  end
end
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
