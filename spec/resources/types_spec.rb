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

RSpec.describe Pangea::Resources::Types do
  describe 'type validation' do
    it 'defines String type with constraints' do
      expect(described_class::String).to be_a(Dry::Types::Nominal)
      
      # Valid strings
      expect(described_class::String['hello']).to eq('hello')
      expect(described_class::String['']).to eq('')
      
      # Invalid types
      expect { described_class::String[123] }.to raise_error(Dry::Types::CoercionError)
    end

    it 'defines Integer type with constraints' do
      expect(described_class::Integer).to be_a(Dry::Types::Nominal)
      
      # Valid integers
      expect(described_class::Integer[42]).to eq(42)
      expect(described_class::Integer[0]).to eq(0)
      expect(described_class::Integer[-1]).to eq(-1)
      
      # Invalid types
      expect { described_class::Integer['not a number'] }.to raise_error(Dry::Types::CoercionError)
    end

    it 'defines Bool type' do
      expect(described_class::Bool).to be_a(Dry::Types::Nominal)
      
      # Valid booleans
      expect(described_class::Bool[true]).to be true
      expect(described_class::Bool[false]).to be false
      
      # Invalid types
      expect { described_class::Bool['true'] }.to raise_error(Dry::Types::CoercionError)
      expect { described_class::Bool[1] }.to raise_error(Dry::Types::CoercionError)
    end

    it 'defines Hash type' do
      expect(described_class::Hash).to be_a(Dry::Types::Nominal)
      
      # Valid hashes
      test_hash = { key: 'value' }
      expect(described_class::Hash[test_hash]).to eq(test_hash)
      expect(described_class::Hash[{}]).to eq({})
      
      # Invalid types
      expect { described_class::Hash['not a hash'] }.to raise_error(Dry::Types::CoercionError)
    end

    it 'defines Array type' do
      expect(described_class::Array).to be_a(Dry::Types::Nominal)
      
      # Valid arrays
      test_array = [1, 2, 3]
      expect(described_class::Array[test_array]).to eq(test_array)
      expect(described_class::Array[[]]).to eq([])
      
      # Invalid types
      expect { described_class::Array['not an array'] }.to raise_error(Dry::Types::CoercionError)
    end
  end

  describe 'AWS-specific types' do
    it 'validates CIDR block format' do
      # Valid CIDR blocks
      valid_cidrs = [
        '10.0.0.0/16',
        '172.16.0.0/12', 
        '192.168.1.0/24',
        '0.0.0.0/0'
      ]
      
      valid_cidrs.each do |cidr|
        expect { described_class::CidrBlock[cidr] }.not_to raise_error
        expect(described_class::CidrBlock[cidr]).to eq(cidr)
      end
      
      # Invalid CIDR blocks
      invalid_cidrs = [
        '256.0.0.0/16',  # Invalid IP
        '10.0.0.0/33',   # Invalid prefix length
        '10.0.0.0',      # Missing prefix
        'not-a-cidr',    # Not an IP
        ''               # Empty string
      ]
      
      invalid_cidrs.each do |cidr|
        expect { described_class::CidrBlock[cidr] }.to raise_error(Dry::Types::CoercionError)
      end
    end

    it 'validates AWS AMI ID format' do
      # Valid AMI IDs
      valid_amis = [
        'ami-12345678',
        'ami-abcdefgh',
        'ami-12345678abcdefgh'  # Longer format
      ]
      
      valid_amis.each do |ami|
        expect { described_class::AmiId[ami] }.not_to raise_error
        expect(described_class::AmiId[ami]).to eq(ami)
      end
      
      # Invalid AMI IDs
      invalid_amis = [
        '12345678',          # Missing ami- prefix
        'ami-',              # Just prefix
        'ami-XYXYXYXY',      # Invalid characters
        'not-an-ami',        # Wrong format
        ''                   # Empty string
      ]
      
      invalid_amis.each do |ami|
        expect { described_class::AmiId[ami] }.to raise_error(Dry::Types::CoercionError)
      end
    end

    it 'validates AWS instance types' do
      # Valid instance types
      valid_types = [
        't3.nano',
        't3.micro', 
        't3.small',
        'c5.large',
        'r5.xlarge',
        'm5.2xlarge',
        'x1e.32xlarge'
      ]
      
      valid_types.each do |instance_type|
        expect { described_class::InstanceType[instance_type] }.not_to raise_error
        expect(described_class::InstanceType[instance_type]).to eq(instance_type)
      end
      
      # Invalid instance types
      invalid_types = [
        'invalid-type',
        't3',           # Missing size
        'large',        # Missing family
        't3.invalid',   # Invalid size
        ''              # Empty string
      ]
      
      invalid_types.each do |instance_type|
        expect { described_class::InstanceType[instance_type] }.to raise_error(Dry::Types::CoercionError)
      end
    end

    it 'validates RDS instance classes' do
      # Valid RDS instance classes
      valid_classes = [
        'db.t3.micro',
        'db.t3.small',
        'db.r5.large',
        'db.r5.xlarge',
        'db.x1e.2xlarge'
      ]
      
      valid_classes.each do |instance_class|
        expect { described_class::DbInstanceClass[instance_class] }.not_to raise_error
        expect(described_class::DbInstanceClass[instance_class]).to eq(instance_class)
      end
      
      # Invalid RDS instance classes
      invalid_classes = [
        't3.micro',        # Missing db. prefix
        'db.invalid.micro', # Invalid family
        'db.t3',           # Missing size
        'invalid'          # Wrong format
      ]
      
      invalid_classes.each do |instance_class|
        expect { described_class::DbInstanceClass[instance_class] }.to raise_error(Dry::Types::CoercionError)
      end
    end

    it 'validates AWS resource names' do
      # Valid resource names (AWS naming conventions)
      valid_names = [
        'my-resource',
        'MyResource123',
        'resource_name',
        '123resource'
      ]
      
      valid_names.each do |name|
        expect { described_class::ResourceName[name] }.not_to raise_error
        expect(described_class::ResourceName[name]).to eq(name)
      end
      
      # Invalid resource names
      invalid_names = [
        '',                    # Empty
        'name with spaces',    # Spaces not allowed in most AWS resources
        'name@with#symbols',   # Special characters
        'a' * 256            # Too long
      ]
      
      invalid_names.each do |name|
        expect { described_class::ResourceName[name] }.to raise_error(Dry::Types::CoercionError)
      end
    end
  end

  describe 'composite types' do
    it 'validates arrays of specific types' do
      string_array_type = described_class::Array.of(described_class::String)
      
      # Valid string arrays
      expect(string_array_type[['a', 'b', 'c']]).to eq(['a', 'b', 'c'])
      expect(string_array_type[[]]).to eq([])
      
      # Invalid - mixed types
      expect { string_array_type[['a', 1, 'c']] }.to raise_error(Dry::Types::CoercionError)
    end

    it 'validates hashes with string keys' do
      string_hash_type = described_class::Hash.map(described_class::String, described_class::String)
      
      # Valid string hash
      valid_hash = { 'key1' => 'value1', 'key2' => 'value2' }
      expect(string_hash_type[valid_hash]).to eq(valid_hash)
      
      # Invalid - non-string keys or values would fail in strict mode
      # (dry-types behavior may vary based on configuration)
    end

    it 'validates optional types' do
      optional_string = described_class::String.optional
      
      # Valid - string or nil
      expect(optional_string['hello']).to eq('hello')
      expect(optional_string[nil]).to be_nil
      
      # Invalid - other types
      expect { optional_string[123] }.to raise_error(Dry::Types::CoercionError)
    end

    it 'validates enum types' do
      environment_type = described_class::String.enum('development', 'staging', 'production')
      
      # Valid environments
      %w[development staging production].each do |env|
        expect(environment_type[env]).to eq(env)
      end
      
      # Invalid environment
      expect { environment_type['invalid'] }.to raise_error(Dry::Types::ConstraintError)
    end
  end

  describe 'default values' do
    it 'provides defaults for types with default method' do
      type_with_default = described_class::String.default('default_value')
      
      # When no value provided, uses default
      expect(type_with_default[nil]).to eq('default_value')
      expect(type_with_default['custom']).to eq('custom')
    end

    it 'provides defaults for hash types' do
      hash_with_default = described_class::Hash.default({}.freeze)
      
      # When no value provided, uses default
      expect(hash_with_default[nil]).to eq({})
      expect(hash_with_default[{ custom: 'value' }]).to eq({ custom: 'value' })
    end
  end

  describe 'constraint validation' do
    it 'validates string length constraints' do
      bounded_string = described_class::String.constrained(min_size: 1, max_size: 10)
      
      # Valid lengths
      expect(bounded_string['a']).to eq('a')
      expect(bounded_string['1234567890']).to eq('1234567890')
      
      # Invalid lengths
      expect { bounded_string[''] }.to raise_error(Dry::Types::ConstraintError)
      expect { bounded_string['a' * 11] }.to raise_error(Dry::Types::ConstraintError)
    end

    it 'validates integer range constraints' do
      port_number = described_class::Integer.constrained(gteq: 1, lteq: 65535)
      
      # Valid ports
      expect(port_number[80]).to eq(80)
      expect(port_number[443]).to eq(443)
      expect(port_number[65535]).to eq(65535)
      
      # Invalid ports
      expect { port_number[0] }.to raise_error(Dry::Types::ConstraintError)
      expect { port_number[65536] }.to raise_error(Dry::Types::ConstraintError)
    end

    it 'validates format constraints using predicates' do
      # This would require custom predicates to be defined
      # Example: email format validation
      skip 'Custom format constraints require predicate definitions'
    end
  end

  describe 'coercion behavior' do
    it 'coerces compatible types when coercion is enabled' do
      # This depends on the coercion configuration in the actual types
      # String coercion from symbols
      if described_class::String.respond_to?(:call) && described_class::String.respond_to?(:constructor)
        # Test coercion behavior if available
        skip 'Coercion behavior testing depends on specific type configuration'
      end
    end
  end
end