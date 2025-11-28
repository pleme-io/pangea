# frozen_string_literal: true
require 'spec_helper'
require 'terraform-synthesizer'
require 'pangea/resources/cloudflare_authenticated_origin_pulls/resource'

RSpec.describe 'cloudflare_authenticated_origin_pulls synthesis' do
  include Pangea::Resources::Cloudflare
  it 'synthesizes' do
    TerraformSynthesizer.new.instance_eval do
      extend Pangea::Resources::Cloudflare
      cloudflare_authenticated_origin_pulls(:test, { zone_id: "023e105f4ecef8ad9ca31a8372d0c353", enabled: true })
    end
  end
end
