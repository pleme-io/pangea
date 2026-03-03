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
require 'pangea/backends/local'
require 'tmpdir'
require 'fileutils'

RSpec.describe Pangea::Backends::Local do
  let(:tmp_dir) { Dir.mktmpdir('pangea_local_backend_test') }
  let(:state_path) { File.join(tmp_dir, 'terraform.tfstate') }
  let(:config) { { path: state_path } }
  let(:backend) { described_class.new(config) }

  after(:each) do
    FileUtils.rm_rf(tmp_dir) if File.exist?(tmp_dir)
  end

  describe '#initialize' do
    it 'stores the configuration with path' do
      expect(backend.config[:path]).to eq(state_path)
    end

    it 'defaults path to terraform.tfstate when not provided' do
      default_backend = described_class.new({})
      expect(default_backend.config[:path]).to eq('terraform.tfstate')
    end
  end

  describe '#type' do
    it 'returns local' do
      expect(backend.type).to eq('local')
    end
  end

  describe '#configured?' do
    it 'always returns true' do
      expect(backend.configured?).to be true
    end
  end

  describe '#initialize!' do
    it 'creates the directory if it does not exist' do
      nested_path = File.join(tmp_dir, 'nested', 'dir', 'terraform.tfstate')
      nested_backend = described_class.new(path: nested_path)

      expect(nested_backend.initialize!).to be true
      expect(Dir.exist?(File.dirname(nested_path))).to be true
    end

    it 'returns true when directory already exists' do
      expect(backend.initialize!).to be true
    end
  end

  describe '#to_terraform_config' do
    it 'returns local backend configuration' do
      expect(backend.to_terraform_config).to eq({
        local: { path: state_path }
      })
    end
  end

  describe '#validate_config!' do
    it 'raises error for paths containing ..' do
      expect {
        described_class.new(path: '../../../etc/passwd')
      }.to raise_error(ArgumentError, /Path cannot contain '\.\.'/)
    end

    it 'accepts valid paths' do
      expect {
        described_class.new(path: 'some/valid/path.tfstate')
      }.not_to raise_error
    end
  end

  describe 'locking' do
    let(:lock_id) { 'test-lock-123' }
    let(:lock_info) { { operation: 'apply', who: 'test-user' } }

    describe '#lock' do
      it 'creates a lock file' do
        expect(backend.lock(lock_id: lock_id, info: lock_info)).to be true
        expect(File.exist?("#{state_path}.lock")).to be true
      end

      it 'returns false if already locked' do
        backend.lock(lock_id: lock_id)
        expect(backend.lock(lock_id: 'another-lock')).to be false
      end

      it 'stores lock information in the lock file' do
        backend.lock(lock_id: lock_id, info: lock_info)

        lock_data = JSON.parse(File.read("#{state_path}.lock"))
        expect(lock_data['id']).to eq(lock_id)
        expect(lock_data['info']).to eq(lock_info.transform_keys(&:to_s))
        expect(lock_data['pid']).to eq(Process.pid)
      end
    end

    describe '#locked?' do
      it 'returns false when not locked' do
        expect(backend.locked?).to be false
      end

      it 'returns true when locked' do
        backend.lock(lock_id: lock_id)
        expect(backend.locked?).to be true
      end

      it 'returns false for corrupted lock file' do
        File.write("#{state_path}.lock", 'not-valid-json')
        expect(backend.locked?).to be false
      end
    end

    describe '#lock_info' do
      it 'returns nil when not locked' do
        expect(backend.lock_info).to be_nil
      end

      it 'returns lock information when locked' do
        backend.lock(lock_id: lock_id, info: lock_info)

        info = backend.lock_info
        expect(info[:id]).to eq(lock_id)
        expect(info[:info]).to eq(lock_info.transform_keys(&:to_s))
        expect(info[:pid]).to eq(Process.pid)
        expect(info[:created]).to be_a(Time)
      end

      it 'returns nil for corrupted lock file' do
        File.write("#{state_path}.lock", 'not-valid-json')
        expect(backend.lock_info).to be_nil
      end
    end

    describe '#unlock' do
      it 'removes the lock file when lock_id matches' do
        backend.lock(lock_id: lock_id)
        expect(backend.unlock(lock_id: lock_id)).to be true
        expect(File.exist?("#{state_path}.lock")).to be false
      end

      it 'returns false when lock_id does not match' do
        backend.lock(lock_id: lock_id)
        expect(backend.unlock(lock_id: 'wrong-id')).to be false
        expect(File.exist?("#{state_path}.lock")).to be true
      end

      it 'returns false when not locked' do
        expect(backend.unlock(lock_id: lock_id)).to be false
      end

      it 'returns false for corrupted lock file' do
        File.write("#{state_path}.lock", 'not-valid-json')
        expect(backend.unlock(lock_id: lock_id)).to be false
      end
    end
  end
end
