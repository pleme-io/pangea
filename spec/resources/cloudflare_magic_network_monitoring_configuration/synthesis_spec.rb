# frozen_string_literal: true
require 'spec_helper'
require 'terraform-synthesizer'
require 'pangea/resources/cloudflare_magic_network_monitoring_configuration/resource'

RSpec.describe 'cloudflare_magic_network_monitoring_configuration synthesis' do
  include Pangea::Resources::Cloudflare
  it 'synthesizes' do
    TerraformSynthesizer.new.instance_eval do
      extend Pangea::Resources::Cloudflare
      cloudflare_magic_network_monitoring_configuration(:test, { account_id: "f037e56e89293a057740de681ac9abbe" })
    end
  end
end
