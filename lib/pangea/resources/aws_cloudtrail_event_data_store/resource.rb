# frozen_string_literal: true

require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/aws_cloudtrail_event_data_store/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      def aws_cloudtrail_event_data_store(name, attributes = {})
        store_attrs = Types::Types::CloudTrailEventDataStoreAttributes.new(attributes)
        
        resource(:aws_cloudtrail_event_data_store, name) do
          name store_attrs.name
          multi_region_enabled store_attrs.multi_region_enabled
          organization_enabled store_attrs.organization_enabled
          retention_period store_attrs.retention_period
          termination_protection_enabled store_attrs.termination_protection_enabled
          
          if store_attrs.tags.any?
            tags do
              store_attrs.tags.each do |key, value|
                public_send(key, value)
              end
            end
          end
        end
        
        ResourceReference.new(
          type: 'aws_cloudtrail_event_data_store',
          name: name,
          resource_attributes: store_attrs.to_h,
          outputs: {
            id: "${aws_cloudtrail_event_data_store.#{name}.id}",
            arn: "${aws_cloudtrail_event_data_store.#{name}.arn}",
            name: "${aws_cloudtrail_event_data_store.#{name}.name}",
            tags_all: "${aws_cloudtrail_event_data_store.#{name}.tags_all}"
          },
          computed_properties: {
            estimated_monthly_cost_usd: store_attrs.estimated_monthly_cost_usd
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)