# frozen_string_literal: true
require 'spec_helper'
require 'terraform-synthesizer'
require 'pangea/resources/cloudflare_mtls_certificate/resource'

RSpec.describe 'cloudflare_mtls_certificate synthesis' do
  include Pangea::Resources::Cloudflare
  it 'synthesizes' do
    TerraformSynthesizer.new.instance_eval do
      extend Pangea::Resources::Cloudflare
      cloudflare_mtls_certificate(:test, { account_id: "f037e56e89293a057740de681ac9abbe", ca: true, certificates: "-----BEGIN CERTIFICATE-----\n...\n-----END CERTIFICATE-----" })
    end
  end
end
