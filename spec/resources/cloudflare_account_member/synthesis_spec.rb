# frozen_string_literal: true
require 'spec_helper'
require 'terraform-synthesizer'
require 'pangea/resources/cloudflare_account_member/resource'

RSpec.describe 'cloudflare_account_member synthesis' do
  include Pangea::Resources::Cloudflare
  it 'synthesizes' do
    TerraformSynthesizer.new.instance_eval do
      extend Pangea::Resources::Cloudflare
      cloudflare_account_member(:test, {
        account_id: "f037e56e89293a057740de681ac9abbe",
        email_address: "user@example.com",
        role_ids: ["3536bcfad5faccb999b47003c79917fb"]
      })
    end
  end
end
