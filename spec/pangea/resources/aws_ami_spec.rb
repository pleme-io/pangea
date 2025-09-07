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
require 'pangea/resources/aws_ami/resource'
require 'pangea/resources/aws_ami/types'

RSpec.describe 'Pangea::Resources::AWS#aws_ami' do
  include Pangea::Resources::AWS
  
  let(:mock_terraform_synthesizer) { instance_double(TerraformSynthesizer) }
  let(:mock_synthesis_context) { double('SynthesisContext') }
  
  before do
    allow(TerraformSynthesizer).to receive(:new).and_return(mock_terraform_synthesizer)
    allow(mock_terraform_synthesizer).to receive(:instance_eval)
    allow(mock_terraform_synthesizer).to receive(:synthesis).and_return(mock_synthesis_context)
    
    # Mock the resource method
    allow(self).to receive(:resource) do |resource_type, name, &block|
      if block_given?
        mock_resource_context = Object.new
        mock_resource_context.define_singleton_method(:name) { |value| }
        mock_resource_context.define_singleton_method(:description) { |value| }
        mock_resource_context.define_singleton_method(:architecture) { |value| }
        mock_resource_context.define_singleton_method(:boot_mode) { |value| }
        mock_resource_context.define_singleton_method(:deprecation_time) { |value| }
        mock_resource_context.define_singleton_method(:ena_support) { |value| }
        mock_resource_context.define_singleton_method(:image_location) { |value| }
        mock_resource_context.define_singleton_method(:imds_support) { |value| }
        mock_resource_context.define_singleton_method(:kernel_id) { |value| }
        mock_resource_context.define_singleton_method(:ramdisk_id) { |value| }
        mock_resource_context.define_singleton_method(:root_device_name) { |value| }
        mock_resource_context.define_singleton_method(:sriov_net_support) { |value| }
        mock_resource_context.define_singleton_method(:tpm_support) { |value| }
        mock_resource_context.define_singleton_method(:virtualization_type) { |value| }
        mock_resource_context.define_singleton_method(:ebs_block_device) { |&inner_block| }
        mock_resource_context.define_singleton_method(:ephemeral_block_device) { |&inner_block| }
        mock_resource_context.define_singleton_method(:tags) { |&inner_block| }
        mock_resource_context.instance_eval(&block)
      end
    end
  end

  describe '#aws_ami' do
    context 'with valid attributes' do
      it 'creates a basic AMI' do
        result = aws_ami(:test_ami, {
          name: "test-ami-x86_64"
        })
        
        expect(result).to be_a(Pangea::Resources::ResourceReference)
        expect(result.type).to eq('aws_ami')
        expect(result.name).to eq(:test_ami)
      end
      
      it 'creates an AMI with description' do
        result = aws_ami(:described_ami, {
          name: "production-base-ami",
          description: "Production base image with security hardening"
        })
        
        expect(result.resource_attributes[:description]).to eq("Production base image with security hardening")
      end
      
      it 'creates an AMI with EBS block devices' do
        result = aws_ami(:ebs_ami, {
          name: "app-ami-with-storage",
          ebs_block_device: [
            {
              device_name: "/dev/sda1",
              volume_size: 20,
              volume_type: "gp3",
              encrypted: true,
              delete_on_termination: true
            }
          ]
        })
        
        expect(result.resource_attributes[:ebs_block_device]).to have(1).item
        expect(result.encrypted_by_default?).to be true
        expect(result.total_storage_size).to eq(20)
      end
      
      it 'creates an AMI with ephemeral block devices' do
        result = aws_ami(:instance_store_ami, {
          name: "instance-store-ami",
          ephemeral_block_device: [
            {
              device_name: "/dev/sdb",
              virtual_name: "ephemeral0"
            }
          ]
        })
        
        expect(result.has_instance_store?).to be true
      end
      
      it 'creates an ARM64 AMI' do
        result = aws_ami(:arm_ami, {
          name: "graviton-base-ami",
          architecture: "arm64",
          ena_support: true
        })
        
        expect(result.resource_attributes[:architecture]).to eq("arm64")
        expect(result.modern_ami?).to be true
        expect(result.recommended_instance_types).to include("t4g.micro")
      end
      
      it 'creates a UEFI boot mode AMI' do
        result = aws_ami(:uefi_ami, {
          name: "uefi-secure-boot-ami",
          boot_mode: "uefi",
          virtualization_type: "hvm"
        })
        
        expect(result.resource_attributes[:boot_mode]).to eq("uefi")
        expect(result.compatible_with_nitro?).to be true
      end
      
      it 'creates an AMI with TPM support' do
        result = aws_ami(:tpm_ami, {
          name: "secure-tpm-ami",
          tpm_support: "v2.0",
          boot_mode: "uefi"
        })
        
        expect(result.resource_attributes[:tpm_support]).to eq("v2.0")
      end
      
      it 'creates an AMI with deprecation time' do
        result = aws_ami(:deprecated_ami, {
          name: "legacy-ami",
          deprecation_time: "2025-12-31T23:59:59Z"
        })
        
        expect(result.resource_attributes[:deprecation_time]).to eq("2025-12-31T23:59:59Z")
      end
      
      it 'returns reference with all terraform outputs' do
        result = aws_ami(:full_output, {
          name: "test-ami"
        })
        
        expect(result.id).to eq("${aws_ami.full_output.id}")
        expect(result.arn).to eq("${aws_ami.full_output.arn}")
        expect(result[:name]).to eq("${aws_ami.full_output.name}")
        expect(result.creation_date).to eq("${aws_ami.full_output.creation_date}")
        expect(result.state).to eq("${aws_ami.full_output.state}")
        expect(result.virtualization_type).to eq("${aws_ami.full_output.virtualization_type}")
      end
      
      it 'provides computed properties' do
        result = aws_ami(:computed_props, {
          name: "modern-ami",
          architecture: "x86_64",
          virtualization_type: "hvm",
          ena_support: true,
          sriov_net_support: "simple"
        })
        
        expect(result.modern_ami?).to be true
        expect(result.supports_sriov?).to be true
        expect(result.compatible_with_nitro?).to be true
        expect(result.estimated_monthly_cost).to be_a(Numeric)
        expect(result.recommended_instance_types).to include("t3.micro", "m5.large")
      end
    end
    
    context 'with invalid attributes' do
      it 'raises error for missing name' do
        expect {
          aws_ami(:invalid, {})
        }.to raise_error(Dry::Struct::Error, /name is missing/)
      end
      
      it 'raises error for invalid deprecation time format' do
        expect {
          aws_ami(:invalid, {
            name: "test-ami",
            deprecation_time: "2025/12/31"
          })
        }.to raise_error(Dry::Struct::Error, /deprecation_time must be in ISO 8601 format/)
      end
      
      it 'raises error for i386 with HVM' do
        expect {
          aws_ami(:invalid, {
            name: "test-ami",
            architecture: "i386",
            virtualization_type: "hvm"
          })
        }.to raise_error(Dry::Struct::Error, /i386 architecture is not compatible with hvm/)
      end
      
      it 'raises error for UEFI with paravirtual' do
        expect {
          aws_ami(:invalid, {
            name: "test-ami",
            boot_mode: "uefi",
            virtualization_type: "paravirtual"
          })
        }.to raise_error(Dry::Struct::Error, /UEFI boot mode is only compatible with hvm/)
      end
      
      it 'raises error for TPM with paravirtual' do
        expect {
          aws_ami(:invalid, {
            name: "test-ami",
            tpm_support: "v2.0",
            virtualization_type: "paravirtual"
          })
        }.to raise_error(Dry::Struct::Error, /TPM support is only compatible with hvm/)
      end
    end
  end
  
  describe Pangea::Resources::AWS::AmiAttributes do
    describe 'validation' do
      it 'validates deprecation time format' do
        expect {
          described_class.new(
            name: "test-ami",
            deprecation_time: "2025-12-31T23:59:59Z"
          )
        }.not_to raise_error
        
        expect {
          described_class.new(
            name: "test-ami",
            deprecation_time: "invalid-date"
          )
        }.to raise_error(Dry::Struct::Error)
      end
      
      it 'validates architecture compatibility' do
        expect {
          described_class.new(
            name: "test-ami",
            architecture: "x86_64",
            virtualization_type: "hvm"
          )
        }.not_to raise_error
        
        expect {
          described_class.new(
            name: "test-ami",
            architecture: "i386",
            virtualization_type: "paravirtual"
          )
        }.not_to raise_error
      end
      
      it 'validates IMDS support compatibility' do
        expect {
          described_class.new(
            name: "test-ami",
            imds_support: "v2.0",
            virtualization_type: "paravirtual"
          )
        }.to raise_error(Dry::Struct::Error, /IMDS support is only compatible with hvm/)
      end
    end
    
    describe '#modern_ami?' do
      it 'identifies modern AMIs' do
        modern = described_class.new(
          name: "modern-ami",
          virtualization_type: "hvm",
          ena_support: true
        )
        expect(modern.modern_ami?).to be true
        
        legacy = described_class.new(
          name: "legacy-ami",
          virtualization_type: "paravirtual"
        )
        expect(legacy.modern_ami?).to be false
      end
    end
    
    describe '#encrypted_by_default?' do
      it 'checks EBS encryption' do
        encrypted = described_class.new(
          name: "encrypted-ami",
          ebs_block_device: [
            { device_name: "/dev/sda1", encrypted: true }
          ]
        )
        expect(encrypted.encrypted_by_default?).to be true
        
        unencrypted = described_class.new(
          name: "unencrypted-ami",
          ebs_block_device: [
            { device_name: "/dev/sda1", encrypted: false }
          ]
        )
        expect(unencrypted.encrypted_by_default?).to be false
      end
    end
    
    describe '#total_storage_size' do
      it 'calculates total EBS storage' do
        ami = described_class.new(
          name: "multi-volume-ami",
          ebs_block_device: [
            { device_name: "/dev/sda1", volume_size: 20 },
            { device_name: "/dev/sdb", volume_size: 100 },
            { device_name: "/dev/sdc", volume_size: 50 }
          ]
        )
        expect(ami.total_storage_size).to eq(170)
      end
    end
    
    describe '#root_volume_size' do
      it 'finds root volume size' do
        ami = described_class.new(
          name: "root-volume-ami",
          root_device_name: "/dev/sda1",
          ebs_block_device: [
            { device_name: "/dev/sda1", volume_size: 30 },
            { device_name: "/dev/sdb", volume_size: 100 }
          ]
        )
        expect(ami.root_volume_size).to eq(30)
      end
    end
    
    describe '#compatible_with_nitro?' do
      it 'checks Nitro compatibility' do
        compatible = described_class.new(
          name: "nitro-ami",
          boot_mode: "uefi",
          virtualization_type: "hvm"
        )
        expect(compatible.compatible_with_nitro?).to be true
        
        incompatible = described_class.new(
          name: "legacy-bios-ami",
          boot_mode: "legacy-bios",
          virtualization_type: "hvm"
        )
        expect(incompatible.compatible_with_nitro?).to be false
      end
    end
    
    describe '#recommended_instance_types' do
      it 'recommends appropriate instances for x86_64' do
        x86_ami = described_class.new(
          name: "x86-ami",
          architecture: "x86_64"
        )
        expect(x86_ami.recommended_instance_types).to include("t3.micro", "m5.large")
      end
      
      it 'recommends appropriate instances for arm64' do
        arm_ami = described_class.new(
          name: "arm-ami",
          architecture: "arm64"
        )
        expect(arm_ami.recommended_instance_types).to include("t4g.micro", "m6g.large")
      end
      
      it 'limits instances for i386' do
        i386_ami = described_class.new(
          name: "i386-ami",
          architecture: "i386"
        )
        expect(i386_ami.recommended_instance_types).to eq(["t2.micro", "t2.small"])
      end
    end
  end
end