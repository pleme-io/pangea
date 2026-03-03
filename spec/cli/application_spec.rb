# frozen_string_literal: true

require 'tmpdir'
require 'fileutils'
require 'yaml'
require 'pangea/cli/application'
require 'pangea/configuration'

RSpec.describe Pangea::CLI::Application do
  subject(:app) { described_class.new }

  describe 'command routing' do
    let(:executor) do
      ex = instance_double(Pangea::Execution::TerraformExecutor)
      allow(ex).to receive(:init).and_return(success: true, message: 'OK', output: '')
      allow(ex).to receive(:plan).and_return(
        success: true, changes: false, output: 'No changes.', exit_code: 0
      )
      allow(ex).to receive(:apply).and_return(success: true, added: 0, changed: 0, destroyed: 0, output: '')
      allow(ex).to receive(:destroy).and_return(success: true, output: '')
      allow(ex).to receive(:refresh).and_return(success: true, message: 'OK', output: '')
      allow(ex).to receive(:state_list).and_return(success: true, resources: [], output: '')
      allow(ex).to receive(:output).and_return(success: true, output: '{}', data: {})
      ex
    end

    let(:workspace_manager) do
      mgr = instance_double(Pangea::Execution::WorkspaceManager)
      ws = Dir.mktmpdir('pangea-ws')
      allow(mgr).to receive(:workspace_for).and_return(ws)
      allow(mgr).to receive(:write_terraform_json).and_return(File.join(ws, 'main.tf.json'))
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

    it 'routes init command' do
      stub_const('ARGV', ['init', 'infra.rb', '--namespace', 'dev'])
      expect(executor).to receive(:init)
      app.run
    end

    it 'routes plan command' do
      stub_const('ARGV', ['plan', 'infra.rb', '--namespace', 'dev'])
      expect(executor).to receive(:plan)
      app.run
    end

    it 'exits with version flag' do
      stub_const('ARGV', ['--version'])
      expect { app.run }.to raise_error(SystemExit)
    end

    it 'exits with help flag' do
      stub_const('ARGV', ['--help'])
      expect { app.run }.to raise_error(SystemExit)
    end

    it 'exits with no command' do
      stub_const('ARGV', [])
      expect { app.run }.to raise_error(SystemExit)
    end
  end
end
