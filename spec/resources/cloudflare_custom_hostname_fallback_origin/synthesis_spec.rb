# frozen_string_literal: true
require 'spec_helper'
require 'terraform-synthesizer'
require 'pangea/resources/cloudflare_custom_hostname_fallback_origin/resource'

RSpec.describe 'cloudflare_custom_hostname_fallback_origin synthesis' do
  include Pangea::Resources::Cloudflare
  it 'synthesizes' do
    TerraformSynthesizer.new.instance_eval do
      extend Pangea::Resources::Cloudflare
      cloudflare_custom_hostname_fallback_origin(:test, { zone_id: "023e105f4ecef8ad9ca31a8372d0c353" })
    end
  end
end
