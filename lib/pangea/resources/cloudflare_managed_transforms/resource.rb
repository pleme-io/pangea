# frozen_string_literal: true
require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/cloudflare_managed_transforms/types'
require 'pangea/resource_registry'

module Pangea::Resources
  module CloudflareManagedTransforms
    def cloudflare_managed_transforms(name, attributes = {})
      attrs = Cloudflare::Types::ManagedTransformsAttributes.new(attributes)
      resource(:cloudflare_managed_transforms, name) do
        zone_id attrs.zone_id
        if attrs.managed_request_headers
          managed_request_headers do
            attrs.managed_request_headers.each { |k, v| send(k.to_sym, v) }
          end
        end
        if attrs.managed_response_headers
          managed_response_headers do
            attrs.managed_response_headers.each { |k, v| send(k.to_sym, v) }
          end
        end
      end
      ResourceReference.new(
        type: 'cloudflare_managed_transforms',
        name: name,
        resource_attributes: attrs.to_h,
        outputs: { id: "${cloudflare_managed_transforms.#{name}.id}" }
      )
    end
  end
  module Cloudflare
    include CloudflareManagedTransforms
  end
end
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
