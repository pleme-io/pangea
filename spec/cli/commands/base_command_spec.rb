# frozen_string_literal: true

require 'tmpdir'
require 'fileutils'
require 'stringio'
require 'yaml'
require 'pangea/cli/commands/base_command'
require 'pangea/configuration'

RSpec.describe Pangea::CLI::Commands::BaseCommand do
  subject(:command) { described_class.new }

  describe '#ui' do
    it 'returns a Logger instance' do
      expect(command.ui).to be_a(Pangea::CLI::UI::Logger)
    end

    it 'memoizes the logger' do
      expect(command.ui).to be(command.ui)
    end
  end

  describe '#ci_environment?' do
    after { %w[CI CONTINUOUS_INTEGRATION GITHUB_ACTIONS GITLAB_CI].each { |k| ENV.delete(k) } }

    it 'detects CI env var' do
      ENV['CI'] = 'true'
      expect(command.ci_environment?).to be_truthy
    end

    it 'detects GITHUB_ACTIONS' do
      ENV['GITHUB_ACTIONS'] = 'true'
      expect(command.ci_environment?).to be_truthy
    end

    it 'detects GITLAB_CI' do
      ENV['GITLAB_CI'] = 'true'
      expect(command.ci_environment?).to be_truthy
    end

    it 'returns falsy when no CI env set' do
      expect(command.ci_environment?).to be_falsy
    end
  end

  describe '#with_spinner' do
    it 'yields and returns the block result' do
      result = command.with_spinner('Working') { 42 }
      expect(result).to eq(42)
    end

    it 're-raises exceptions from the block' do
      expect {
        command.with_spinner('Working') { raise 'boom' }
      }.to raise_error(RuntimeError, 'boom')
    end
  end

  describe '#measure_time' do
    it 'yields and returns the block result' do
      result = command.measure_time { 'done' }
      expect(result).to eq('done')
    end
  end

  describe '#load_namespace' do
    it 'returns nil for nil name' do
      expect(command.load_namespace(nil)).to be_nil
    end

    context 'with a valid config' do
      around do |example|
        Dir.mktmpdir('pangea-test') do |dir|
          config = {
            'default_namespace' => 'dev',
            'namespaces' => {
              'dev' => { 'description' => 'Development', 'state' => { 'type' => 'local' } }
            }
          }
          File.write(File.join(dir, 'pangea.yml'), YAML.dump(config))
          Dir.chdir(dir) { example.run }
        end
      end

      it 'returns a namespace entity for valid name' do
        # Reset config so it picks up the test dir
        Pangea.instance_variable_set(:@configuration, nil)
        ns = command.load_namespace('dev')
        expect(ns).to be_a(Pangea::Entities::Namespace)
        expect(ns.name).to eq('dev')
      ensure
        Pangea.instance_variable_set(:@configuration, nil)
      end
    end
  end

  describe '#format_duration' do
    it 'formats seconds under 60' do
      expect(command.send(:format_duration, 5.123)).to eq('5.12s')
    end

    it 'formats minutes and seconds' do
      expect(command.send(:format_duration, 125)).to eq('2m 5s')
    end
  end
end
