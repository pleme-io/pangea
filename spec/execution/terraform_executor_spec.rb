# frozen_string_literal: true

require 'tmpdir'
require 'fileutils'
require 'stringio'
require 'open3'
require 'pangea/execution/terraform_executor'
require 'pangea/logging/structured_logger'

RSpec.describe Pangea::Execution::TerraformExecutor do
  let(:working_dir) { Dir.mktmpdir('pangea-tf') }
  let(:logger) { instance_double(Pangea::Logging::StructuredLogger).as_null_object }

  subject(:executor) do
    described_class.new(working_dir: working_dir, binary: 'tofu', logger: logger)
  end

  after { FileUtils.rm_rf(working_dir) }

  def make_status(exit_code)
    instance_double(Process::Status, exitstatus: exit_code, success?: exit_code == 0)
  end

  def make_wait_thr(exit_code)
    status = make_status(exit_code)
    double('wait_thr', value: status, pid: 12345)
  end

  def stub_open3(stdout: '', stderr: '', exit_code: 0)
    allow(Open3).to receive(:popen3).and_yield(
      instance_double(IO, close: nil),
      StringIO.new(stdout),
      StringIO.new(stderr),
      make_wait_thr(exit_code)
    )
  end

  describe '#init' do
    it 'returns success on successful init' do
      stub_open3(stdout: "Terraform has been successfully initialized!\n")
      result = executor.init
      expect(result[:success]).to be true
    end

    it 'returns failure on init error' do
      stub_open3(stderr: "Error: Failed to initialize backend", exit_code: 1)
      result = executor.init
      expect(result[:success]).to be false
    end

    it 'includes -upgrade flag when requested' do
      captured_cmd = nil
      allow(Open3).to receive(:popen3) do |*args, **_opts, &block|
        captured_cmd = args
        block.call(
          instance_double(IO, close: nil),
          StringIO.new("Initialized\n"),
          StringIO.new(''),
          make_wait_thr(0)
        )
      end
      executor.init(upgrade: true)
      expect(captured_cmd.join(' ')).to include('-upgrade')
    end
  end

  describe '#plan' do
    it 'returns success with changes on exit code 2' do
      stub_open3(
        stdout: "Plan: 1 to add, 0 to change, 0 to destroy.\n",
        exit_code: 2
      )
      result = executor.plan
      expect(result[:success]).to be true
      expect(result[:changes]).to be true
    end

    it 'returns success without changes on exit code 0' do
      stub_open3(
        stdout: "No changes. Infrastructure is up-to-date.\n",
        exit_code: 0
      )
      result = executor.plan
      expect(result[:success]).to be true
      expect(result[:changes]).to be false
    end

    it 'returns failure on exit code 1' do
      stub_open3(stderr: "Error: Invalid provider configuration", exit_code: 1)
      result = executor.plan
      expect(result[:success]).to be false
    end

    it 'includes -out flag when out_file specified' do
      captured_cmd = nil
      allow(Open3).to receive(:popen3) do |*args, **_opts, &block|
        captured_cmd = args
        block.call(
          instance_double(IO, close: nil),
          StringIO.new("Plan saved\n"),
          StringIO.new(''),
          make_wait_thr(2)
        )
      end
      executor.plan(out_file: File.join(working_dir, 'plan.tfplan'))
      expect(captured_cmd.join(' ')).to include('-out=')
    end
  end

  describe '#apply' do
    it 'returns success with resource counts' do
      output = "Apply complete! Resources: 2 added, 1 changed, 0 destroyed.\n"
      stub_open3(stdout: output)
      result = executor.apply(auto_approve: true)
      expect(result[:success]).to be true
      expect(result[:added]).to eq(2)
      expect(result[:changed]).to eq(1)
      expect(result[:destroyed]).to eq(0)
    end

    it 'returns failure on apply error' do
      stub_open3(stderr: "Error: Error creating VPC", exit_code: 1)
      result = executor.apply(auto_approve: true)
      expect(result[:success]).to be false
    end
  end

  describe '#destroy' do
    it 'returns success on successful destroy' do
      stub_open3(stdout: "Destroy complete! Resources: 3 destroyed.\n")
      result = executor.destroy(auto_approve: true)
      expect(result[:success]).to be true
    end

    it 'returns failure on destroy error' do
      stub_open3(stderr: "Error: Resource is locked", exit_code: 1)
      result = executor.destroy(auto_approve: true)
      expect(result[:success]).to be false
    end
  end

  describe '#state_list' do
    it 'returns list of managed resources' do
      stub_open3(stdout: "aws_vpc.main\naws_subnet.public\n")
      result = executor.state_list
      expect(result[:success]).to be true
      expect(result[:resources]).to contain_exactly('aws_vpc.main', 'aws_subnet.public')
    end

    it 'returns empty list when no state' do
      stub_open3(stdout: '')
      result = executor.state_list
      expect(result[:resources]).to be_empty
    end
  end

  describe '#refresh' do
    it 'returns success on refresh' do
      stub_open3(stdout: "aws_vpc.main: Refreshing state...\n")
      result = executor.refresh
      expect(result[:success]).to be true
    end
  end

  describe '#version' do
    it 'returns version string' do
      stub_open3(stdout: "OpenTofu v1.6.0\n")
      result = executor.version
      expect(result[:success]).to be true
    end
  end

  describe 'retry logic' do
    it 'retries on timeout errors' do
      call_count = 0
      allow(Open3).to receive(:popen3) do |*_args, **_opts, &block|
        call_count += 1
        exit_code = call_count < 2 ? 1 : 0
        stderr_text = call_count < 2 ? "Error: connection timed out" : ''
        block.call(
          instance_double(IO, close: nil),
          StringIO.new("OK\n"),
          StringIO.new(stderr_text),
          make_wait_thr(exit_code)
        )
      end

      allow(executor).to receive(:sleep)
      result = executor.init
      expect(result[:success]).to be true
      expect(call_count).to eq(2)
    end
  end
end
