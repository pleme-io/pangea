# frozen_string_literal: true
require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/cloudflare_schema_validation_schemas/types'
require 'pangea/resource_registry'

module Pangea::Resources
  module CloudflareSchemaValidationSchemas
    def cloudflare_schema_validation_schemas(name, attributes = {})
      attrs = Cloudflare::Types::SchemaValidationSchemasAttributes.new(attributes)
      resource(:cloudflare_schema_validation_schemas, name) do
        zone_id attrs.zone_id if attrs.zone_id
        account_id attrs.account_id if attrs.account_id
      end
      ResourceReference.new(
        type: 'cloudflare_schema_validation_schemas',
        name: name,
        resource_attributes: attrs.to_h,
        outputs: { id: "${cloudflare_schema_validation_schemas.\#{name}.id}" }
      )
    end
  end
  module Cloudflare
    include CloudflareSchemaValidationSchemas
  end
end
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
