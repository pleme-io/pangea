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
require 'pangea/resources/aws_ebs_volume/resource'
require 'pangea/resources/aws_ebs_volume/types'

RSpec.describe 'Pangea::Resources::AWS#aws_ebs_volume' do
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
        mock_resource_context.define_singleton_method(:availability_zone) { |value| }
        mock_resource_context.define_singleton_method(:size) { |value| }
        mock_resource_context.define_singleton_method(:snapshot_id) { |value| }
        mock_resource_context.define_singleton_method(:type) { |value| }
        mock_resource_context.define_singleton_method(:iops) { |value| }
        mock_resource_context.define_singleton_method(:throughput) { |value| }
        mock_resource_context.define_singleton_method(:encrypted) { |value| }
        mock_resource_context.define_singleton_method(:kms_key_id) { |value| }
        mock_resource_context.define_singleton_method(:multi_attach_enabled) { |value| }
        mock_resource_context.define_singleton_method(:outpost_arn) { |value| }
        mock_resource_context.define_singleton_method(:tags) { |&inner_block| }
        mock_resource_context.instance_eval(&block)
      end
    end
  end

  describe '#aws_ebs_volume' do
    context 'with valid attributes' do
      it 'creates a basic gp3 volume' do
        result = aws_ebs_volume(:test_volume, {
          availability_zone: "us-east-1a",
          size: 100
        })
        
        expect(result).to be_a(Pangea::Resources::ResourceReference)
        expect(result.type).to eq('aws_ebs_volume')
        expect(result.name).to eq(:test_volume)
      end
      
      it 'creates a gp3 volume with custom IOPS and throughput' do
        result = aws_ebs_volume(:high_perf_volume, {
          availability_zone: "us-east-1a",
          size: 100,
          type: "gp3",
          iops: 5000,
          throughput: 250
        })
        
        expect(result.resource_attributes[:iops]).to eq(5000)
        expect(result.resource_attributes[:throughput]).to eq(250)
      end
      
      it 'creates an io2 volume with provisioned IOPS' do
        result = aws_ebs_volume(:io2_volume, {
          availability_zone: "us-east-1a",
          size: 100,
          type: "io2",
          iops: 10000,
          multi_attach_enabled: true
        })
        
        expect(result.resource_attributes[:type]).to eq("io2")
        expect(result.resource_attributes[:iops]).to eq(10000)
        expect(result.resource_attributes[:multi_attach_enabled]).to be true
      end
      
      it 'creates a volume from snapshot' do
        result = aws_ebs_volume(:snapshot_volume, {
          availability_zone: "us-east-1a",
          snapshot_id: "snap-12345678"
        })
        
        expect(result.resource_attributes[:snapshot_id]).to eq("snap-12345678")
        expect(result.from_snapshot?).to be true
      end
      
      it 'creates an encrypted volume with KMS key' do
        result = aws_ebs_volume(:encrypted_volume, {
          availability_zone: "us-east-1a",
          size: 200,
          encrypted: true,
          kms_key_id: "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"
        })
        
        expect(result.resource_attributes[:encrypted]).to be true
        expect(result.resource_attributes[:kms_key_id]).to include("arn:aws:kms")
      end
      
      it 'creates a throughput optimized HDD volume' do
        result = aws_ebs_volume(:st1_volume, {
          availability_zone: "us-east-1a",
          size: 500,
          type: "st1"
        })
        
        expect(result.resource_attributes[:type]).to eq("st1")
        expect(result.throughput_optimized?).to be true
      end
      
      it 'creates a cold storage volume' do
        result = aws_ebs_volume(:cold_storage, {
          availability_zone: "us-east-1a",
          size: 1000,
          type: "sc1",
          tags: {
            Name: "archive-storage",
            Retention: "long-term"
          }
        })
        
        expect(result.cold_storage?).to be true
        expect(result.resource_attributes[:tags]).to include(Retention: "long-term")
      end
      
      it 'returns reference with all terraform outputs' do
        result = aws_ebs_volume(:full_output, {
          availability_zone: "us-east-1a",
          size: 50
        })
        
        expect(result.id).to eq("${aws_ebs_volume.full_output.id}")
        expect(result.arn).to eq("${aws_ebs_volume.full_output.arn}")
        expect(result.size).to eq("${aws_ebs_volume.full_output.size}")
        expect(result.type).to eq("${aws_ebs_volume.full_output.type}")
        expect(result.iops).to eq("${aws_ebs_volume.full_output.iops}")
        expect(result.throughput).to eq("${aws_ebs_volume.full_output.throughput}")
      end
      
      it 'provides computed properties' do
        result = aws_ebs_volume(:computed_props, {
          availability_zone: "us-east-1a",
          size: 100,
          type: "gp3"
        })
        
        expect(result.gp3?).to be true
        expect(result.supports_encryption?).to be true
        expect(result.supports_multi_attach?).to be false
        expect(result.default_iops).to eq(3000)
        expect(result.default_throughput).to eq(125)
        expect(result.estimated_monthly_cost_usd).to be_a(Float)
      end
    end
    
    context 'with invalid attributes' do
      it 'raises error for missing availability_zone' do
        expect {
          aws_ebs_volume(:invalid, {
            size: 100
          })
        }.to raise_error(Dry::Struct::Error, /availability_zone is missing/)
      end
      
      it 'raises error for missing size when not from snapshot' do
        expect {
          aws_ebs_volume(:invalid, {
            availability_zone: "us-east-1a",
            type: "gp3"
          })
        }.to raise_error(Dry::Struct::Error, /Size is required/)
      end
      
      it 'raises error for missing IOPS on io1/io2 volumes' do
        expect {
          aws_ebs_volume(:invalid, {
            availability_zone: "us-east-1a",
            size: 100,
            type: "io1"
          })
        }.to raise_error(Dry::Struct::Error, /IOPS is required for volume type 'io1'/)
      end
      
      it 'raises error for excessive IOPS' do
        expect {
          aws_ebs_volume(:invalid, {
            availability_zone: "us-east-1a",
            size: 100,
            type: "io2",
            iops: 60000  # Exceeds 500 IOPS per GiB limit
          })
        }.to raise_error(Dry::Struct::Error, /IOPS.*exceeds maximum/)
      end
      
      it 'raises error for throughput on non-gp3 volumes' do
        expect {
          aws_ebs_volume(:invalid, {
            availability_zone: "us-east-1a",
            size: 100,
            type: "gp2",
            throughput: 250
          })
        }.to raise_error(Dry::Struct::Error, /Throughput can only be specified for gp3 volumes/)
      end
      
      it 'raises error for multi-attach on non-io volumes' do
        expect {
          aws_ebs_volume(:invalid, {
            availability_zone: "us-east-1a",
            size: 100,
            type: "gp3",
            multi_attach_enabled: true
          })
        }.to raise_error(Dry::Struct::Error, /Multi-Attach is only supported for io1 and io2/)
      end
      
      it 'raises error for KMS key without encryption' do
        expect {
          aws_ebs_volume(:invalid, {
            availability_zone: "us-east-1a",
            size: 100,
            kms_key_id: "arn:aws:kms:..."
          })
        }.to raise_error(Dry::Struct::Error, /kms_key_id can only be specified when encrypted is true/)
      end
    end
  end
  
  describe Pangea::Resources::AWS::EbsVolumeAttributes do
    describe 'validation' do
      it 'validates size limits for gp3' do
        expect {
          described_class.new(
            availability_zone: "us-east-1a",
            size: 16385,  # Too large
            type: "gp3"
          )
        }.to raise_error(Dry::Struct::Error, /Size for gp3 volumes must be between 1 and 16384/)
      end
      
      it 'validates size limits for st1' do
        expect {
          described_class.new(
            availability_zone: "us-east-1a",
            size: 100,  # Too small
            type: "st1"
          )
        }.to raise_error(Dry::Struct::Error, /Size for st1 volumes must be between 125 and 16384/)
      end
      
      it 'validates IOPS ratios for io2' do
        expect {
          described_class.new(
            availability_zone: "us-east-1a",
            size: 10,
            type: "io2",
            iops: 6000  # Exceeds 500 IOPS per GiB
          )
        }.to raise_error(Dry::Struct::Error, /IOPS.*exceeds maximum/)
      end
      
      it 'validates throughput ratios for gp3' do
        expect {
          described_class.new(
            availability_zone: "us-east-1a",
            size: 100,
            type: "gp3",
            iops: 3000,
            throughput: 1000  # Exceeds 4:1 ratio with IOPS
          )
        }.to raise_error(Dry::Struct::Error, /Throughput.*exceeds maximum/)
      end
    end
    
    describe '#default_iops' do
      it 'returns 3000 for gp3' do
        volume = described_class.new(
          availability_zone: "us-east-1a",
          size: 100,
          type: "gp3"
        )
        expect(volume.default_iops).to eq(3000)
      end
      
      it 'calculates IOPS for gp2' do
        volume = described_class.new(
          availability_zone: "us-east-1a",
          size: 1000,
          type: "gp2"
        )
        expect(volume.default_iops).to eq(3000)  # 3 * 1000
      end
      
      it 'returns nil for io1/io2' do
        volume = described_class.new(
          availability_zone: "us-east-1a",
          size: 100,
          type: "io1",
          iops: 5000
        )
        expect(volume.default_iops).to be_nil
      end
    end
    
    describe '#estimated_monthly_cost_usd' do
      it 'calculates cost for gp3 volume' do
        volume = described_class.new(
          availability_zone: "us-east-1a",
          size: 100,
          type: "gp3"
        )
        expect(volume.estimated_monthly_cost_usd).to eq(8.00)  # $0.08 * 100 GB
      end
      
      it 'calculates cost for gp3 with extra throughput' do
        volume = described_class.new(
          availability_zone: "us-east-1a",
          size: 100,
          type: "gp3",
          throughput: 225  # 100 MiB/s extra
        )
        expect(volume.estimated_monthly_cost_usd).to eq(12.00)  # $8 + $4 for extra throughput
      end
      
      it 'calculates cost for io2 with IOPS' do
        volume = described_class.new(
          availability_zone: "us-east-1a",
          size: 100,
          type: "io2",
          iops: 5000
        )
        cost = 100 * 0.125 + 5000 * 0.065  # Storage + IOPS
        expect(volume.estimated_monthly_cost_usd).to eq(337.50)
      end
      
      it 'calculates cost for cold storage' do
        volume = described_class.new(
          availability_zone: "us-east-1a",
          size: 1000,
          type: "sc1"
        )
        expect(volume.estimated_monthly_cost_usd).to eq(15.00)  # $0.015 * 1000 GB
      end
    end
    
    describe 'computed properties' do
      it 'identifies provisioned IOPS volumes' do
        io1 = described_class.new(
          availability_zone: "us-east-1a",
          size: 100,
          type: "io1",
          iops: 5000
        )
        expect(io1.provisioned_iops?).to be true
        
        gp3 = described_class.new(
          availability_zone: "us-east-1a",
          size: 100,
          type: "gp3"
        )
        expect(gp3.provisioned_iops?).to be false
      end
      
      it 'identifies throughput optimized volumes' do
        st1 = described_class.new(
          availability_zone: "us-east-1a",
          size: 500,
          type: "st1"
        )
        expect(st1.throughput_optimized?).to be true
      end
      
      it 'identifies volumes created from snapshot' do
        from_snap = described_class.new(
          availability_zone: "us-east-1a",
          snapshot_id: "snap-12345678"
        )
        expect(from_snap.from_snapshot?).to be true
        
        from_scratch = described_class.new(
          availability_zone: "us-east-1a",
          size: 100
        )
        expect(from_scratch.from_snapshot?).to be false
      end
    end
  end
end