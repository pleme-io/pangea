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
require 'pangea/resources/aws_ami/resource'
require 'pangea/resources/aws_ami/types'

RSpec.describe 'aws_ami synthesis' do
  include Pangea::Resources::AWS
  
  let(:synthesizer) { TerraformSynthesizer.new }
  
  describe 'terraform synthesis' do
    it 'synthesizes basic AMI' do
      synthesizer.instance_eval do
        aws_ami(:basic_ami, {
          name: "basic-ami-2025"
        })
      end
      
      result = synthesizer.synthesis
      ami = result[:resource][:aws_ami][:basic_ami]
      
      expect(ami).to include(
        name: "basic-ami-2025",
        architecture: "x86_64",      # Default
        virtualization_type: "hvm"    # Default
      )
      expect(ami).not_to have_key(:description)
      expect(ami).not_to have_key(:boot_mode)
    end
    
    it 'synthesizes AMI with description and tags' do
      synthesizer.instance_eval do
        aws_ami(:tagged_ami, {
          name: "production-base-2025-01",
          description: "Production base AMI with security hardening",
          tags: {
            Environment: "production",
            Version: "2025.01",
            Hardened: "true"
          }
        })
      end
      
      result = synthesizer.synthesis
      ami = result[:resource][:aws_ami][:tagged_ami]
      
      expect(ami[:name]).to eq("production-base-2025-01")
      expect(ami[:description]).to eq("Production base AMI with security hardening")
      expect(ami[:tags]).to include(
        Environment: "production",
        Version: "2025.01",
        Hardened: "true"
      )
    end
    
    it 'synthesizes ARM64 AMI with modern features' do
      synthesizer.instance_eval do
        aws_ami(:arm_ami, {
          name: "graviton-optimized-ami",
          architecture: "arm64",
          virtualization_type: "hvm",
          ena_support: true,
          sriov_net_support: "simple",
          imds_support: "v2.0",
          tags: {
            Name: "Graviton Optimized",
            Architecture: "ARM64"
          }
        })
      end
      
      result = synthesizer.synthesis
      ami = result[:resource][:aws_ami][:arm_ami]
      
      expect(ami[:architecture]).to eq("arm64")
      expect(ami[:ena_support]).to be true
      expect(ami[:sriov_net_support]).to eq("simple")
      expect(ami[:imds_support]).to eq("v2.0")
    end
    
    it 'synthesizes AMI with EBS block devices' do
      synthesizer.instance_eval do
        aws_ami(:ebs_ami, {
          name: "multi-volume-ami",
          root_device_name: "/dev/sda1",
          ebs_block_device: [
            {
              device_name: "/dev/sda1",
              volume_size: 30,
              volume_type: "gp3",
              iops: 3000,
              throughput: 125,
              encrypted: true,
              delete_on_termination: true
            },
            {
              device_name: "/dev/sdb",
              volume_size: 100,
              volume_type: "gp3",
              encrypted: true,
              delete_on_termination: false
            }
          ]
        })
      end
      
      result = synthesizer.synthesis
      ami = result[:resource][:aws_ami][:ebs_ami]
      
      expect(ami[:root_device_name]).to eq("/dev/sda1")
      expect(ami[:ebs_block_device]).to have(2).items
      
      root_device = ami[:ebs_block_device].first
      expect(root_device[:device_name]).to eq("/dev/sda1")
      expect(root_device[:volume_size]).to eq(30)
      expect(root_device[:volume_type]).to eq("gp3")
      expect(root_device[:iops]).to eq(3000)
      expect(root_device[:throughput]).to eq(125)
      expect(root_device[:encrypted]).to be true
    end
    
    it 'synthesizes AMI with ephemeral block devices' do
      synthesizer.instance_eval do
        aws_ami(:instance_store_ami, {
          name: "instance-store-optimized",
          ephemeral_block_device: [
            {
              device_name: "/dev/sdb",
              virtual_name: "ephemeral0"
            },
            {
              device_name: "/dev/sdc",
              virtual_name: "ephemeral1"
            }
          ]
        })
      end
      
      result = synthesizer.synthesis
      ami = result[:resource][:aws_ami][:instance_store_ami]
      
      expect(ami[:ephemeral_block_device]).to have(2).items
      expect(ami[:ephemeral_block_device].first).to include(
        device_name: "/dev/sdb",
        virtual_name: "ephemeral0"
      )
    end
    
    it 'synthesizes secure boot AMI' do
      synthesizer.instance_eval do
        aws_ami(:secure_ami, {
          name: "secure-boot-uefi-tpm",
          boot_mode: "uefi",
          tpm_support: "v2.0",
          ena_support: true,
          ebs_block_device: [
            {
              device_name: "/dev/sda1",
              volume_size: 20,
              encrypted: true,
              kms_key_id: "arn:aws:kms:us-east-1:123456789012:key/12345678"
            }
          ],
          tags: {
            Security: "hardened",
            BootMode: "uefi",
            TPM: "enabled"
          }
        })
      end
      
      result = synthesizer.synthesis
      ami = result[:resource][:aws_ami][:secure_ami]
      
      expect(ami[:boot_mode]).to eq("uefi")
      expect(ami[:tpm_support]).to eq("v2.0")
      expect(ami[:ebs_block_device].first[:kms_key_id]).to include("arn:aws:kms")
    end
    
    it 'synthesizes AMI with deprecation schedule' do
      synthesizer.instance_eval do
        aws_ami(:deprecated_ami, {
          name: "legacy-ami-to-retire",
          deprecation_time: "2025-12-31T23:59:59Z",
          tags: {
            Status: "deprecated",
            RetireDate: "2025-12-31"
          }
        })
      end
      
      result = synthesizer.synthesis
      ami = result[:resource][:aws_ami][:deprecated_ami]
      
      expect(ami[:deprecation_time]).to eq("2025-12-31T23:59:59Z")
      expect(ami[:tags][:Status]).to eq("deprecated")
    end
    
    it 'synthesizes paravirtual AMI for legacy support' do
      synthesizer.instance_eval do
        aws_ami(:legacy_ami, {
          name: "legacy-paravirtual-ami",
          architecture: "x86_64",
          virtualization_type: "paravirtual",
          kernel_id: "aki-12345678",
          ramdisk_id: "ari-12345678"
        })
      end
      
      result = synthesizer.synthesis
      ami = result[:resource][:aws_ami][:legacy_ami]
      
      expect(ami[:virtualization_type]).to eq("paravirtual")
      expect(ami[:kernel_id]).to eq("aki-12345678")
      expect(ami[:ramdisk_id]).to eq("ari-12345678")
      expect(ami).not_to have_key(:ena_support)  # Not compatible with paravirtual
    end
    
    it 'handles empty tags gracefully' do
      synthesizer.instance_eval do
        aws_ami(:no_tags, {
          name: "untagged-ami",
          tags: {}
        })
      end
      
      result = synthesizer.synthesis
      ami = result[:resource][:aws_ami][:no_tags]
      
      expect(ami).not_to have_key(:tags)
    end
    
    it 'generates correct JSON for terraform' do
      synthesizer.instance_eval do
        aws_ami(:json_test, {
          name: "json-test-ami",
          description: "AMI for JSON output testing",
          architecture: "x86_64",
          ena_support: true,
          ebs_block_device: [
            {
              device_name: "/dev/sda1",
              volume_size: 50,
              volume_type: "gp3",
              encrypted: true
            }
          ],
          tags: {
            Name: "json-test",
            Purpose: "testing",
            Terraform: "true"
          }
        })
      end
      
      json_output = JSON.pretty_generate(synthesizer.synthesis)
      parsed = JSON.parse(json_output, symbolize_names: true)
      
      ami = parsed[:resource][:aws_ami][:json_test]
      expect(ami[:name]).to eq("json-test-ami")
      expect(ami[:description]).to eq("AMI for JSON output testing")
      expect(ami[:ebs_block_device]).to be_a(Array)
      expect(ami[:tags]).to be_a(Hash)
      expect(ami[:tags][:Terraform]).to eq("true")
    end
    
    it 'synthesizes complete AMI lifecycle' do
      synthesizer.instance_eval do
        # Base AMI
        aws_ami(:base, {
          name: "company-base-2025-01",
          description: "Base AMI with company standards",
          ena_support: true,
          tags: { Stage: "base", Version: "2025.01" }
        })
        
        # Application AMI built from base
        aws_ami(:app, {
          name: "company-app-2025-01",
          description: "Application AMI with runtime",
          ena_support: true,
          imds_support: "v2.0",
          tags: { Stage: "application", Version: "2025.01", BaseAMI: "company-base-2025-01" }
        })
        
        # Production AMI with security hardening
        aws_ami(:prod, {
          name: "company-prod-2025-01",
          description: "Production hardened AMI",
          boot_mode: "uefi",
          tpm_support: "v2.0",
          ena_support: true,
          imds_support: "v2.0",
          ebs_block_device: [
            {
              device_name: "/dev/sda1",
              volume_size: 100,
              encrypted: true,
              kms_key_id: "alias/production"
            }
          ],
          tags: { 
            Stage: "production", 
            Version: "2025.01", 
            Hardened: "true",
            Compliance: "PCI-DSS"
          }
        })
      end
      
      result = synthesizer.synthesis
      amis = result[:resource][:aws_ami]
      
      expect(amis).to have_key(:base)
      expect(amis).to have_key(:app)
      expect(amis).to have_key(:prod)
      
      expect(amis[:base][:tags][:Stage]).to eq("base")
      expect(amis[:app][:tags][:Stage]).to eq("application")
      expect(amis[:prod][:tags][:Stage]).to eq("production")
      expect(amis[:prod][:boot_mode]).to eq("uefi")
      expect(amis[:prod][:tpm_support]).to eq("v2.0")
    end
  end
end