# frozen_string_literal: true

require 'tmpdir'
require 'fileutils'
require 'yaml'
require 'pangea/configuration'

RSpec.describe Pangea::Configuration do
  subject(:config) { described_class.new }

  describe 'config loading' do
    context 'when pangea.yml exists in current directory' do
      around do |example|
        Dir.mktmpdir('pangea-config') do |dir|
          File.write(File.join(dir, 'pangea.yml'), YAML.dump(
            'default_namespace' => 'dev',
            'namespaces' => {
              'dev' => {
                'description' => 'Development environment',
                'state' => { 'type' => 'local' }
              },
              'prod' => {
                'description' => 'Production',
                'state' => {
                  'type' => 's3',
                  'bucket' => 'my-state',
                  'key' => 'terraform.tfstate',
                  'region' => 'us-east-1'
                }
              }
            }
          ))
          Dir.chdir(dir) { example.run }
        end
      end

      it 'loads configuration from pangea.yml' do
        expect(config.default_namespace).to eq('dev')
      end

      it 'finds all configured namespaces' do
        names = config.namespaces.map(&:name)
        expect(names).to contain_exactly('dev', 'prod')
      end

      it 'returns namespace entity by name' do
        ns = config.namespace('dev')
        expect(ns).to be_a(Pangea::Entities::Namespace)
        expect(ns.name).to eq('dev')
      end

      it 'returns nil for unknown namespace' do
        expect(config.namespace('staging')).to be_nil
      end

      it 'checks namespace existence' do
        expect(config.namespace?('dev')).to be true
        expect(config.namespace?('staging')).to be false
      end
    end

    context 'when no config file exists' do
      around do |example|
        Dir.mktmpdir('pangea-empty') do |dir|
          Dir.chdir(dir) { example.run }
        end
      end

      it 'uses defaults without raising' do
        expect { config }.not_to raise_error
      end

      it 'returns empty namespaces' do
        expect(config.namespaces).to be_empty
      end
    end

    context 'with environment variable override' do
      around do |example|
        Dir.mktmpdir('pangea-env') do |dir|
          Dir.chdir(dir) do
            ENV['PANGEA_NAMESPACE'] = 'staging'
            example.run
          end
        end
      end

      after { ENV.delete('PANGEA_NAMESPACE') }

      it 'returns env var namespace as default' do
        expect(config.default_namespace).to eq('staging')
      end
    end
  end

  describe 'search paths' do
    it 'searches current directory first' do
      paths = Pangea::Configuration::ConfigLoader::CONFIG_PATHS
      expect(paths.first.call).to eq(Dir.pwd)
    end
  end
end
