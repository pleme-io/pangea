# frozen_string_literal: true
# Copyright 2025 The Pangea Authors

require 'spec_helper'
require 'terraform-synthesizer'
require 'pangea/resources/hcloud_server/resource'

RSpec.describe 'hcloud_server synthesis' do
  include Pangea::Resources::Hetzner

  let(:synthesizer) { TerraformSynthesizer.new }

  describe 'terraform synthesis' do
    it 'synthesizes minimal server configuration' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Hetzner
        hcloud_server(:web, {
          name: "web-01",
          server_type: "cx23",
          location: "fsn1",
          image: "ubuntu-22.04"
        })
      end

      result = synthesizer.synthesis
      server = result[:resource][:hcloud_server][:web]

      expect(server[:name]).to eq("web-01")
      expect(server[:server_type]).to eq("cx23")
      expect(server[:location]).to eq("fsn1")
      expect(server[:image]).to eq("ubuntu-22.04")
    end

    it 'synthesizes server with ssh keys and firewall' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Hetzner
        hcloud_server(:web, {
          name: "web-01",
          server_type: "cx23",
          location: "fsn1",
          image: "ubuntu-22.04",
          ssh_keys: ["deployer-key"],
          firewall_ids: ["${hcloud_firewall.web.id}"]
        })
      end

      result = synthesizer.synthesis
      server = result[:resource][:hcloud_server][:web]

      expect(server[:ssh_keys]).to eq(["deployer-key"])
      expect(server[:firewall_ids]).to eq(["${hcloud_firewall.web.id}"])
    end

    it 'synthesizes server with public_net configuration' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Hetzner
        hcloud_server(:web, {
          name: "web-01",
          server_type: "cx23",
          location: "fsn1",
          image: "ubuntu-22.04",
          public_net: {
            ipv4_enabled: true,
            ipv6_enabled: false
          }
        })
      end

      result = synthesizer.synthesis
      server = result[:resource][:hcloud_server][:web]

      expect(server[:public_net][:ipv4_enabled]).to be true
      expect(server[:public_net][:ipv6_enabled]).to be false
    end

    it 'synthesizes server with user_data cloud-init' do
      cloud_init = <<~YAML
        #cloud-config
        packages:
          - nginx
      YAML

      synthesizer.instance_eval do
        extend Pangea::Resources::Hetzner
        hcloud_server(:web, {
          name: "web-01",
          server_type: "cx23",
          location: "fsn1",
          image: "ubuntu-22.04",
          user_data: cloud_init
        })
      end

      result = synthesizer.synthesis
      server = result[:resource][:hcloud_server][:web]

      expect(server[:user_data]).to include("#cloud-config")
      expect(server[:user_data]).to include("nginx")
    end

    it 'synthesizes server with labels' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Hetzner
        hcloud_server(:web, {
          name: "web-01",
          server_type: "cx23",
          location: "fsn1",
          image: "ubuntu-22.04",
          labels: {
            environment: "production",
            team: "platform"
          }
        })
      end

      result = synthesizer.synthesis
      server = result[:resource][:hcloud_server][:web]

      expect(server[:labels][:environment]).to eq("production")
      expect(server[:labels][:team]).to eq("platform")
    end
  end

  describe 'resource references' do
    it 'provides correct terraform interpolation strings' do
      ref = synthesizer.instance_eval do
        extend Pangea::Resources::Hetzner
        hcloud_server(:test, {
          name: "test-server",
          server_type: "cx23",
          location: "fsn1",
          image: "ubuntu-22.04"
        })
      end

      expect(ref.id).to eq("${hcloud_server.test.id}")
      expect(ref.outputs[:ipv4_address]).to eq("${hcloud_server.test.ipv4_address}")
      expect(ref.outputs[:status]).to eq("${hcloud_server.test.status}")
    end
  end
end
