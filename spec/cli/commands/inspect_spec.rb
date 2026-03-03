# frozen_string_literal: true

require 'tmpdir'
require 'fileutils'
require 'stringio'
require 'yaml'
require 'json'
require 'pangea/cli/commands/inspect'
require 'pangea/configuration'

RSpec.describe Pangea::CLI::Commands::Inspect do
  subject(:command) { described_class.new }

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
        File.write(File.join(dir, 'network.rb'), "template :network do\nend\n")

        Dir.chdir(dir) do
          Pangea.instance_variable_set(:@configuration, nil)
          # Pre-load configuration so it doesn't print to stdout during tests
          Pangea.configuration
          example.run
        end
      end
    end

    after { Pangea.instance_variable_set(:@configuration, nil) }

    it 'returns error for unknown inspection type' do
      output = capture_stdout { command.run(nil, type: 'bogus', format: 'json') }
      result = JSON.parse(output)
      expect(result['error']).to match(/unknown/i)
    end

    it 'outputs valid JSON format' do
      output = capture_stdout { command.run(nil, type: 'config', format: 'json') }
      expect { JSON.parse(output) }.not_to raise_error
    end

    it 'outputs valid YAML format' do
      output = capture_stdout { command.run(nil, type: 'config', format: 'yaml') }
      expect { YAML.safe_load(output, permitted_classes: [Symbol, Date, Time]) }.not_to raise_error
    end

    it 'inspects config when type is config' do
      output = capture_stdout { command.run(nil, type: 'config', format: 'json', namespace: 'dev') }
      result = JSON.parse(output)
      expect(result).to be_a(Hash)
    end

    it 'handles missing file gracefully' do
      output = capture_stdout { command.run('missing.rb', type: 'templates', format: 'json') }
      result = JSON.parse(output)
      expect(result).to have_key('error')
    end
  end

  private

  def capture_stdout
    original = $stdout
    $stdout = StringIO.new
    yield
    $stdout.string
  ensure
    $stdout = original
  end
end
