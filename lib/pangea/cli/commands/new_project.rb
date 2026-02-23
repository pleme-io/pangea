# frozen_string_literal: true

require 'fileutils'
require 'yaml'
require 'pangea/cli/commands/base_command'

module Pangea
  module CLI
    module Commands
      # Scaffold a new Pangea project
      class NewProject < BaseCommand
        TEMPLATES = {
          'basic' => {
            description: 'Minimal project with local state',
            namespaces: {
              'dev' => { type: 'local' },
              'prod' => { type: 'local' }
            }
          },
          'hetzner-k8s' => {
            description: 'Hetzner Cloud Kubernetes cluster',
            namespaces: {
              'dev' => { type: 'local' },
              'prod' => { type: 's3', bucket: 'CHANGEME-tf-state', key: 'terraform.tfstate', region: 'eu-central-1' }
            },
            provider: :hcloud,
            envrc_vars: %w[HCLOUD_TOKEN]
          },
          'aws-vpc' => {
            description: 'AWS VPC with public/private subnets',
            namespaces: {
              'dev' => { type: 'local' },
              'prod' => { type: 's3', bucket: 'CHANGEME-tf-state', key: 'terraform.tfstate', region: 'us-east-1' }
            },
            provider: :aws,
            envrc_vars: %w[AWS_PROFILE AWS_REGION]
          }
        }.freeze

        def run(project_name, template: 'basic')
          unless TEMPLATES.key?(template)
            ui.error "Unknown template: #{template}"
            ui.error "Available templates: #{TEMPLATES.keys.join(', ')}"
            exit 1
          end

          project_dir = File.expand_path(project_name)
          basename = File.basename(project_dir)

          if File.exist?(project_dir)
            ui.error "Directory already exists: #{project_dir}"
            exit 1
          end

          scaffold = TEMPLATES[template]

          FileUtils.mkdir_p(project_dir)

          write_config(project_dir, basename, scaffold)
          write_gitignore(project_dir)
          write_envrc(project_dir, scaffold)
          write_template(project_dir, basename, scaffold)
          write_flake_nix(project_dir, basename)
          write_gemfile(project_dir)
          write_ci_workflow(project_dir, basename)
          write_test_scaffold(project_dir, basename)

          ui.success "Project '#{basename}' created at #{project_dir}"
          ui.info "  Template: #{template} — #{scaffold[:description]}"
          ui.info ""
          ui.info 'Next steps:'
          ui.info "  cd #{basename}"
          ui.info '  nix develop              # Enter dev shell'
          ui.info '  nix run .#init -- dev    # Initialize terraform'
          ui.info '  nix run .#plan -- dev    # Plan changes'
          ui.info '  nix run .#apply -- dev   # Apply changes'
        end

        private

        def write_config(dir, project_name, scaffold)
          namespaces = {}
          scaffold[:namespaces].each do |name, opts|
            ns = { 'description' => "#{name.capitalize} environment" }
            state = { 'type' => opts[:type] }
            if opts[:type] == 's3'
              state['bucket'] = opts[:bucket]
              state['key'] = "#{project_name}/#{opts[:key]}"
              state['region'] = opts[:region]
            end
            ns['state'] = state
            namespaces[name] = ns
          end

          config = {
            'default_namespace' => scaffold[:namespaces].keys.first,
            'namespaces' => namespaces
          }

          File.write(File.join(dir, 'pangea.yml'), YAML.dump(config))
        end

        def write_gitignore(dir)
          content = <<~GITIGNORE
            .terraform/
            *.tfstate
            *.tfstate.backup
            *.tfplan
            .pangea/
            .terraform.lock.hcl
            result
            result-*
            .direnv/
          GITIGNORE

          File.write(File.join(dir, '.gitignore'), content)
        end

        def write_envrc(dir, scaffold)
          vars = scaffold[:envrc_vars] || []
          var_lines = vars.map { |v| "export #{v}=" }

          content = "use flake\n"
          content += "# Provider credentials\n"
          if var_lines.empty?
            content += "# export HCLOUD_TOKEN=\n"
            content += "# export AWS_PROFILE=\n"
          else
            content += "#{var_lines.join("\n")}\n"
          end

          File.write(File.join(dir, '.envrc'), content)
        end

        def write_template(dir, project_name, scaffold)
          provider = scaffold[:provider] || :aws
          region = provider == :hcloud ? nil : '"us-east-1"'

          provider_line = if region
                            "  provider :#{provider}, region: #{region}"
                          else
                            "  provider :#{provider}"
                          end

          content = <<~RUBY
            template :#{project_name.tr('-', '_')} do
            #{provider_line}

              # Define your infrastructure here
              # See: https://github.com/pleme-io/pangea
            end
          RUBY

          File.write(File.join(dir, "#{project_name}.rb"), content)
        end

        def write_flake_nix(dir, basename)
          content = <<~NIX
            {
              description = "#{basename} infrastructure";

              inputs = {
                nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
                ruby-nix.url = "github:inscapist/ruby-nix";
                flake-utils.url = "github:numtide/flake-utils";
                substrate = {
                  url = "github:pleme-io/substrate";
                  inputs.nixpkgs.follows = "nixpkgs";
                };
                forge = {
                  url = "github:pleme-io/forge";
                  inputs.nixpkgs.follows = "nixpkgs";
                  inputs.substrate.follows = "substrate";
                };
              };

              outputs = { self, nixpkgs, ruby-nix, flake-utils, substrate, forge, ... }:
                (import "${substrate}/lib/pangea-infra-flake.nix" {
                  inherit nixpkgs ruby-nix flake-utils substrate forge;
                }) {
                  inherit self;
                  name = "#{basename}";
                };
            }
          NIX

          File.write(File.join(dir, 'flake.nix'), content)
        end

        def write_gemfile(dir)
          content = <<~GEMFILE
            source 'https://rubygems.org'

            gem 'pangea', '~> 1.0'

            group :test do
              gem 'rspec', '~> 3.12'
            end
          GEMFILE

          File.write(File.join(dir, 'Gemfile'), content)
        end

        def write_ci_workflow(dir, basename)
          workflow_dir = File.join(dir, '.github', 'workflows')
          FileUtils.mkdir_p(workflow_dir)

          content = <<~YAML
            name: Infrastructure CI

            on:
              push:
                branches: [main]
              pull_request:

            jobs:
              validate:
                runs-on: ubuntu-latest
                steps:
                  - uses: actions/checkout@v4
                  - uses: DeterminateSystems/nix-installer-action@main
                  - uses: DeterminateSystems/magic-nix-cache-action@main
                  - run: nix run .#validate -- dev

              test:
                runs-on: ubuntu-latest
                steps:
                  - uses: actions/checkout@v4
                  - uses: DeterminateSystems/nix-installer-action@main
                  - uses: DeterminateSystems/magic-nix-cache-action@main
                  - run: nix run .#test
          YAML

          File.write(File.join(workflow_dir, 'ci.yml'), content)
        end

        def write_test_scaffold(dir, basename)
          spec_dir = File.join(dir, 'spec')
          FileUtils.mkdir_p(spec_dir)

          helper_content = <<~RUBY
            require 'yaml'

            RSpec.configure do |config|
              config.formatter = :documentation
            end
          RUBY

          spec_content = <<~RUBY
            require 'spec_helper'

            RSpec.describe '#{basename} infrastructure' do
              it 'has valid pangea.yml' do
                config = YAML.safe_load(File.read('pangea.yml'))
                expect(config).to have_key('namespaces')
              end
            end
          RUBY

          File.write(File.join(spec_dir, 'spec_helper.rb'), helper_content)
          File.write(File.join(spec_dir, "#{basename}_spec.rb"), spec_content)
        end
      end
    end
  end
end
