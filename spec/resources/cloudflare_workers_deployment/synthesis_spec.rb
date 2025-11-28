# frozen_string_literal: true
require 'spec_helper'
require 'terraform-synthesizer'
require 'pangea/resources/cloudflare_workers_deployment/resource'

RSpec.describe 'cloudflare_workers_deployment synthesis' do
  include Pangea::Resources::Cloudflare
  it 'synthesizes' do
    TerraformSynthesizer.new.instance_eval do
      extend Pangea::Resources::Cloudflare
      cloudflare_workers_deployment(:test, {
        account_id: "f037e56e89293a057740de681ac9abbe",
        script_name: "my-worker"
      })
    end
  end
end
