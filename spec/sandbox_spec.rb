# frozen_string_literal: true

require %(pangea/sandbox)

Rspec.configure do |config|
  config.before(:suite) do
    @sandbox = Sandbox.new(
      base_dir: %(./spare/spec/sandbox),
      name: %(spec_test_sandbox),
      rubies: [
        SandBoxruby.new(
          base_dir: %(./spare/spec/sandbox),
          version: %(3.1.0),
          name: %(spec_test_ruby),
          gemset: %(spec_test_ruby_gemset)
        )
      ]
    )
    @sandbox.prepare_sandbox
  end

  config.after(:suite) do
    @sandbox = Sandbox.new(
      base_dir: %(./spare/spec/sandbox),
      name: %(spec_test_sandbox),
      rubies: [
        SandBoxruby.new(
          base_dir: %(./spare/spec/sandbox),
          version: %(3.1.0),
          name: %(spec_test_ruby),
          gemset: %(spec_test_ruby_gemset)
        )
      ]
    )
    @sandbox.clean_sandbox
  end
end

describe Sandbox do
  let(:sandbox) do
    Sandbox.new(
      base_dir: %(./spare/spec/sandbox),
      name: %(spec_test_sandbox),
      rubies: [
        SandBoxruby.new(
          base_dir: %(./spare/spec/sandbox),
          version: %(3.1.0),
          name: %(spec_test_ruby),
          gemset: %(spec_test_ruby_gemset)
        )
      ]
    )
  end

  let(:sandbox_base_dir) { %(./spare/spec/sandbox) }

  context %(default) do
    it %(creates appropriate sandbox) do
      nil
    end
  end
end
