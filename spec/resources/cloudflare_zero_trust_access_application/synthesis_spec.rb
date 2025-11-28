# frozen_string_literal: true
# Copyright 2025 The Pangea Authors

require 'spec_helper'
require 'terraform-synthesizer'
require 'pangea/resources/cloudflare_zero_trust_access_application/resource'
require 'pangea/resources/cloudflare_zero_trust_access_application/types'

RSpec.describe 'cloudflare_zero_trust_access_application synthesis' do
  include Pangea::Resources::Cloudflare

  let(:synthesizer) { TerraformSynthesizer.new }
  let(:account_id) { "a" * 32 }

  describe 'self-hosted applications' do
    it 'synthesizes basic self-hosted app' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_zero_trust_access_application(:app, {
          account_id: "a" * 32,
          name: "Internal Dashboard",
          type: "self_hosted",
          domain: "dash.example.com"
        })
      end

      result = synthesizer.synthesis
      app = result[:resource][:cloudflare_zero_trust_access_application][:app]

      expect(app[:account_id]).to eq(account_id)
      expect(app[:name]).to eq("Internal Dashboard")
      expect(app[:type]).to eq("self_hosted")
      expect(app[:domain]).to eq("dash.example.com")
    end
  end

  describe 'SaaS applications' do
    it 'synthesizes SAML SaaS app' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_zero_trust_access_application(:saas, {
          account_id: "a" * 32,
          name: "Salesforce",
          type: "saas",
          saas_app: {
            auth_type: "saml",
            sp_entity_id: "salesforce-entity",
            sso_endpoint: "https://salesforce.com/sso"
          }
        })
      end

      result = synthesizer.synthesis
      app = result[:resource][:cloudflare_zero_trust_access_application][:saas]

      expect(app[:type]).to eq("saas")
      expect(app[:saas_app][:auth_type]).to eq("saml")
    end
  end
end
