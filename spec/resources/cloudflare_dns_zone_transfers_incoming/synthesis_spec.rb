# frozen_string_literal: true
require 'spec_helper'
require 'terraform-synthesizer'
require 'pangea/resources/cloudflare_dns_zone_transfers_incoming/resource'

RSpec.describe 'cloudflare_dns_zone_transfers_incoming synthesis' do
  include Pangea::Resources::Cloudflare
  it 'synthesizes' do
    TerraformSynthesizer.new.instance_eval do
      extend Pangea::Resources::Cloudflare
      cloudflare_dns_zone_transfers_incoming(:test, { zone_id: "023e105f4ecef8ad9ca31a8372d0c353" })
    end
  end
end
