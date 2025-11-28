# frozen_string_literal: true
require 'spec_helper'
require 'terraform-synthesizer'
require 'pangea/resources/cloudflare_queue_consumer/resource'

RSpec.describe 'cloudflare_queue_consumer synthesis' do
  include Pangea::Resources::Cloudflare
  it 'synthesizes queue consumer' do
    TerraformSynthesizer.new.instance_eval do
      extend Pangea::Resources::Cloudflare
      cloudflare_queue_consumer(:consumer, {
        account_id: "a" * 32,
        queue_id: "queue123",
        script_name: "my-worker"
      })
    end
  end
end
