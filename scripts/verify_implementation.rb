#!/usr/bin/env ruby

# Mock colorize if not available
class String
  def colorize(color)
    self
  end
end

class ImplementationVerifier
  def initialize
    @results = []
  end
  
  def verify_all
    puts "Pangea Implementation Verification".colorize(:blue)
    puts "=" * 50
    
    verify_phase_1_types
    verify_phase_2_resources
    verify_phase_3_testing
    verify_phase_4_components
    verify_phase_5_errors
    verify_phase_6_documentation
    
    print_summary
  end
  
  private
  
  def verify_phase_1_types
    puts "\nPhase 1: Type System".colorize(:yellow)
    
    check_file_exists("lib/pangea/types.rb")
    check_file_exists("lib/pangea/types/registry.rb")
    check_file_exists("lib/pangea/types/base_types.rb")
    check_file_exists("lib/pangea/types/aws_types.rb")
    
    check_code_works(
      "Type Registry",
      "require './lib/pangea/types'; Pangea::Types[:cidr_block]"
    )
  end
  
  def verify_phase_2_resources
    puts "\nPhase 2: Resource Standardization".colorize(:yellow)
    
    check_file_exists("lib/pangea/resources/templates/resource_template.rb.erb")
    check_file_exists("lib/pangea/generators/resource_generator.rb")
    check_file_exists("lib/pangea/quality/resource_auditor.rb")
    check_file_exists("audit_results/vpc_resources_audit.json")
  end
  
  def verify_phase_3_testing
    puts "\nPhase 3: Testing Framework".colorize(:yellow)
    
    check_file_exists("spec/support/test_data_registry.rb")
    check_file_exists("lib/pangea/generators/test_generator.rb")
    check_file_exists("spec/templates/resource_spec.rb.erb")
    check_file_exists("spec/templates/synthesis_spec.rb.erb")
    check_file_exists("spec/templates/integration_spec.rb.erb")
  end
  
  def verify_phase_4_components
    puts "\nPhase 4: Component Standardization".colorize(:yellow)
    
    check_file_exists("lib/pangea/components/base.rb")
    check_file_exists("lib/pangea/components/capabilities.rb")
    
    check_code_works(
      "Component Base Class",
      "require './lib/pangea/components/base'; Pangea::Components::Base"
    )
  end
  
  def verify_phase_5_errors
    puts "\nPhase 5: Error Standardization".colorize(:yellow)
    
    check_file_exists("lib/pangea/errors.rb")
    check_file_exists("lib/pangea/validation.rb")
    
    check_code_works(
      "Error Messages",
      "require './lib/pangea/errors'; Pangea::Errors::ValidationError.missing_required('test', 'attr')"
    )
  end
  
  def verify_phase_6_documentation
    puts "\nPhase 6: Documentation".colorize(:yellow)
    
    check_file_exists("lib/pangea/documentation/generator.rb")
    check_file_exists("lib/pangea/documentation/writer.rb")
  end
  
  def check_file_exists(path)
    if File.exist?(path)
      @results << { status: :pass, message: "File exists: #{path}" }
      puts "  ✓ #{path}".colorize(:green)
    else
      @results << { status: :fail, message: "Missing file: #{path}" }
      puts "  ✗ #{path}".colorize(:red)
    end
  end
  
  def check_code_works(name, code)
    begin
      eval(code)
      @results << { status: :pass, message: "#{name} works" }
      puts "  ✓ #{name}".colorize(:green)
    rescue => e
      @results << { status: :fail, message: "#{name} failed: #{e.message}" }
      puts "  ✗ #{name}: #{e.message}".colorize(:red)
    end
  end
  
  def print_summary
    puts "\n" + "=" * 50
    passed = @results.count { |r| r[:status] == :pass }
    failed = @results.count { |r| r[:status] == :fail }
    
    puts "Summary: #{passed} passed, #{failed} failed".colorize(failed > 0 ? :red : :green)
    
    if failed > 0
      puts "\nFailed checks:".colorize(:red)
      @results.select { |r| r[:status] == :fail }.each do |result|
        puts "  - #{result[:message]}"
      end
    end
  end
end

 ImplementationVerifier.new.verify_all