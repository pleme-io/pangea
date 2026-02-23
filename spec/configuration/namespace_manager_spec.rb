# frozen_string_literal: true

require 'tmpdir'
require 'fileutils'
require 'yaml'
require 'pangea/configuration'

RSpec.describe 'Pangea::Configuration::NamespaceManager' do
  let(:config_dir) { Dir.mktmpdir('pangea-ns') }

  after { FileUtils.rm_rf(config_dir) }

  def make_config(namespaces)
    cfg = { 'default_namespace' => namespaces.keys.first, 'namespaces' => {} }
    namespaces.each do |name, opts|
      cfg['namespaces'][name.to_s] = opts.transform_keys(&:to_s)
    end
    File.write(File.join(config_dir, 'pangea.yml'), YAML.dump(cfg))
  end

  def load_config
    Dir.chdir(config_dir) { Pangea::Configuration.new }
  end

  describe '#namespaces' do
    it 'loads namespaces from config' do
      make_config(
        'dev' => { 'description' => 'Dev', 'state' => { 'type' => 'local' } },
        'prod' => { 'description' => 'Prod', 'state' => { 'type' => 's3', 'bucket' => 'tf-state', 'key' => 'terraform.tfstate' } }
      )
      config = load_config
      expect(config.namespaces.length).to eq(2)
    end

    it 'returns Namespace entities' do
      make_config('dev' => { 'description' => 'Dev', 'state' => { 'type' => 'local' } })
      config = load_config
      ns = config.namespaces.first
      expect(ns).to be_a(Pangea::Entities::Namespace)
      expect(ns.name).to eq('dev')
      expect(ns.description).to eq('Dev')
    end
  end

  describe '#namespace' do
    before do
      make_config(
        'dev' => { 'description' => 'Dev', 'state' => { 'type' => 'local' } },
        'prod' => { 'description' => 'Prod', 'state' => { 'type' => 's3', 'bucket' => 'b', 'key' => 'terraform.tfstate' } }
      )
    end

    it 'returns the requested namespace' do
      config = load_config
      ns = config.namespace('prod')
      expect(ns.name).to eq('prod')
    end

    it 'returns nil for non-existent namespace' do
      config = load_config
      expect(config.namespace('staging')).to be_nil
    end
  end

  describe '#namespace?' do
    before do
      make_config('dev' => { 'description' => 'Dev', 'state' => { 'type' => 'local' } })
    end

    it 'returns true for existing namespace' do
      expect(load_config.namespace?('dev')).to be true
    end

    it 'returns false for missing namespace' do
      expect(load_config.namespace?('prod')).to be false
    end
  end

  describe '#default_namespace' do
    it 'returns the first namespace as default' do
      make_config('staging' => { 'description' => 'Staging', 'state' => { 'type' => 'local' } })
      expect(load_config.default_namespace).to eq('staging')
    end

    it 'prefers PANGEA_NAMESPACE env var' do
      make_config('dev' => { 'description' => 'Dev', 'state' => { 'type' => 'local' } })
      ENV['PANGEA_NAMESPACE'] = 'override'
      expect(load_config.default_namespace).to eq('override')
    ensure
      ENV.delete('PANGEA_NAMESPACE')
    end
  end

  describe 'state configuration' do
    it 'parses local state config' do
      make_config('dev' => { 'description' => 'Dev', 'state' => { 'type' => 'local' } })
      ns = load_config.namespace('dev')
      expect(ns.state[:type]).to eq(:local)
    end

    it 'parses S3 state config with bucket' do
      make_config('prod' => {
        'description' => 'Prod',
        'state' => { 'type' => 's3', 'bucket' => 'my-bucket', 'key' => 'terraform.tfstate', 'region' => 'us-east-1' }
      })
      ns = load_config.namespace('prod')
      expect(ns.state[:type]).to eq(:s3)
      expect(ns.state[:config][:bucket]).to eq('my-bucket')
    end
  end
end
