# frozen_string_literal: true
require 'spec_helper'
require 'terraform-synthesizer'
require 'pangea/resources/cloudflare_zone_dns_settings/resource'

RSpec.describe 'cloudflare_zone_dns_settings synthesis' do
  include Pangea::Resources::Cloudflare
  it 'synthesizes' do
    TerraformSynthesizer.new.instance_eval do
      extend Pangea::Resources::Cloudflare
      cloudflare_zone_dns_settings(:test, { zone_id: "023e105f4ecef8ad9ca31a8372d0c353" })
    end
  end
end
