# frozen_string_literal: true
require 'spec_helper'
require 'terraform-synthesizer'
require 'pangea/resources/cloudflare_logpush_job/resource'

RSpec.describe 'cloudflare_logpush_job synthesis' do
  include Pangea::Resources::Cloudflare
  it 'synthesizes' do
    TerraformSynthesizer.new.instance_eval do
      extend Pangea::Resources::Cloudflare
      cloudflare_logpush_job(:test, {
        zone_id: "023e105f4ecef8ad9ca31a8372d0c353",
        dataset: "http_requests",
        destination_conf: "s3://my-bucket/logs?region=us-east-1"
      })
    end
  end
end
