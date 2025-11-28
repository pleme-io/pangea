# frozen_string_literal: true
require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/cloudflare_queue_consumer/types'
require 'pangea/resource_registry'

module Pangea::Resources
  module CloudflareQueueConsumer
    def cloudflare_queue_consumer(name, attributes = {})
      attrs = Cloudflare::Types::QueueConsumerAttributes.new(attributes)
      resource(:cloudflare_queue_consumer, name) do
        account_id attrs.account_id
        queue_id attrs.queue_id
        script_name attrs.script_name
        batch_size attrs.batch_size if attrs.batch_size
        max_retries attrs.max_retries if attrs.max_retries
        max_wait_time_ms attrs.max_wait_time_ms if attrs.max_wait_time_ms
      end
      ResourceReference.new(
        type: 'cloudflare_queue_consumer',
        name: name,
        resource_attributes: attrs.to_h,
        outputs: { id: "${cloudflare_queue_consumer.#{name}.id}" }
      )
    end
  end
  module Cloudflare
    include CloudflareQueueConsumer
  end
end
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
