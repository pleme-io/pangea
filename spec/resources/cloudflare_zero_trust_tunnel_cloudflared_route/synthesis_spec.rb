# frozen_string_literal: true
require 'spec_helper'
require 'terraform-synthesizer'
require 'pangea/resources/cloudflare_zero_trust_tunnel_cloudflared_route/resource'

RSpec.describe 'cloudflare_zero_trust_tunnel_cloudflared_route synthesis' do
  include Pangea::Resources::Cloudflare
  it 'synthesizes' do
    TerraformSynthesizer.new.instance_eval do
      extend Pangea::Resources::Cloudflare
      cloudflare_zero_trust_tunnel_cloudflared_route(:test, {
        account_id: "f037e56e89293a057740de681ac9abbe",
        tunnel_id: "f70ff985-a4ef-4643-bbbc-4a0ed4fc8415",
        network: "192.168.0.0/24"
      })
    end
  end
end
