# frozen_string_literal: true
# Copyright 2025 The Pangea Authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


require 'spec_helper'
require 'terraform-synthesizer'
require 'pangea/resources/hcloud_ssh_key/resource'
require 'pangea/resources/hcloud_ssh_key/types'

RSpec.describe 'hcloud_ssh_key synthesis' do
  include Pangea::Resources::Hetzner

  let(:synthesizer) { TerraformSynthesizer.new }

  describe 'terraform synthesis' do
    it 'synthesizes minimal ssh key configuration' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Hetzner
        hcloud_ssh_key(:deployer, {
          name: "deployer-key",
          public_key: "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAITest test@example.com"
        })
      end

      result = synthesizer.synthesis
      ssh_key = result[:resource][:hcloud_ssh_key][:deployer]

      expect(ssh_key[:name]).to eq("deployer-key")
      expect(ssh_key[:public_key]).to include("ssh-ed25519")
    end

    it 'synthesizes ssh key with labels' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Hetzner
        hcloud_ssh_key(:deployer, {
          name: "deployer-key",
          public_key: "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAITest test@example.com",
          labels: {
            environment: "production",
            managed_by: "pangea"
          }
        })
      end

      result = synthesizer.synthesis
      ssh_key = result[:resource][:hcloud_ssh_key][:deployer]

      expect(ssh_key[:labels][:environment]).to eq("production")
      expect(ssh_key[:labels][:managed_by]).to eq("pangea")
    end
  end

  describe 'resource references' do
    it 'provides correct terraform interpolation strings' do
      ref = synthesizer.instance_eval do
        extend Pangea::Resources::Hetzner
        hcloud_ssh_key(:test, {
          name: "test-key",
          public_key: "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAITest test@example.com"
        })
      end

      expect(ref.id).to eq("${hcloud_ssh_key.test.id}")
      expect(ref.outputs[:fingerprint]).to eq("${hcloud_ssh_key.test.fingerprint}")
      expect(ref.outputs[:name]).to eq("${hcloud_ssh_key.test.name}")
    end
  end
end
