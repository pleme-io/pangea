# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "ResourceReference - Pure Functions" do
  let(:vpc_reference) do
    Pangea::Resources::ResourceReference.new(
      type: 'aws_vpc',
      name: :main,
      resource_attributes: { cidr_block: '10.0.0.0/16' },
      outputs: { id: '${aws_vpc.main.id}', arn: '${aws_vpc.main.arn}' }
    )
  end

  describe "#ref method - pure terraform reference generation" do
    it "generates correct terraform reference strings" do
      expect(vpc_reference.ref(:id)).to eq('${aws_vpc.main.id}')
      expect(vpc_reference.ref(:cidr_block)).to eq('${aws_vpc.main.cidr_block}')
      expect(vpc_reference.ref(:tags)).to eq('${aws_vpc.main.tags}')
    end
    
    it "accepts string attribute names" do
      expect(vpc_reference.ref('id')).to eq('${aws_vpc.main.id}')
      expect(vpc_reference.ref('cidr_block')).to eq('${aws_vpc.main.cidr_block}')
    end
    
    it "generates references for any attribute name" do
      expect(vpc_reference.ref(:non_existent)).to eq('${aws_vpc.main.non_existent}')
    end
  end

  describe "#[] method - alias for ref" do
    it "works as an alias for ref method" do
      expect(vpc_reference[:id]).to eq(vpc_reference.ref(:id))
      expect(vpc_reference[:cidr_block]).to eq(vpc_reference.ref(:cidr_block))
    end
  end

  describe "#id and #arn convenience methods" do
    it "returns id reference from outputs if available" do
      expect(vpc_reference.id).to eq('${aws_vpc.main.id}')
    end
    
    it "returns arn reference from outputs if available" do
      expect(vpc_reference.arn).to eq('${aws_vpc.main.arn}')
    end
    
    it "generates id reference if not in outputs" do
      ref_without_id = Pangea::Resources::ResourceReference.new(
        type: 'aws_vpc',
        name: :test,
        resource_attributes: {},
        outputs: {}
      )
      expect(ref_without_id.id).to eq('${aws_vpc.test.id}')
    end
  end

  describe "#to_h method - serialization" do
    it "converts to hash with all properties" do
      hash = vpc_reference.to_h
      
      expect(hash).to be_a(Hash)
      expect(hash[:type]).to eq('aws_vpc')
      expect(hash[:name]).to eq(:main)
      expect(hash[:resource_attributes]).to eq({ cidr_block: '10.0.0.0/16' })
      expect(hash[:outputs]).to eq({ id: '${aws_vpc.main.id}', arn: '${aws_vpc.main.arn}' })
    end
  end

  describe "immutability" do
    it "returns frozen attributes hash" do
      expect(vpc_reference.resource_attributes).to be_frozen
    end
    
    it "returns frozen outputs hash" do
      expect(vpc_reference.outputs).to be_frozen
    end
  end

  describe "equality comparison" do
    it "considers two references equal if all properties match" do
      ref1 = Pangea::Resources::ResourceReference.new(
        type: 'aws_vpc',
        name: :main,
        resource_attributes: { cidr_block: '10.0.0.0/16' },
        outputs: { id: '${aws_vpc.main.id}' }
      )
      
      ref2 = Pangea::Resources::ResourceReference.new(
        type: 'aws_vpc',
        name: :main,
        resource_attributes: { cidr_block: '10.0.0.0/16' },
        outputs: { id: '${aws_vpc.main.id}' }
      )
      
      expect(ref1).to eq(ref2)
    end
    
    it "considers references different if any property differs" do
      ref1 = Pangea::Resources::ResourceReference.new(
        type: 'aws_vpc',
        name: :main,
        resource_attributes: { cidr_block: '10.0.0.0/16' },
        outputs: {}
      )
      
      ref2 = Pangea::Resources::ResourceReference.new(
        type: 'aws_vpc',
        name: :main,
        resource_attributes: { cidr_block: '10.0.0.0/24' },  # Different CIDR
        outputs: {}
      )
      
      expect(ref1).not_to eq(ref2)
    end
  end
end