# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Pangea::Resources::ResourceReference do
  let(:vpc_attributes) do
    {
      cidr_block: '10.0.0.0/16',
      enable_dns_hostnames: true,
      enable_dns_support: true,
      tags: { Name: 'test-vpc' }
    }
  end

  let(:vpc_outputs) do
    {
      id: '${aws_vpc.test_vpc.id}',
      arn: '${aws_vpc.test_vpc.arn}',
      cidr_block: '${aws_vpc.test_vpc.cidr_block}',
      default_security_group_id: '${aws_vpc.test_vpc.default_security_group_id}'
    }
  end

  subject do
    described_class.new(
      type: 'aws_vpc',
      name: :test_vpc,
      resource_attributes: vpc_attributes,
      outputs: vpc_outputs
    )
  end

  describe 'initialization' do
    it 'creates a ResourceReference with all required attributes' do
      expect(subject.type).to eq('aws_vpc')
      expect(subject.name).to eq(:test_vpc)
      expect(subject.resource_attributes).to eq(vpc_attributes)
      expect(subject.outputs).to eq(vpc_outputs)
    end

    it 'validates required fields are present' do
      expect {
        described_class.new(name: :test, resource_attributes: {}, outputs: {})
      }.to raise_error(Dry::Struct::Error, /type/)

      expect {
        described_class.new(type: 'aws_vpc', resource_attributes: {}, outputs: {})  
      }.to raise_error(Dry::Struct::Error, /name/)
    end

    it 'validates field types' do
      expect {
        described_class.new(
          type: :aws_vpc,  # Should be string
          name: :test,
          resource_attributes: {},
          outputs: {}
        )
      }.to raise_error(Dry::Struct::Error)

      expect {
        described_class.new(
          type: 'aws_vpc',
          name: 'test',  # Should be symbol
          resource_attributes: {},
          outputs: {}
        )
      }.to raise_error(Dry::Struct::Error)
    end

    it 'provides default empty hashes for attributes and outputs' do
      ref = described_class.new(type: 'aws_vpc', name: :test)
      expect(ref.resource_attributes).to eq({})
      expect(ref.outputs).to eq({})
    end
  end

  describe '#ref' do
    it 'generates terraform reference strings' do
      expect(subject.ref(:id)).to eq('${aws_vpc.test_vpc.id}')
      expect(subject.ref(:arn)).to eq('${aws_vpc.test_vpc.arn}')
      expect(subject.ref(:cidr_block)).to eq('${aws_vpc.test_vpc.cidr_block}')
    end

    it 'works with string attribute names' do
      expect(subject.ref('id')).to eq('${aws_vpc.test_vpc.id}')
    end

    it 'generates references for any attribute name' do
      expect(subject.ref(:custom_attribute)).to eq('${aws_vpc.test_vpc.custom_attribute}')
    end
  end

  describe '#id' do
    it 'provides convenient access to id output' do
      expect(subject.id).to eq('${aws_vpc.test_vpc.id}')
    end

    it 'falls back to generated reference if id not in outputs' do
      ref_without_id = described_class.new(
        type: 'aws_vpc',
        name: :test,
        resource_attributes: {},
        outputs: { arn: '${aws_vpc.test.arn}' }
      )
      
      expect(ref_without_id.id).to eq('${aws_vpc.test.id}')
    end
  end

  describe '#arn' do
    it 'provides convenient access to arn output' do
      expect(subject.arn).to eq('${aws_vpc.test_vpc.arn}')
    end

    it 'falls back to generated reference if arn not in outputs' do
      ref_without_arn = described_class.new(
        type: 'aws_vpc',
        name: :test,
        resource_attributes: {},
        outputs: { id: '${aws_vpc.test.id}' }
      )
      
      expect(ref_without_arn.arn).to eq('${aws_vpc.test.arn}')
    end
  end

  describe '#computed_attributes' do
    context 'for AWS VPC resource' do
      it 'returns VpcComputedAttributes instance' do
        expect(subject.computed_attributes).to be_a(Pangea::Resources::AWS::VpcComputedAttributes)
      end

      it 'provides computed properties' do
        computed = subject.computed_attributes
        expect(computed.is_default_vpc?).to be false
        expect(computed.dns_enabled?).to be true
        expect(computed.supports_ipv6?).to be false
      end
    end

    context 'for AWS Subnet resource' do
      let(:subnet_ref) do
        described_class.new(
          type: 'aws_subnet',
          name: :test_subnet,
          resource_attributes: {
            cidr_block: '10.0.1.0/24',
            map_public_ip_on_launch: true,
            vpc_id: '${aws_vpc.main.id}'
          },
          outputs: { id: '${aws_subnet.test_subnet.id}' }
        )
      end

      it 'returns SubnetComputedAttributes instance' do
        expect(subnet_ref.computed_attributes).to be_a(Pangea::Resources::AWS::SubnetComputedAttributes)
      end

      it 'determines subnet type correctly' do
        computed = subnet_ref.computed_attributes
        expect(computed.is_public?).to be true
        expect(computed.is_private?).to be false
      end
    end

    context 'for unsupported resource type' do
      let(:unsupported_ref) do
        described_class.new(
          type: 'unsupported_resource',
          name: :test,
          resource_attributes: {},
          outputs: {}
        )
      end

      it 'returns nil for unsupported types' do
        expect(unsupported_ref.computed_attributes).to be_nil
      end
    end
  end

  describe 'equality and comparison' do
    it 'considers two references equal if all attributes match' do
      other_ref = described_class.new(
        type: 'aws_vpc',
        name: :test_vpc,
        resource_attributes: vpc_attributes,
        outputs: vpc_outputs
      )
      
      expect(subject).to eq(other_ref)
    end

    it 'considers references different if type differs' do
      other_ref = described_class.new(
        type: 'aws_subnet',
        name: :test_vpc,
        resource_attributes: vpc_attributes,
        outputs: vpc_outputs
      )
      
      expect(subject).not_to eq(other_ref)
    end

    it 'considers references different if name differs' do
      other_ref = described_class.new(
        type: 'aws_vpc',
        name: :other_vpc,
        resource_attributes: vpc_attributes,
        outputs: vpc_outputs
      )
      
      expect(subject).not_to eq(other_ref)
    end

    it 'considers references different if attributes differ' do
      other_attributes = vpc_attributes.merge(enable_dns_hostnames: false)
      other_ref = described_class.new(
        type: 'aws_vpc',
        name: :test_vpc,
        resource_attributes: other_attributes,
        outputs: vpc_outputs
      )
      
      expect(subject).not_to eq(other_ref)
    end
  end

  describe 'serialization' do
    it 'converts to hash correctly' do
      hash = subject.to_h
      
      expect(hash).to include(
        type: 'aws_vpc',
        name: :test_vpc,
        resource_attributes: vpc_attributes,
        outputs: vpc_outputs
      )
    end

    it 'supports JSON serialization' do
      json = JSON.generate(subject.to_h)
      parsed = JSON.parse(json, symbolize_names: true)
      
      expect(parsed[:type]).to eq('aws_vpc')
      expect(parsed[:name]).to eq('test_vpc')  # Symbol becomes string in JSON
    end
  end

  describe 'immutability' do
    it 'is immutable by default (Dry::Struct behavior)' do
      expect { subject.type = 'new_type' }.to raise_error(NoMethodError)
      expect { subject.name = :new_name }.to raise_error(NoMethodError)
    end

    it 'does not allow direct modification of attributes hash' do
      original_attributes = subject.resource_attributes.dup
      
      # Attempting to modify the attributes hash should not affect the struct
      subject.resource_attributes[:new_key] = 'new_value'
      
      # The original reference should still have the original attributes
      expect(subject.resource_attributes).to eq(original_attributes)
    end
  end

  describe 'resource reference chaining' do
    let(:vpc_ref) do
      described_class.new(
        type: 'aws_vpc',
        name: :main_vpc,
        resource_attributes: vpc_attributes,
        outputs: vpc_outputs
      )
    end

    let(:subnet_ref) do
      described_class.new(
        type: 'aws_subnet',
        name: :main_subnet,
        resource_attributes: {
          vpc_id: vpc_ref.ref(:id),
          cidr_block: '10.0.1.0/24',
          availability_zone: 'us-east-1a'
        },
        outputs: {
          id: '${aws_subnet.main_subnet.id}',
          vpc_id: '${aws_subnet.main_subnet.vpc_id}'
        }
      )
    end

    it 'chains resource references correctly' do
      expect(subnet_ref.resource_attributes[:vpc_id]).to eq('${aws_vpc.main_vpc.id}')
    end

    it 'maintains reference relationships' do
      # The subnet references the VPC
      expect(subnet_ref.resource_attributes[:vpc_id]).to include('aws_vpc.main_vpc.id')
      
      # But they remain separate resource references
      expect(subnet_ref.type).to eq('aws_subnet')
      expect(vpc_ref.type).to eq('aws_vpc')
    end
  end

  describe 'validation edge cases' do
    it 'handles empty strings in type and name' do
      expect {
        described_class.new(type: '', name: :test, resource_attributes: {}, outputs: {})
      }.to raise_error(Dry::Struct::Error)

      expect {
        described_class.new(type: 'aws_vpc', name: :'', resource_attributes: {}, outputs: {})
      }.not_to raise_error
    end

    it 'handles nested hashes in attributes' do
      nested_attributes = {
        vpc_config: {
          cidr_block: '10.0.0.0/16',
          enable_dns: true
        },
        tags: {
          Environment: 'test',
          Project: { name: 'test-project', owner: 'team' }
        }
      }

      ref = described_class.new(
        type: 'aws_resource',
        name: :nested_test,
        resource_attributes: nested_attributes,
        outputs: {}
      )

      expect(ref.resource_attributes[:vpc_config][:cidr_block]).to eq('10.0.0.0/16')
      expect(ref.resource_attributes[:tags][:Project][:name]).to eq('test-project')
    end

    it 'handles nil values in attributes' do
      attributes_with_nil = {
        required_field: 'value',
        optional_field: nil,
        tags: { Name: 'test', Description: nil }
      }

      ref = described_class.new(
        type: 'aws_resource',
        name: :nil_test,
        resource_attributes: attributes_with_nil,
        outputs: {}
      )

      expect(ref.resource_attributes[:optional_field]).to be_nil
      expect(ref.resource_attributes[:tags][:Description]).to be_nil
    end
  end
end