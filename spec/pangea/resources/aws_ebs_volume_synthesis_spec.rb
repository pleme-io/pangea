# frozen_string_literal: true

require 'spec_helper'
require 'terraform-synthesizer'
require 'pangea/resources/aws_ebs_volume/resource'
require 'pangea/resources/aws_ebs_volume/types'

RSpec.describe 'aws_ebs_volume synthesis' do
  include Pangea::Resources::AWS
  
  let(:synthesizer) { TerraformSynthesizer.new }
  
  describe 'terraform synthesis' do
    it 'synthesizes basic gp3 volume' do
      synthesizer.instance_eval do
        aws_ebs_volume(:basic_volume, {
          availability_zone: "us-east-1a",
          size: 100
        })
      end
      
      result = synthesizer.synthesis
      volume = result[:resource][:aws_ebs_volume][:basic_volume]
      
      expect(volume).to include(
        availability_zone: "us-east-1a",
        size: 100,
        type: "gp3"  # Default type
      )
      expect(volume).not_to have_key(:iops)
      expect(volume).not_to have_key(:throughput)
    end
    
    it 'synthesizes gp3 volume with performance configuration' do
      synthesizer.instance_eval do
        aws_ebs_volume(:perf_volume, {
          availability_zone: "us-east-1b",
          size: 200,
          type: "gp3",
          iops: 6000,
          throughput: 250,
          tags: {
            Name: "high-performance-volume",
            Environment: "production"
          }
        })
      end
      
      result = synthesizer.synthesis
      volume = result[:resource][:aws_ebs_volume][:perf_volume]
      
      expect(volume[:availability_zone]).to eq("us-east-1b")
      expect(volume[:size]).to eq(200)
      expect(volume[:type]).to eq("gp3")
      expect(volume[:iops]).to eq(6000)
      expect(volume[:throughput]).to eq(250)
      expect(volume[:tags]).to include(
        Name: "high-performance-volume",
        Environment: "production"
      )
    end
    
    it 'synthesizes io2 volume with multi-attach' do
      synthesizer.instance_eval do
        aws_ebs_volume(:io2_shared, {
          availability_zone: "us-east-1a",
          size: 500,
          type: "io2",
          iops: 20000,
          multi_attach_enabled: true,
          encrypted: true,
          tags: {
            Name: "shared-io2-volume",
            Type: "database"
          }
        })
      end
      
      result = synthesizer.synthesis
      volume = result[:resource][:aws_ebs_volume][:io2_shared]
      
      expect(volume[:type]).to eq("io2")
      expect(volume[:iops]).to eq(20000)
      expect(volume[:multi_attach_enabled]).to be true
      expect(volume[:encrypted]).to be true
    end
    
    it 'synthesizes volume from snapshot' do
      synthesizer.instance_eval do
        aws_ebs_volume(:restored_volume, {
          availability_zone: "us-east-1c",
          snapshot_id: "snap-0123456789abcdef0",
          type: "gp3",
          iops: 4000
        })
      end
      
      result = synthesizer.synthesis
      volume = result[:resource][:aws_ebs_volume][:restored_volume]
      
      expect(volume[:availability_zone]).to eq("us-east-1c")
      expect(volume[:snapshot_id]).to eq("snap-0123456789abcdef0")
      expect(volume).not_to have_key(:size)  # Size inherited from snapshot
      expect(volume[:type]).to eq("gp3")
      expect(volume[:iops]).to eq(4000)
    end
    
    it 'synthesizes encrypted volume with KMS' do
      synthesizer.instance_eval do
        aws_ebs_volume(:encrypted_vol, {
          availability_zone: "us-west-2a",
          size: 150,
          encrypted: true,
          kms_key_id: "arn:aws:kms:us-west-2:123456789012:key/12345678-1234-1234-1234-123456789012",
          tags: {
            Name: "encrypted-data",
            Compliance: "required"
          }
        })
      end
      
      result = synthesizer.synthesis
      volume = result[:resource][:aws_ebs_volume][:encrypted_vol]
      
      expect(volume[:encrypted]).to be true
      expect(volume[:kms_key_id]).to include("arn:aws:kms")
      expect(volume[:tags][:Compliance]).to eq("required")
    end
    
    it 'synthesizes throughput optimized HDD' do
      synthesizer.instance_eval do
        aws_ebs_volume(:big_data, {
          availability_zone: "us-east-1a",
          size: 2000,
          type: "st1",
          tags: {
            Name: "big-data-storage",
            Workload: "sequential"
          }
        })
      end
      
      result = synthesizer.synthesis
      volume = result[:resource][:aws_ebs_volume][:big_data]
      
      expect(volume[:size]).to eq(2000)
      expect(volume[:type]).to eq("st1")
      expect(volume).not_to have_key(:iops)
      expect(volume).not_to have_key(:throughput)
    end
    
    it 'synthesizes cold storage volume' do
      synthesizer.instance_eval do
        aws_ebs_volume(:archive, {
          availability_zone: "us-east-1b",
          size: 5000,
          type: "sc1",
          encrypted: true,
          tags: {
            Name: "archive-storage",
            AccessPattern: "infrequent",
            Retention: "7years"
          }
        })
      end
      
      result = synthesizer.synthesis
      volume = result[:resource][:aws_ebs_volume][:archive]
      
      expect(volume[:size]).to eq(5000)
      expect(volume[:type]).to eq("sc1")
      expect(volume[:encrypted]).to be true
      expect(volume[:tags][:AccessPattern]).to eq("infrequent")
    end
    
    it 'synthesizes multiple volumes with references' do
      synthesizer.instance_eval do
        # Create volumes in different AZs
        aws_ebs_volume(:primary, {
          availability_zone: "us-east-1a",
          size: 100,
          type: "io2",
          iops: 5000,
          tags: { Role: "primary" }
        })
        
        aws_ebs_volume(:secondary, {
          availability_zone: "us-east-1b",
          size: 100,
          type: "io2",
          iops: 5000,
          tags: { Role: "secondary" }
        })
        
        # Reference another resource's AZ
        az_ref = ref(:aws_subnet, :private_subnet, :availability_zone)
        aws_ebs_volume(:dynamic_az, {
          availability_zone: az_ref,
          size: 50,
          type: "gp3"
        })
      end
      
      result = synthesizer.synthesis
      volumes = result[:resource][:aws_ebs_volume]
      
      expect(volumes).to have_key(:primary)
      expect(volumes).to have_key(:secondary)
      expect(volumes).to have_key(:dynamic_az)
      
      expect(volumes[:primary][:tags][:Role]).to eq("primary")
      expect(volumes[:secondary][:tags][:Role]).to eq("secondary")
      expect(volumes[:dynamic_az][:availability_zone]).to eq("${aws_subnet.private_subnet.availability_zone}")
    end
    
    it 'handles empty tags gracefully' do
      synthesizer.instance_eval do
        aws_ebs_volume(:no_tags, {
          availability_zone: "us-east-1a",
          size: 50,
          tags: {}
        })
      end
      
      result = synthesizer.synthesis
      volume = result[:resource][:aws_ebs_volume][:no_tags]
      
      expect(volume).not_to have_key(:tags)
    end
    
    it 'generates correct JSON for terraform' do
      synthesizer.instance_eval do
        aws_ebs_volume(:json_test, {
          availability_zone: "eu-west-1a",
          size: 250,
          type: "gp3",
          iops: 8000,
          throughput: 500,
          encrypted: true,
          tags: {
            Name: "json-test-volume",
            Project: "terraform-test",
            CostCenter: "engineering"
          }
        })
      end
      
      json_output = JSON.pretty_generate(synthesizer.synthesis)
      parsed = JSON.parse(json_output, symbolize_names: true)
      
      volume = parsed[:resource][:aws_ebs_volume][:json_test]
      expect(volume[:availability_zone]).to eq("eu-west-1a")
      expect(volume[:size]).to eq(250)
      expect(volume[:type]).to eq("gp3")
      expect(volume[:iops]).to eq(8000)
      expect(volume[:throughput]).to eq(500)
      expect(volume[:tags]).to be_a(Hash)
      expect(volume[:tags][:Project]).to eq("terraform-test")
    end
    
    it 'synthesizes complete storage architecture' do
      synthesizer.instance_eval do
        # Database volumes
        aws_ebs_volume(:db_primary, {
          availability_zone: "us-east-1a",
          size: 1000,
          type: "io2",
          iops: 30000,
          encrypted: true,
          tags: { Tier: "database", Role: "primary" }
        })
        
        # Application volumes
        aws_ebs_volume(:app_data, {
          availability_zone: "us-east-1a",
          size: 200,
          type: "gp3",
          iops: 6000,
          throughput: 250,
          tags: { Tier: "application" }
        })
        
        # Backup volumes
        aws_ebs_volume(:backup, {
          availability_zone: "us-east-1a",
          size: 2000,
          type: "st1",
          tags: { Tier: "backup" }
        })
        
        # Archive volumes
        aws_ebs_volume(:archive, {
          availability_zone: "us-east-1a",
          size: 5000,
          type: "sc1",
          tags: { Tier: "archive" }
        })
      end
      
      result = synthesizer.synthesis
      volumes = result[:resource][:aws_ebs_volume]
      
      expect(volumes[:db_primary][:type]).to eq("io2")
      expect(volumes[:app_data][:type]).to eq("gp3")
      expect(volumes[:backup][:type]).to eq("st1")
      expect(volumes[:archive][:type]).to eq("sc1")
      
      # Verify tier tags
      expect(volumes[:db_primary][:tags][:Tier]).to eq("database")
      expect(volumes[:app_data][:tags][:Tier]).to eq("application")
      expect(volumes[:backup][:tags][:Tier]).to eq("backup")
      expect(volumes[:archive][:tags][:Tier]).to eq("archive")
    end
    
    it 'synthesizes outpost volume' do
      synthesizer.instance_eval do
        aws_ebs_volume(:outpost_volume, {
          availability_zone: "us-east-1a",
          size: 100,
          type: "gp2",
          outpost_arn: "arn:aws:outposts:us-east-1:123456789012:outpost/op-0123456789abcdef0",
          tags: {
            Name: "outpost-local-storage",
            Location: "on-premises"
          }
        })
      end
      
      result = synthesizer.synthesis
      volume = result[:resource][:aws_ebs_volume][:outpost_volume]
      
      expect(volume[:outpost_arn]).to include("arn:aws:outposts")
      expect(volume[:tags][:Location]).to eq("on-premises")
    end
  end
end