# frozen_string_literal: true

require 'tmpdir'
require 'fileutils'
require 'stringio'
require 'yaml'

module CLITestHelpers
  def create_test_config(dir, namespaces: { dev: { state: { type: :local } } })
    config = { 'default_namespace' => namespaces.keys.first.to_s, 'namespaces' => {} }
    namespaces.each do |name, opts|
      state = opts[:state] || { type: :local }
      config['namespaces'][name.to_s] = {
        'description' => "#{name} namespace",
        'state' => state.transform_keys(&:to_s)
      }
    end

    config_path = File.join(dir, 'pangea.yml')
    File.write(config_path, YAML.dump(config))
    config_path
  end

  def create_test_template(dir, name, content = nil)
    content ||= <<~RUBY
      template :#{name} do
        provider :aws, region: "us-east-1"
        aws_vpc :main, cidr_block: "10.0.0.0/16"
      end
    RUBY

    file_path = File.join(dir, "#{name}.rb")
    File.write(file_path, content)
    file_path
  end

  def mock_terraform_executor(
    init: { success: true, message: 'Initialized', output: '' },
    plan: { success: true, changes: true, output: 'Plan: 1 to add', resource_changes: {} },
    apply: { success: true, added: 1, changed: 0, destroyed: 0, output: 'Apply complete!' },
    destroy: { success: true, output: 'Destroy complete!' },
    state_list: { success: true, resources: [], output: '' },
    refresh: { success: true, message: 'Refreshed', output: '' },
    output: { success: true, output: '{}', data: {} },
    version: { success: true, version: '1.6.0', output: 'OpenTofu v1.6.0' }
  )
    executor = instance_double(Pangea::Execution::TerraformExecutor)
    allow(executor).to receive(:init).and_return(init)
    allow(executor).to receive(:plan).and_return(plan)
    allow(executor).to receive(:apply).and_return(apply)
    allow(executor).to receive(:destroy).and_return(destroy)
    allow(executor).to receive(:state_list).and_return(state_list)
    allow(executor).to receive(:refresh).and_return(refresh)
    allow(executor).to receive(:output).and_return(output)
    allow(executor).to receive(:version).and_return(version)
    executor
  end

  def mock_workspace_manager(workspace_path: nil)
    manager = instance_double(Pangea::Execution::WorkspaceManager)
    ws_path = workspace_path || Dir.mktmpdir('pangea-test-ws')
    allow(manager).to receive(:workspace_for).and_return(ws_path)
    allow(manager).to receive(:write_terraform_json).and_return(File.join(ws_path, 'main.tf.json'))
    allow(manager).to receive(:read_terraform_json).and_return({})
    allow(manager).to receive(:initialized?).and_return(false)
    allow(manager).to receive(:clean)
    allow(manager).to receive(:remove)
    allow(manager).to receive(:save_metadata)
    allow(manager).to receive(:workspace_metadata).and_return({})
    manager
  end

  def with_test_project(namespaces: { dev: { state: { type: :local } } })
    Dir.mktmpdir('pangea-test') do |dir|
      create_test_config(dir, namespaces: namespaces)
      create_test_template(dir, 'main')
      Dir.chdir(dir) do
        yield dir
      end
    end
  end

  def suppress_output
    original_stdout = $stdout
    original_stderr = $stderr
    $stdout = StringIO.new
    $stderr = StringIO.new
    yield
  ensure
    $stdout = original_stdout
    $stderr = original_stderr
  end

  def capture_output
    original_stdout = $stdout
    original_stderr = $stderr
    $stdout = StringIO.new
    $stderr = StringIO.new
    yield
    { stdout: $stdout.string, stderr: $stderr.string }
  ensure
    $stdout = original_stdout
    $stderr = original_stderr
  end
end
