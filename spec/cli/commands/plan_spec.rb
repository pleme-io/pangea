# frozen_string_literal: true

require 'tmpdir'
require 'fileutils'
require 'yaml'
require 'pangea/cli/commands/plan'
require 'pangea/configuration'
require 'pangea/execution/workspace_manager'
require 'pangea/execution/terraform_executor'

RSpec.describe Pangea::CLI::Commands::Plan do
  subject(:command) { described_class.new }

  let(:workspace_dir) { Dir.mktmpdir('pangea-ws') }
  let(:namespace_entity) do
    Pangea::Entities::Namespace.new(
      name: 'dev', description: 'Dev',
      state: { type: :local, config: {} }, tags: {}
    )
  end

  let(:plan_success) do
    {
      success: true, changes: true,
      output: "Plan: 1 to add, 0 to change, 0 to destroy.",
      resource_changes: { 'aws_vpc.main' => 'create' },
      exit_code: 2
    }
  end

  let(:plan_no_changes) do
    {
      success: true, changes: false,
      output: "No changes. Your infrastructure matches the configuration.",
      resource_changes: {},
      exit_code: 0
    }
  end

  let(:plan_failure) do
    {
      success: false, changes: false,
      output: '', error: 'Error: Invalid provider',
      exit_code: 1
    }
  end

  let(:executor) do
    ex = instance_double(Pangea::Execution::TerraformExecutor)
    allow(ex).to receive(:init).and_return(success: true, message: 'OK', output: '')
    allow(ex).to receive(:plan).and_return(plan_success)
    allow(ex).to receive(:state_list).and_return(success: true, resources: [], output: '')
    allow(ex).to receive(:output).and_return(success: true, output: '{}', data: {})
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

  describe '#plan_template' do
    before do
      command.instance_variable_set(:@workspace_manager, workspace_manager)
      command.instance_variable_set(:@namespace, 'dev')
      command.instance_variable_set(:@file_path, 'network.rb')
      command.instance_variable_set(:@diff, Pangea::CLI::UI::Diff::Renderer.new)
      command.instance_variable_set(:@visualizer, Pangea::CLI::UI::Visualizer.new)
      command.instance_variable_set(:@progress, Pangea::CLI::UI::Progress.new)
      command.instance_variable_set(:@show_compiled, false)
    end

    it 'executes terraform plan' do
      expect(executor).to receive(:plan)
      command.plan_template(:network, '{"resource":{"aws_vpc":{"main":{}}}}', namespace_entity)
    end

    it 'displays no-changes message when plan has no changes' do
      allow(executor).to receive(:plan).and_return(plan_no_changes)
      expect { command.plan_template(:network, '{}', namespace_entity) }.not_to raise_error
    end

    it 'displays error on plan failure' do
      allow(executor).to receive(:plan).and_return(plan_failure)
      expect { command.plan_template(:network, '{}', namespace_entity) }.not_to raise_error
    end
  end

  describe '#run' do
    let(:compilation_result) do
      Pangea::Entities::CompilationResult.new(
        success: true,
        terraform_json: '{"resource":{"aws_vpc":{"main":{"cidr_block":"10.0.0.0/16"}}}}',
        template_name: 'network',
        template_count: 1,
        errors: [],
        warnings: []
      )
    end

    let(:compiler) do
      comp = instance_double(Pangea::Compilation::TemplateCompiler)
      allow(comp).to receive(:compile_file).and_return(compilation_result)
      comp
    end

    before do
      allow(Pangea::Compilation::TemplateCompiler).to receive(:new).and_return(compiler)
    end

    around do |example|
      Dir.mktmpdir('pangea-test') do |dir|
        config = {
          'default_namespace' => 'dev',
          'namespaces' => {
            'dev' => { 'description' => 'Dev', 'state' => { 'type' => 'local' } }
          }
        }
        File.write(File.join(dir, 'pangea.yml'), YAML.dump(config))
        File.write(File.join(dir, 'network.rb'), "template :network do\nend\n")

        Dir.chdir(dir) do
          Pangea.instance_variable_set(:@configuration, nil)
          example.run
        end
      end
    end

    after { Pangea.instance_variable_set(:@configuration, nil) }

    it 'compiles template and runs plan' do
      expect(executor).to receive(:plan)
      command.run('network.rb', namespace: 'dev')
    end
  end
end
