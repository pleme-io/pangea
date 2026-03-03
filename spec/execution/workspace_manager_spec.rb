# frozen_string_literal: true

require 'json'
require 'tmpdir'
require 'fileutils'
require 'pangea/execution/workspace_manager'

RSpec.describe Pangea::Execution::WorkspaceManager do
  let(:base_dir) { Dir.mktmpdir('pangea-wm') }
  subject(:manager) { described_class.new(base_dir: base_dir) }

  after { FileUtils.rm_rf(base_dir) }

  describe '#workspace_for' do
    it 'creates workspace directory for namespace' do
      path = manager.workspace_for(namespace: 'dev')
      expect(Dir.exist?(path)).to be true
      expect(path).to include('dev')
    end

    it 'creates workspace with project name' do
      path = manager.workspace_for(namespace: 'dev', project: 'network')
      expect(path).to include('network')
    end

    it 'creates workspace with site' do
      path = manager.workspace_for(namespace: 'prod', site: 'us-east-1')
      expect(path).to include('us-east-1')
    end

    it 'returns same path for same arguments' do
      path1 = manager.workspace_for(namespace: 'dev', project: 'net')
      path2 = manager.workspace_for(namespace: 'dev', project: 'net')
      expect(path1).to eq(path2)
    end
  end

  describe '#write_terraform_json' do
    let(:workspace) { manager.workspace_for(namespace: 'dev') }

    it 'writes pretty-printed JSON to file' do
      content = { provider: { aws: { region: 'us-east-1' } } }
      path = manager.write_terraform_json(workspace: workspace, content: content)
      expect(File.exist?(path)).to be true
      written = JSON.parse(File.read(path))
      expect(written['provider']['aws']['region']).to eq('us-east-1')
    end

    it 'uses custom filename' do
      content = { resource: {} }
      path = manager.write_terraform_json(workspace: workspace, content: content, filename: 'network.tf.json')
      expect(File.basename(path)).to eq('network.tf.json')
    end
  end

  describe '#read_terraform_json' do
    let(:workspace) { manager.workspace_for(namespace: 'dev') }

    it 'reads and parses JSON from workspace' do
      content = { resource: { aws_vpc: { main: {} } } }
      manager.write_terraform_json(workspace: workspace, content: content)
      result = manager.read_terraform_json(workspace: workspace)
      expect(result).to have_key(:resource)
    end

    it 'returns nil when file does not exist' do
      result = manager.read_terraform_json(workspace: workspace)
      expect(result).to be_nil
    end
  end

  describe '#initialized?' do
    let(:workspace) { manager.workspace_for(namespace: 'dev') }

    it 'returns false for uninitialized workspace' do
      expect(manager.initialized?(workspace)).to be false
    end

    it 'returns true when .terraform directory exists' do
      FileUtils.mkdir_p(File.join(workspace, '.terraform'))
      expect(manager.initialized?(workspace)).to be true
    end

    it 'returns true when .terraform.lock.hcl exists' do
      FileUtils.touch(File.join(workspace, '.terraform.lock.hcl'))
      expect(manager.initialized?(workspace)).to be true
    end
  end

  describe '#clean' do
    let(:workspace) { manager.workspace_for(namespace: 'dev') }

    before do
      FileUtils.mkdir_p(File.join(workspace, '.terraform'))
      FileUtils.touch(File.join(workspace, '.terraform.lock.hcl'))
      FileUtils.touch(File.join(workspace, 'plan.tfplan'))
      FileUtils.touch(File.join(workspace, 'terraform.tfstate'))
      FileUtils.touch(File.join(workspace, 'main.tf.json'))
    end

    it 'removes terraform artifacts' do
      manager.clean(workspace)
      expect(Dir.exist?(File.join(workspace, '.terraform'))).to be false
      expect(File.exist?(File.join(workspace, '.terraform.lock.hcl'))).to be false
      expect(File.exist?(File.join(workspace, 'plan.tfplan'))).to be false
    end

    it 'keeps non-terraform files' do
      manager.clean(workspace)
      expect(File.exist?(File.join(workspace, 'main.tf.json'))).to be true
    end
  end

  describe '#remove' do
    it 'removes entire workspace directory' do
      workspace = manager.workspace_for(namespace: 'dev')
      manager.remove(workspace)
      expect(Dir.exist?(workspace)).to be false
    end
  end

  describe '#list_workspaces' do
    it 'returns empty array when no workspaces' do
      expect(manager.list_workspaces).to be_empty
    end

    it 'lists workspaces with terraform JSON files' do
      ws = manager.workspace_for(namespace: 'dev', project: 'network')
      manager.write_terraform_json(workspace: ws, content: {})
      result = manager.list_workspaces
      expect(result).not_to be_empty
    end
  end

  describe '#save_metadata and #workspace_metadata' do
    let(:workspace) { manager.workspace_for(namespace: 'dev') }

    it 'saves and reads metadata' do
      metadata = { namespace: 'dev', template: 'network' }
      manager.save_metadata(workspace: workspace, metadata: metadata)
      result = manager.workspace_metadata(workspace)
      expect(result[:namespace]).to eq('dev')
      expect(result[:template]).to eq('network')
    end

    it 'adds updated_at timestamp' do
      manager.save_metadata(workspace: workspace, metadata: { foo: 'bar' })
      result = manager.workspace_metadata(workspace)
      expect(result[:updated_at]).not_to be_nil
    end

    it 'returns empty hash for missing metadata' do
      expect(manager.workspace_metadata(workspace)).to eq({})
    end
  end

  describe '#temp_workspace' do
    it 'yields a temporary directory' do
      manager.temp_workspace do |dir|
        expect(Dir.exist?(dir)).to be true
        File.write(File.join(dir, 'test.txt'), 'hello')
      end
    end

    it 'returns the block result' do
      result = manager.temp_workspace { 42 }
      expect(result).to eq(42)
    end
  end
end
