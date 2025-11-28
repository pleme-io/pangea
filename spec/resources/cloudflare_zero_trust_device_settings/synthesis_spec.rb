# frozen_string_literal: true
require 'spec_helper'
require 'terraform-synthesizer'
require 'pangea/resources/cloudflare_zero_trust_device_settings/resource'

RSpec.describe 'cloudflare_zero_trust_device_settings synthesis' do
  include Pangea::Resources::Cloudflare
  it 'synthesizes' do
    TerraformSynthesizer.new.instance_eval do
      extend Pangea::Resources::Cloudflare
      cloudflare_zero_trust_device_settings(:test, { account_id: "f037e56e89293a057740de681ac9abbe" })
    end
  end
end
