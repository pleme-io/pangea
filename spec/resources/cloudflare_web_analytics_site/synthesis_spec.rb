# frozen_string_literal: true
require 'spec_helper'
require 'terraform-synthesizer'
require 'pangea/resources/cloudflare_web_analytics_site/resource'

RSpec.describe 'cloudflare_web_analytics_site synthesis' do
  include Pangea::Resources::Cloudflare
  it 'synthesizes' do
    TerraformSynthesizer.new.instance_eval do
      extend Pangea::Resources::Cloudflare
      cloudflare_web_analytics_site(:test, {
        account_id: "f037e56e89293a057740de681ac9abbe",
        auto_install: true
      })
    end
  end
end
