#!/usr/bin/env ruby

class UtilitiesVerifier
  def initialize
    @results = []
  end
  
  def verify_all
    puts "Pangea Utilities Implementation Verification"
    puts "=" * 50
    
    verify_foundation
    verify_remote_state
    verify_drift_detection
    verify_cost_analysis
    verify_visualization
    verify_cli_commands
    
    print_summary
  end
  
  private
  
  def verify_foundation
    puts "\nPhase 1: Foundation"
    
    check_directory_structure
    check_module_loading
  end
  
  def verify_remote_state
    puts "\nPhase 2: Remote State"
    
    check_class_exists("Pangea::Utilities::RemoteState::Reference")
    check_class_exists("Pangea::Utilities::RemoteState::DependencyManager")
    check_class_exists("Pangea::Utilities::RemoteState::OutputRegistry")
    
    check_functionality("Remote State Reference") do
      ref = Pangea::Utilities::RemoteState.reference('test', 'network', 'vpc_id')
      ref.reference_string == '${data.terraform_remote_state.network_state.outputs.vpc_id}'
    end
  end
  
  def verify_drift_detection
    puts "\nPhase 3: Drift Detection"
    
    check_class_exists("Pangea::Utilities::Drift::Detector")
    check_class_exists("Pangea::Utilities::Drift::Report")
    
    check_functionality("Drift Report") do
      report = Pangea::Utilities::Drift::Report.new('test', :drift_detected, {})
      report.drift_detected?
    end
  end
  
  def verify_cost_analysis
    puts "\nPhase 4: Cost Analysis"
    
    check_class_exists("Pangea::Utilities::Cost::Calculator")
    check_class_exists("Pangea::Utilities::Cost::ResourcePricing")
    
    check_functionality("Resource Pricing") do
      price = Pangea::Utilities::Cost::ResourcePricing.get_price('aws_instance', {instance_type: 't3.micro'})
      price[:hourly] == 0.0104
    end
  end
  
  def verify_visualization
    puts "\nPhase 5: Visualization"
    
    check_class_exists("Pangea::Utilities::Visualization::Graph")
    check_class_exists("Pangea::Utilities::Visualization::MermaidExporter")
    
    check_functionality("Graph Creation") do
      graph = Pangea::Utilities::Visualization::Graph.new
      graph.add_node('test')
      graph.nodes.key?('test')
    end
  end
  
  def verify_cli_commands
    puts "\nPhase 6: CLI Commands"
    
    check_file_exists("lib/pangea/utilities/cli/command.rb")
    check_file_exists("lib/pangea/utilities/cli/commands/state_command.rb")
    check_file_exists("lib/pangea/utilities/cli/commands/drift_command.rb")
    check_file_exists("lib/pangea/utilities/cli/commands/cost_command.rb")
  end
  
  def check_directory_structure
    expected_dirs = %w[
      remote_state drift cost visualization analysis
      validation backup migration monitoring cli/commands
    ]
    
    expected_dirs.each do |dir|
      path = "lib/pangea/utilities/#{dir}"
      if Dir.exist?(path)
        success "Directory exists: #{dir}"
      else
        error "Missing directory: #{dir}"
      end
    end
  end
  
  def check_module_loading
    begin
      require 'pangea/utilities'
      success "Utilities module loads successfully"
    rescue => e
      error "Failed to load utilities: #{e.message}"
    end
  end
  
  def check_class_exists(class_name)
    klass = class_name.split('::').inject(Object) { |o, c| o.const_get(c) }
    success "#{class_name} exists"
    @results << { status: :pass }
  rescue => e
    error "#{class_name} missing: #{e.message}"
    @results << { status: :fail }
  end
  
  def check_file_exists(path)
    if File.exist?(path)
      success "File exists: #{path}"
      @results << { status: :pass }
    else
      error "Missing file: #{path}"
      @results << { status: :fail }
    end
  end
  
  def check_functionality(name)
    result = yield
    if result
      success "#{name} works correctly"
      @results << { status: :pass }
    else
      error "#{name} failed"
      @results << { status: :fail }
    end
  rescue => e
    error "#{name} error: #{e.message}"
    @results << { status: :fail }
  end
  
  def success(message)
    puts "  ✓ #{message}"
  end
  
  def error(message)
    puts "  ✗ #{message}"
  end
  
  def print_summary
    puts "\n" + "=" * 50
    passed = @results.count { |r| r[:status] == :pass }
    failed = @results.count { |r| r[:status] == :fail }
    
    puts "Summary: #{passed} passed, #{failed} failed"
  end
end

# Change to Pangea directory before running
Dir.chdir(File.expand_path('..', __dir__))

# Load the library path
$LOAD_PATH.unshift(File.expand_path('lib', Dir.pwd))

UtilitiesVerifier.new.verify_all