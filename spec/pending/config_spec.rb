# spec/pangea/config_spec.rb
require 'yaml'
require 'pangea/config'

RSpec.describe Pangea::Config do
  before(:each) do
    # Reset memoized configuration before each test.
    Pangea::Config.instance_variable_set(:@config, nil)
  end

  describe '.config' do
    context 'when no configuration files exist' do
      before do
        # Stub File.exist? to always return false.
        allow(File).to receive(:exist?).and_return(false)
      end

      it 'returns an empty hash' do
        expect(Pangea::Config.config).to eq({})
      end
    end

    context 'when configuration files exist' do
      let(:system_config_path) { '/etc/pangea/config.yml' }
      let(:user_config_path)   { File.expand_path('~/.config/pangea/config.yml') }
      let(:local_config_path)  { 'pangea.yml' }

      let(:system_config) { { a: 1, b: { x: 10, y: 20 } } }
      let(:user_config)   { { b: { y: 30, z: 40 }, c: 3 } }
      let(:local_config)  { { b: { z: 50 }, d: 4 } }

      before do
        # Stub File.exist? to return true only for the three expected file paths.
        allow(File).to receive(:exist?) do |file|
          [system_config_path, user_config_path, local_config_path].include?(file)
        end

        # Stub YAML.load_file to return predetermined configuration hashes.
        allow(YAML).to receive(:load_file) do |file|
          case file
          when system_config_path
            system_config
          when user_config_path
            user_config
          when local_config_path
            local_config
          end
        end
      end

      it 'deep merges configurations with correct priority' do
        # Expected merge:
        # Start with system_config: { a: 1, b: { x: 10, y: 20 } }
        # Merge user_config: { b: { y: 30, z: 40 }, c: 3 }  -> b becomes { x:10, y:30, z:40 }
        # Merge local_config: { b: { z: 50 }, d: 4 }        -> b becomes { x:10, y:30, z:50 }
        expected = {
          a: 1,
          b: { x: 10, y: 30, z: 50 },
          c: 3,
          d: 4
        }
        expect(Pangea::Config.config).to eq(expected)
      end
    end

    context 'memoization' do
      let(:dummy_config_path) { 'pangea.yml' }
      let(:dummy_config) { { foo: 'bar' } }

      before do
        # Only pangea.yml exists.
        allow(File).to receive(:exist?).and_return(false)
        allow(File).to receive(:exist?).with(dummy_config_path).and_return(true)

        # Expect YAML.load_file to be called only once.
        expect(YAML).to receive(:load_file).with(dummy_config_path).once.and_return(dummy_config)
      end

      it 'loads configuration only once' do
        config1 = Pangea::Config.config
        config2 = Pangea::Config.config
        expect(config1).to eq(dummy_config)
        expect(config1).to equal(config2)
      end
    end
  end
end
