# frozen_string_literal: true
require 'spec_helper'
require 'terraform-synthesizer'
require 'pangea/resources/cloudflare_cloudforce_one_request_asset/resource'

RSpec.describe 'cloudflare_cloudforce_one_request_asset synthesis' do
  include Pangea::Resources::Cloudflare
  it 'synthesizes' do
    TerraformSynthesizer.new.instance_eval do
      extend Pangea::Resources::Cloudflare
      cloudflare_cloudforce_one_request_asset(:test, { account_id: "f037e56e89293a057740de681ac9abbe" })
    end
  end
end
