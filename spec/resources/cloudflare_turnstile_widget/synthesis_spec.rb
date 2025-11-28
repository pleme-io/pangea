# frozen_string_literal: true
require 'spec_helper'
require 'terraform-synthesizer'
require 'pangea/resources/cloudflare_turnstile_widget/resource'

RSpec.describe 'cloudflare_turnstile_widget synthesis' do
  include Pangea::Resources::Cloudflare
  it 'synthesizes turnstile widget' do
    TerraformSynthesizer.new.instance_eval do
      extend Pangea::Resources::Cloudflare
      cloudflare_turnstile_widget(:widget, {
        account_id: "a" * 32,
        name: "My Widget",
        domains: ["example.com"],
        mode: "managed"
      })
    end
  end
end
