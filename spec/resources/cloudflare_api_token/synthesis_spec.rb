# frozen_string_literal: true
require 'spec_helper'
require 'terraform-synthesizer'
require 'pangea/resources/cloudflare_api_token/resource'

RSpec.describe 'cloudflare_api_token synthesis' do
  include Pangea::Resources::Cloudflare
  it 'synthesizes' do
    TerraformSynthesizer.new.instance_eval do
      extend Pangea::Resources::Cloudflare
      cloudflare_api_token(:test, {
        name: "my-token",
        policy: [{ permission_groups: [{ id: "c8fed203ed3043cba015a93ad1616f1f" }], resources: { "com.cloudflare.api.account.*" => "*" } }]
      })
    end
  end
end
