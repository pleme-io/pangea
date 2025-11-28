# frozen_string_literal: true
require 'spec_helper'
require 'terraform-synthesizer'
require 'pangea/resources/cloudflare_zero_trust_access_group/resource'

RSpec.describe 'cloudflare_zero_trust_access_group synthesis' do
  include Pangea::Resources::Cloudflare
  it 'synthesizes' do
    TerraformSynthesizer.new.instance_eval do
      extend Pangea::Resources::Cloudflare
      cloudflare_zero_trust_access_group(:test, {
        account_id: "f037e56e89293a057740de681ac9abbe",
        name: "example group",
        include: [{ email: ["test@example.com"] }]
      })
    end
  end
end
