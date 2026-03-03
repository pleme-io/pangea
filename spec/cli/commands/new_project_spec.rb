# frozen_string_literal: true

require 'tmpdir'
require 'fileutils'
require 'yaml'
require 'pangea/cli/commands/new_project'

RSpec.describe Pangea::CLI::Commands::NewProject do
  subject(:command) { described_class.new }

  let(:base_dir) { Dir.mktmpdir('pangea-new') }

  after { FileUtils.rm_rf(base_dir) }

  describe '#run' do
    context 'with basic template' do
      it 'creates project directory with all files' do
        project_dir = File.join(base_dir, 'my-project')
        command.run(project_dir, template: 'basic')

        expect(File.exist?(File.join(project_dir, 'pangea.yml'))).to be true
        expect(File.exist?(File.join(project_dir, '.gitignore'))).to be true
        expect(File.exist?(File.join(project_dir, 'my-project.rb'))).to be true
      end

      it 'creates valid pangea.yml' do
        project_dir = File.join(base_dir, 'test-infra')
        command.run(project_dir, template: 'basic')

        config = YAML.safe_load(File.read(File.join(project_dir, 'pangea.yml')))
        expect(config['default_namespace']).to eq('dev')
        expect(config['namespaces']).to have_key('dev')
        expect(config['namespaces']).to have_key('prod')
        expect(config['namespaces']['dev']['state']['type']).to eq('local')
      end

      it 'creates .gitignore with terraform and nix patterns' do
        project_dir = File.join(base_dir, 'test-infra')
        command.run(project_dir, template: 'basic')

        gitignore = File.read(File.join(project_dir, '.gitignore'))
        expect(gitignore).to include('.terraform/')
        expect(gitignore).to include('*.tfstate')
        expect(gitignore).to include('result')
        expect(gitignore).to include('.direnv/')
      end

      it 'creates starter template file' do
        project_dir = File.join(base_dir, 'test-infra')
        command.run(project_dir, template: 'basic')

        template = File.read(File.join(project_dir, 'test-infra.rb'))
        expect(template).to include('template :test_infra')
        expect(template).to include('provider :aws')
      end

      it 'creates .envrc with use flake' do
        project_dir = File.join(base_dir, 'test-infra')
        command.run(project_dir, template: 'basic')

        envrc = File.read(File.join(project_dir, '.envrc'))
        expect(envrc).to include('use flake')
      end

      it 'generates flake.nix with substrate import' do
        project_dir = File.join(base_dir, 'test-infra')
        command.run(project_dir, template: 'basic')

        flake = File.read(File.join(project_dir, 'flake.nix'))
        expect(flake).to include('pangea-infra-flake.nix')
        expect(flake).to include('name = "test-infra"')
        expect(flake).to include('github:pleme-io/substrate')
      end

      it 'generates Gemfile with pangea dependency' do
        project_dir = File.join(base_dir, 'test-infra')
        command.run(project_dir, template: 'basic')

        gemfile = File.read(File.join(project_dir, 'Gemfile'))
        expect(gemfile).to include("gem 'pangea'")
        expect(gemfile).to include("gem 'rspec'")
      end

      it 'generates CI workflow' do
        project_dir = File.join(base_dir, 'test-infra')
        command.run(project_dir, template: 'basic')

        ci = File.read(File.join(project_dir, '.github', 'workflows', 'ci.yml'))
        expect(ci).to include('nix run .#validate')
        expect(ci).to include('nix run .#test')
      end

      it 'generates test scaffold' do
        project_dir = File.join(base_dir, 'test-infra')
        command.run(project_dir, template: 'basic')

        expect(File.exist?(File.join(project_dir, 'spec', 'spec_helper.rb'))).to be true
        spec = File.read(File.join(project_dir, 'spec', 'test-infra_spec.rb'))
        expect(spec).to include("have_key('namespaces')")
      end
    end

    context 'with hetzner-k8s template' do
      it 'creates project with hcloud provider' do
        project_dir = File.join(base_dir, 'k8s-cluster')
        command.run(project_dir, template: 'hetzner-k8s')

        template = File.read(File.join(project_dir, 'k8s-cluster.rb'))
        expect(template).to include('provider :hcloud')
      end

      it 'creates .envrc with HCLOUD_TOKEN' do
        project_dir = File.join(base_dir, 'k8s-cluster')
        command.run(project_dir, template: 'hetzner-k8s')

        envrc = File.read(File.join(project_dir, '.envrc'))
        expect(envrc).to include('use flake')
        expect(envrc).to include('HCLOUD_TOKEN')
      end

      it 'configures S3 backend for prod' do
        project_dir = File.join(base_dir, 'k8s-cluster')
        command.run(project_dir, template: 'hetzner-k8s')

        config = YAML.safe_load(File.read(File.join(project_dir, 'pangea.yml')))
        prod_state = config['namespaces']['prod']['state']
        expect(prod_state['type']).to eq('s3')
        expect(prod_state['bucket']).to include('CHANGEME')
        expect(prod_state['key']).to include('terraform.tfstate')
      end
    end

    context 'with aws-vpc template' do
      it 'creates project with aws provider' do
        project_dir = File.join(base_dir, 'vpc-setup')
        command.run(project_dir, template: 'aws-vpc')

        template = File.read(File.join(project_dir, 'vpc-setup.rb'))
        expect(template).to include('provider :aws')
      end

      it 'creates .envrc with AWS vars' do
        project_dir = File.join(base_dir, 'vpc-setup')
        command.run(project_dir, template: 'aws-vpc')

        envrc = File.read(File.join(project_dir, '.envrc'))
        expect(envrc).to include('use flake')
        expect(envrc).to include('AWS_PROFILE')
        expect(envrc).to include('AWS_REGION')
      end
    end

    context 'error handling' do
      it 'exits with error for unknown template' do
        project_dir = File.join(base_dir, 'bad-project')
        expect { command.run(project_dir, template: 'nonexistent') }
          .to raise_error(SystemExit) { |e| expect(e.status).to eq(1) }
      end

      it 'exits with error when directory exists' do
        project_dir = File.join(base_dir, 'existing')
        FileUtils.mkdir_p(project_dir)
        expect { command.run(project_dir, template: 'basic') }
          .to raise_error(SystemExit) { |e| expect(e.status).to eq(1) }
      end
    end
  end
end
