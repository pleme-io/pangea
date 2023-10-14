# frozen_string_literal: true

require %(pangea/sandbox)

# Rspec.configure do |config|
#   config.before(:suite) do
#     puts 'Creating directories for test suite...'
#     Dir.mkdir('test_directory') unless File.exist?('test_directory')
#   end
#
#   config.after(:suite) do
#     puts 'Deleting directories after test suite...'
#     Dir.rmdir('test_directory') if File.exist?('test_directory')
#   end
# end

describe Sandbox do
  let(:sandbox) do
    Sandbox.new(
      base_dir: %(./spare/spec/sandbox)
    )
  end

  let(:sandbox_base_dir) { %(./spare/spec/sandbox) }

  context %(baseline) do
    it %(creates appropriate directories) do
      nil
    end
  end
end
