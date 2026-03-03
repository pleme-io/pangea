# frozen_string_literal: true

require 'tmpdir'
require 'fileutils'
require 'yaml'
require 'json'
require 'pangea/configuration'
require 'pangea/compilation/template_compiler'
require 'pangea/execution/workspace_manager'
require 'pangea/execution/terraform_executor'

RSpec.describe 'End-to-end CLI pipeline' do
  let(:workspace_base) { Dir.mktmpdir('pangea-e2e-ws') }

  after { FileUtils.rm_rf(workspace_base) }

  describe 'config + compile + workspace pipeline' do
    around do |example|
      Dir.mktmpdir('pangea-e2e') do |dir|
        File.write(File.join(dir, 'pangea.yml'), YAML.dump(
          'default_namespace' => 'test',
          'namespaces' => {
            'test' => {
              'description' => 'Test environment',
              'state' => { 'type' => 'local' }
            }
          }
        ))

        File.write(File.join(dir, 'infra.rb'), <<~RUBY)
          template :network do
            provider :aws, region: "us-east-1"
          end
        RUBY

        Dir.chdir(dir) do
          Pangea.instance_variable_set(:@configuration, nil)
          example.run
        end
      end
    end

    after { Pangea.instance_variable_set(:@configuration, nil) }

    it 'loads config and resolves namespace' do
      config = Pangea::Configuration.new
      ns = config.namespace('test')
      expect(ns).not_to be_nil
      expect(ns.name).to eq('test')
      expect(ns.state[:type]).to eq(:local)
    end

    it 'compiles template successfully' do
      compiler = Pangea::Compilation::TemplateCompiler.new
      result = compiler.compile_file('infra.rb')
      expect(result.success).to be true
    end

    it 'creates workspace and writes terraform JSON' do
      manager = Pangea::Execution::WorkspaceManager.new(base_dir: workspace_base)
      workspace = manager.workspace_for(namespace: 'test', project: 'network')

      # Write a valid terraform config directly (bypassing compiler since
      # aws_vpc requires pangea-aws gem which isn't in the nix dev env)
      terraform_config = { 'resource' => { 'aws_vpc' => { 'main' => { 'cidr_block' => '10.0.0.0/16' } } } }

      path = manager.write_terraform_json(
        workspace: workspace,
        content: terraform_config
      )

      expect(File.exist?(path)).to be true
      written = JSON.parse(File.read(path))
      expect(written).to have_key('resource')
    end

    it 'full pipeline: config -> compile -> workspace -> metadata' do
      # 1. Load config
      config = Pangea::Configuration.new
      ns = config.namespace('test')

      # 2. Compile template (succeeds even without provider gems)
      compiler = Pangea::Compilation::TemplateCompiler.new
      result = compiler.compile_file('infra.rb')
      expect(result.success).to be true

      # 3. Setup workspace with pre-built terraform config
      manager = Pangea::Execution::WorkspaceManager.new(base_dir: workspace_base)
      workspace = manager.workspace_for(namespace: ns.name, project: 'network')

      terraform_config = { 'resource' => { 'aws_vpc' => { 'main' => { 'cidr_block' => '10.0.0.0/16' } } } }
      manager.write_terraform_json(workspace: workspace, content: terraform_config)

      # 4. Save metadata
      manager.save_metadata(workspace: workspace, metadata: {
        namespace: ns.name,
        template: 'network',
        source_file: 'infra.rb'
      })

      # 5. Verify
      meta = manager.workspace_metadata(workspace)
      expect(meta[:namespace]).to eq('test')
      expect(meta[:template]).to eq('network')

      tf_json = manager.read_terraform_json(workspace: workspace)
      expect(tf_json).to have_key(:resource)
    end
  end

  describe 'multi-template compilation' do
    around do |example|
      Dir.mktmpdir('pangea-multi') do |dir|
        File.write(File.join(dir, 'pangea.yml'), YAML.dump(
          'default_namespace' => 'dev',
          'namespaces' => { 'dev' => { 'description' => 'Dev', 'state' => { 'type' => 'local' } } }
        ))

        File.write(File.join(dir, 'multi.rb'), <<~RUBY)
          template :network do
            provider :aws, region: "us-east-1"
          end

          template :compute do
            provider :aws, region: "us-east-1"
          end
        RUBY

        Dir.chdir(dir) do
          Pangea.instance_variable_set(:@configuration, nil)
          example.run
        end
      end
    end

    after { Pangea.instance_variable_set(:@configuration, nil) }

    it 'compiles multiple templates from one file' do
      compiler = Pangea::Compilation::TemplateCompiler.new
      result = compiler.compile_file('multi.rb')
      expect(result.success).to be true
      expect(result.template_count).to be >= 2
    end
  end
end
