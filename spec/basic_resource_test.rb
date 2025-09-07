# frozen_string_literal: true

require_relative 'simple_spec_helper'

RSpec.describe 'Basic Resource Functions' do
  context 'when loading Pangea modules' do
    it 'loads Pangea::Resources module' do
      expect(Pangea::Resources).to be_a(Module)
    end

    it 'has Types module available' do
      expect(Pangea::Types).to be_a(Module)
    end

    it 'can access dry-types' do
      expect(Dry::Types).to be_a(Module)
    end
  end

  context 'when using types' do
    it 'validates string types' do
      string_type = Pangea::Types::String
      expect(string_type['hello']).to eq('hello')
    end

    it 'validates integer types' do
      integer_type = Pangea::Types::Integer
      expect(integer_type[42]).to eq(42)
    end

    it 'validates boolean types' do
      bool_type = Pangea::Types::Bool
      expect(bool_type[true]).to be true
      expect(bool_type[false]).to be false
    end
  end

  context 'when using AWS region enum' do
    it 'validates valid AWS regions' do
      region_type = Pangea::Types::AwsRegion
      expect(region_type['us-east-1']).to eq('us-east-1')
      expect(region_type['eu-west-1']).to eq('eu-west-1')
    end

    it 'rejects invalid regions' do
      region_type = Pangea::Types::AwsRegion
      expect { region_type['invalid-region'] }.to raise_error(Dry::Types::ConstraintError)
    end
  end

  context 'when testing entities' do
    it 'has Namespace entity' do
      expect(Pangea::Entities::Namespace).to be_a(Class)
    end

    it 'can create a namespace with valid attributes' do
      namespace = Pangea::Entities::Namespace.new(
        name: 'test-namespace',
        state: {
          type: :local,
          config: {
            region: 'us-east-1',
            path: './terraform.tfstate'
          }
        }
      )
      
      expect(namespace.name).to eq('test-namespace')
      expect(namespace.state.type).to eq(:local)
      expect(namespace.state.local?).to be true
    end
  end
end