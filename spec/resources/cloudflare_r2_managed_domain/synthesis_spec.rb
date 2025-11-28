# frozen_string_literal: true
require 'spec_helper'
require 'terraform-synthesizer'
require 'pangea/resources/cloudflare_r2_managed_domain/resource'

RSpec.describe 'cloudflare_r2_managed_domain synthesis' do
  include Pangea::Resources::Cloudflare
  it 'synthesizes' do
    TerraformSynthesizer.new.instance_eval do
      extend Pangea::Resources::Cloudflare
      cloudflare_r2_managed_domain(:test, { account_id: "f037e56e89293a057740de681ac9abbe" })
    end
  end
end
