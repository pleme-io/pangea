# frozen_string_literal: true
require 'spec_helper'
require 'terraform-synthesizer'
require 'pangea/resources/cloudflare_pages_domain/resource'

RSpec.describe 'cloudflare_pages_domain synthesis' do
  include Pangea::Resources::Cloudflare
  it 'synthesizes pages domain' do
    TerraformSynthesizer.new.instance_eval do
      extend Pangea::Resources::Cloudflare
      cloudflare_pages_domain(:domain, {
        account_id: "a" * 32,
        project_name: "my-project",
        domain: "example.com"
      })
    end
  end
end
