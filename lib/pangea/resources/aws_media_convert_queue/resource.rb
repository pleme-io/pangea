# frozen_string_literal: true

require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/aws_media_convert_queue/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS MediaConvert Queue with type-safe attributes
      def aws_media_convert_queue(name, attributes = {})
        queue_attrs = Types::MediaConvertQueueAttributes.new(attributes)
        
        resource(:aws_media_convert_queue, name) do
          name queue_attrs.name
          description queue_attrs.description if queue_attrs.description && !queue_attrs.description.empty?
          pricing_plan queue_attrs.pricing_plan
          status queue_attrs.status
          
          if queue_attrs.reserved_pricing? && queue_attrs.reservation_plan_settings.any?
            reservation_plan_settings do
              commitment queue_attrs.reservation_plan_settings[:commitment]
              renewal_type queue_attrs.reservation_plan_settings[:renewal_type]
              reserved_slots queue_attrs.reservation_plan_settings[:reserved_slots]
            end
          end
          
          if queue_attrs.tags.any?
            tags do
              queue_attrs.tags.each do |key, value|
                public_send(key, value)
              end
            end
          end
        end
        
        ResourceReference.new(
          type: 'aws_media_convert_queue',
          name: name,
          resource_attributes: queue_attrs.to_h,
          outputs: {
            arn: "${aws_media_convert_queue.#{name}.arn}",
            id: "${aws_media_convert_queue.#{name}.id}",
            name: "${aws_media_convert_queue.#{name}.name}"
          },
          computed: {
            reserved_pricing: queue_attrs.reserved_pricing?,
            on_demand_pricing: queue_attrs.on_demand_pricing?,
            active: queue_attrs.active?,
            paused: queue_attrs.paused?
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)