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
require 'pangea/backends/base'

RSpec.describe Pangea::Backends::Base do
  let(:config) { { key: 'value' } }
  let(:backend) { described_class.new(config) }

  describe '#initialize' do
    it 'stores the configuration' do
      expect(backend.config).to eq(config)
    end

    it 'accepts empty configuration' do
      empty_backend = described_class.new
      expect(empty_backend.config).to eq({})
    end
  end

  describe '#type' do
    it 'returns the class name as lowercase' do
      expect(backend.type).to eq('base')
    end
  end

  describe 'abstract methods' do
    it 'raises NotImplementedError for #initialize!' do
      expect { backend.initialize! }.to raise_error(NotImplementedError)
    end

    it 'raises NotImplementedError for #configured?' do
      expect { backend.configured? }.to raise_error(NotImplementedError)
    end

    it 'raises NotImplementedError for #lock' do
      expect { backend.lock(lock_id: 'test') }.to raise_error(NotImplementedError)
    end

    it 'raises NotImplementedError for #unlock' do
      expect { backend.unlock(lock_id: 'test') }.to raise_error(NotImplementedError)
    end

    it 'raises NotImplementedError for #locked?' do
      expect { backend.locked? }.to raise_error(NotImplementedError)
    end

    it 'raises NotImplementedError for #lock_info' do
      expect { backend.lock_info }.to raise_error(NotImplementedError)
    end

    it 'raises NotImplementedError for #to_terraform_config' do
      expect { backend.to_terraform_config }.to raise_error(NotImplementedError)
    end
  end
end
