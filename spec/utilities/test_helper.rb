# spec/utilities/test_helper.rb
require 'spec_helper'
require 'pangea/utilities'

module UtilitiesTestHelper
  def create_test_workspace(template_name, namespace = 'test')
    workspace_path = File.expand_path("~/.pangea/workspaces/#{namespace}/#{template_name}")
    FileUtils.mkdir_p(workspace_path)
    
    # Create minimal state file
    state = {
      "version" => 4,
      "terraform_version" => "1.0.0",
      "serial" => 1,
      "lineage" => SecureRandom.uuid,
      "outputs" => {},
      "resources" => []
    }
    
    File.write(File.join(workspace_path, 'terraform.tfstate'), JSON.pretty_generate(state))
    workspace_path
  end
  
  def cleanup_test_workspaces
    test_workspace_dir = File.expand_path("~/.pangea/workspaces/test")
    FileUtils.rm_rf(test_workspace_dir) if Dir.exist?(test_workspace_dir)
  end
  
  def create_test_registry
    registry_dir = '.pangea/outputs'
    FileUtils.rm_rf(registry_dir) if Dir.exist?(registry_dir)
    FileUtils.mkdir_p(registry_dir)
  end
  
  def mock_terraform_plan_output(add: 0, change: 0, destroy: 0)
    output = []
    
    add.times { |i| output << "  + aws_instance.web_#{i}" }
    change.times { |i| output << "  ~ aws_vpc.main_#{i}" }
    destroy.times { |i| output << "  - aws_security_group.old_#{i}" }
    
    output.join("\n")
  end
end

RSpec.configure do |config|
  config.include UtilitiesTestHelper
  
  config.before(:suite) do
    # Setup test environment
  end
  
  config.after(:suite) do
    # Cleanup
  end
end