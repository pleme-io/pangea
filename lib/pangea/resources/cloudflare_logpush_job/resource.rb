# frozen_string_literal: true
require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/cloudflare_logpush_job/types'
require 'pangea/resource_registry'

module Pangea::Resources
  module CloudflareLogpushJob
    def cloudflare_logpush_job(name, attributes = {})
      attrs = Cloudflare::Types::LogpushJobAttributes.new(attributes)
      resource(:cloudflare_logpush_job, name) do
        zone_id attrs.zone_id if attrs.zone_id
        account_id attrs.account_id if attrs.account_id
        dataset attrs.dataset
        destination_conf attrs.destination_conf
        enabled attrs.enabled if !attrs.enabled.nil?
        filter attrs.filter if attrs.filter
        frequency attrs.frequency if attrs.frequency
        kind attrs.kind if attrs.kind
        logpull_options attrs.logpull_options if attrs.logpull_options
        max_upload_bytes attrs.max_upload_bytes if attrs.max_upload_bytes
        max_upload_interval_seconds attrs.max_upload_interval_seconds if attrs.max_upload_interval_seconds
        max_upload_records attrs.max_upload_records if attrs.max_upload_records
        name attrs.name if attrs.name
        output_options attrs.output_options if attrs.output_options
        ownership_challenge attrs.ownership_challenge if attrs.ownership_challenge
      end
      ResourceReference.new(
        type: 'cloudflare_logpush_job',
        name: name,
        resource_attributes: attrs.to_h,
        outputs: { id: "${cloudflare_logpush_job.#{name}.id}" }
      )
    end
  end
  module Cloudflare
    include CloudflareLogpushJob
  end
end
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
