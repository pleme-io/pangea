# frozen_string_literal: true
require 'spec_helper'
require 'terraform-synthesizer'
require 'pangea/resources/cloudflare_r2_bucket_event_notification/resource'

RSpec.describe 'cloudflare_r2_bucket_event_notification synthesis' do
  include Pangea::Resources::Cloudflare
  it 'synthesizes' do
    TerraformSynthesizer.new.instance_eval do
      extend Pangea::Resources::Cloudflare
      cloudflare_r2_bucket_event_notification(:test, {
        account_id: "f037e56e89293a057740de681ac9abbe",
        bucket: "my-bucket",
        queue: "my-queue"
      })
    end
  end
end
