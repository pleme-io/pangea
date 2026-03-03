# frozen_string_literal: true

require 'tmpdir'
require 'fileutils'
require 'yaml'
require 'pangea/cli/commands/init'
require 'pangea/configuration'
require 'pangea/execution/workspace_manager'
require 'pangea/execution/terraform_executor'

RSpec.describe Pangea::CLI::Commands::Init do
  subject(:command) { described_class.new }

  let(:workspace_dir) { Dir.mktmpdir('pangea-ws') }
  let(:namespace_entity) do
    Pangea::Entities::Namespace.new(
      name: 'dev',
      description: 'Development',
      state: { type: :local, config: {} },
      tags: {}
    )
  end

  let(:executor) do
    instance_double(Pangea::Execution::TerraformExecutor,
      init: { success: true, message: 'Initialized', output: 'Terraform has been initialized!' })
  end

  let(:workspace_manager) do
    mgr = instance_double(Pangea::Execution::WorkspaceManager)
    allow(mgr).to receive(:workspace_for).and_return(workspace_dir)
    allow(mgr).to receive(:write_terraform_json).and_return(File.join(workspace_dir, 'main.tf.json'))
    allow(mgr).to receive(:save_metadata)
    allow(mgr).to receive(:initialized?).and_return(false)
    mgr
  end

  before do
    allow(Pangea::Execution::TerraformExecutor).to receive(:new).and_return(executor)
    allow(Pangea::Execution::WorkspaceManager).to receive(:new).and_return(workspace_manager)
  end

  after { FileUtils.rm_rf(workspace_dir) }

  describe '#init_template' do
    before do
      command.instance_variable_set(:@workspace_manager, workspace_manager)
      command.instance_variable_set(:@namespace, 'dev')
      command.instance_variable_set(:@file_path, 'infra.rb')
    end

    it 'runs terraform init and reports success' do
      expect(executor).to receive(:init).with(stream_output: true)
        .and_return(success: true, message: 'Initialized', output: 'done')

      command.init_template(:network, '{"provider":{}}', namespace_entity)
    end

    it 'calls exit 1 on init failure' do
      allow(executor).to receive(:init)
        .and_return(success: false, error: 'backend error', output: '')

      expect { command.init_template(:network, '{}', namespace_entity) }
        .to raise_error(SystemExit) { |e| expect(e.status).to eq(1) }
    end
  end

  describe '#run' do
    let(:compilation_result) do
      Pangea::Entities::CompilationResult.new(
        success: true,
        terraform_json: '{"resource":{"aws_vpc":{"main":{"cidr_block":"10.0.0.0/16"}}}}',
        template_name: 'infra',
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
        File.write(File.join(dir, 'infra.rb'), "template :infra do\nend\n")

        Dir.chdir(dir) do
          Pangea.instance_variable_set(:@configuration, nil)
          example.run
        end
      end
    end

    after { Pangea.instance_variable_set(:@configuration, nil) }

    it 'compiles the template and runs init' do
      expect(executor).to receive(:init).and_return(success: true, message: 'OK', output: '')
      command.run('infra.rb', namespace: 'dev')
    end

    it 'handles compilation failure gracefully' do
      failed_result = Pangea::Entities::CompilationResult.new(
        success: false, errors: ['File not found'], warnings: []
      )
      allow(compiler).to receive(:compile_file).and_return(failed_result)
      expect(executor).not_to receive(:init)
      command.run('infra.rb', namespace: 'dev')
    end
  end
end
