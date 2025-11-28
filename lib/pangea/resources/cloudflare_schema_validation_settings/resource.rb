# frozen_string_literal: true
require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/cloudflare_schema_validation_settings/types'
require 'pangea/resource_registry'

module Pangea::Resources
  module CloudflareSchemaValidationSettings
    def cloudflare_schema_validation_settings(name, attributes = {})
      attrs = Cloudflare::Types::SchemaValidationSettingsAttributes.new(attributes)
      resource(:cloudflare_schema_validation_settings, name) do
        zone_id attrs.zone_id if attrs.zone_id
        account_id attrs.account_id if attrs.account_id
      end
      ResourceReference.new(
        type: 'cloudflare_schema_validation_settings',
        name: name,
        resource_attributes: attrs.to_h,
        outputs: { id: "${cloudflare_schema_validation_settings.\#{name}.id}" }
      )
    end
  end
  module Cloudflare
    include CloudflareSchemaValidationSettings
  end
end
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
