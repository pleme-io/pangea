# frozen_string_literal: true

require 'tmpdir'
require 'fileutils'
require 'yaml'
require 'pangea/cli/commands/destroy'
require 'pangea/configuration'
require 'pangea/execution/workspace_manager'
require 'pangea/execution/terraform_executor'

RSpec.describe Pangea::CLI::Commands::Destroy do
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
    allow(ex).to receive(:state_list).and_return(
      success: true, resources: ['aws_vpc.main', 'aws_subnet.public'], output: ''
    )
    allow(ex).to receive(:destroy).and_return(
      success: true, output: 'Destroy complete! Resources: 2 destroyed.'
    )
    ex
  end

  let(:workspace_manager) do
    mgr = instance_double(Pangea::Execution::WorkspaceManager)
    allow(mgr).to receive(:workspace_for).and_return(workspace_dir)
    allow(mgr).to receive(:write_terraform_json).and_return(File.join(workspace_dir, 'main.tf.json'))
    allow(mgr).to receive(:save_metadata)
    allow(mgr).to receive(:initialized?).and_return(true)
    allow(mgr).to receive(:clean)
    allow(mgr).to receive(:workspace_metadata).and_return({})
    mgr
  end

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
    allow(Pangea::Execution::TerraformExecutor).to receive(:new).and_return(executor)
    allow(Pangea::Execution::WorkspaceManager).to receive(:new).and_return(workspace_manager)
    allow(Pangea::Compilation::TemplateCompiler).to receive(:new).and_return(compiler)
  end

  after { FileUtils.rm_rf(workspace_dir) }

  describe '#run' do
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

    it 'lists state and runs destroy with auto-approve' do
      expect(executor).to receive(:state_list)
      expect(executor).to receive(:destroy)
      command.run('infra.rb', namespace: 'dev', auto_approve: true)
    end

    it 'handles destroy failure' do
      allow(executor).to receive(:destroy).and_return(
        success: false, error: 'Resource locked', output: ''
      )
      expect { command.run('infra.rb', namespace: 'dev', auto_approve: true) }
        .not_to raise_error
    end
  end
end
