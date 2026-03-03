# frozen_string_literal: true

require 'tmpdir'
require 'fileutils'
require 'yaml'
require 'pangea/cli/commands/sync'
require 'pangea/configuration'
require 'pangea/execution/workspace_manager'
require 'pangea/execution/terraform_executor'

RSpec.describe Pangea::CLI::Commands::Sync do
  subject(:command) { described_class.new }

  let(:workspace_dir) { Dir.mktmpdir('pangea-ws') }
  let(:namespace_entity) do
    Pangea::Entities::Namespace.new(
      name: 'dev', description: 'Dev',
      state: { type: :local, config: {} }, tags: {}
    )
  end

  let(:executor) do
    ex = instance_double(Pangea::Execution::TerraformExecutor)
    allow(ex).to receive(:init).and_return(success: true, message: 'OK', output: '')
    allow(ex).to receive(:refresh).and_return(
      success: true, message: 'Refreshed', output: 'Refresh complete.'
    )
    allow(ex).to receive(:state_list).and_return(
      success: true,
      resources: ['aws_vpc.main', 'aws_subnet.public', 'aws_subnet.private'],
      output: ''
    )
    ex
  end

  let(:workspace_manager) do
    mgr = instance_double(Pangea::Execution::WorkspaceManager)
    allow(mgr).to receive(:workspace_for).and_return(workspace_dir)
    allow(mgr).to receive(:write_terraform_json).and_return(File.join(workspace_dir, 'main.tf.json'))
    allow(mgr).to receive(:save_metadata)
    allow(mgr).to receive(:initialized?).and_return(true)
    allow(mgr).to receive(:workspace_metadata).and_return({})
    mgr
  end

  before do
    allow(Pangea::Execution::TerraformExecutor).to receive(:new).and_return(executor)
    allow(Pangea::Execution::WorkspaceManager).to receive(:new).and_return(workspace_manager)
  end

  after { FileUtils.rm_rf(workspace_dir) }

  describe '#sync_template' do
    before do
      command.instance_variable_set(:@workspace_manager, workspace_manager)
      command.instance_variable_set(:@namespace, 'dev')
      command.instance_variable_set(:@file_path, 'network.rb')
    end

    it 'runs refresh and displays state summary' do
      expect(executor).to receive(:refresh)
      expect(executor).to receive(:state_list)
      command.sync_template(:network, '{}', namespace_entity)
    end

    it 'handles refresh failure' do
      allow(executor).to receive(:refresh).and_return(
        success: false, error: 'Provider error', output: ''
      )
      expect { command.sync_template(:network, '{}', namespace_entity) }.not_to raise_error
    end
  end
end
