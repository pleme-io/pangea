# frozen_string_literal: true
require 'spec_helper'
require 'terraform-synthesizer'
require 'pangea/resources/cloudflare_r2_bucket_lifecycle/resource'

RSpec.describe 'cloudflare_r2_bucket_lifecycle synthesis' do
  include Pangea::Resources::Cloudflare
  it 'synthesizes R2 bucket lifecycle' do
    TerraformSynthesizer.new.instance_eval do
      extend Pangea::Resources::Cloudflare
      cloudflare_r2_bucket_lifecycle(:lifecycle, {
        account_id: "a" * 32,
        bucket_name: "my-bucket",
        rules: [{
          enabled: true,
          prefix: "logs/",
          expiration: { days: 30 }
        }]
      })
    end
  end
end
