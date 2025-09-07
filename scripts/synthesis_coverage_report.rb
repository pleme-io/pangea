#!/usr/bin/env ruby

require 'find'
require 'json'

# Simple color output without external dependencies
class String
  def colorize(color)
    colors = {
      red: 31,
      green: 32,
      yellow: 33,
      blue: 34,
      magenta: 35,
      cyan: 36,
      light_blue: 94
    }
    "\e[#{colors[color] || 0}m#{self}\e[0m"
  end
end

# Script to analyze synthesis test coverage for all resources
class SynthesisCoverageAnalyzer
  RESOURCE_DIR = File.join(__dir__, '..', 'lib', 'pangea', 'resources')
  SPEC_DIR = File.join(__dir__, '..', 'spec', 'resources')
  
  def initialize
    @resources = {}
    @coverage_report = {}
  end
  
  def run
    puts "=== Pangea Synthesis Test Coverage Report ===".colorize(:yellow)
    puts
    
    discover_resources
    analyze_coverage
    generate_report
  end
  
  private
  
  def discover_resources
    Dir.glob(File.join(RESOURCE_DIR, 'aws_*')).each do |resource_path|
      next unless File.directory?(resource_path)
      
      resource_name = File.basename(resource_path)
      resource_file = File.join(resource_path, 'resource.rb')
      
      # Only consider directories that have a resource.rb file with actual implementation
      next unless File.exist?(resource_file)
      
      # Check if the resource.rb file contains an actual function definition
      content = File.read(resource_file)
      next unless content.include?("def #{resource_name}(")
      
      @resources[resource_name] = {
        path: resource_path,
        resource_file: resource_file,
        has_types: File.exist?(File.join(resource_path, 'types.rb')),
        has_docs: File.exist?(File.join(resource_path, 'CLAUDE.md'))
      }
    end
    
    puts "Found #{@resources.size} implemented resources to analyze".colorize(:green)
  end
  
  def analyze_coverage
    @resources.each do |resource_name, info|
      spec_dir = File.join(SPEC_DIR, resource_name)
      
      @coverage_report[resource_name] = {
        has_spec_dir: Dir.exist?(spec_dir),
        resource_spec: nil,
        synthesis_spec: nil,
        total_tests: 0,
        synthesis_tests: 0,
        synthesis_coverage: []
      }
      
      if Dir.exist?(spec_dir)
        # Check for resource spec
        resource_spec_file = File.join(spec_dir, 'complete_resource_spec.rb')
        if File.exist?(resource_spec_file)
          @coverage_report[resource_name][:resource_spec] = analyze_spec_file(resource_spec_file)
        end
        
        # Check for synthesis spec
        synthesis_spec_file = File.join(spec_dir, 'complete_synthesis_spec.rb')
        if File.exist?(synthesis_spec_file)
          @coverage_report[resource_name][:synthesis_spec] = analyze_synthesis_spec(synthesis_spec_file)
          @coverage_report[resource_name][:synthesis_tests] = @coverage_report[resource_name][:synthesis_spec][:test_count]
          @coverage_report[resource_name][:synthesis_coverage] = extract_synthesis_coverage(synthesis_spec_file)
        end
        
        # Total test count
        @coverage_report[resource_name][:total_tests] = 
          (@coverage_report[resource_name][:resource_spec]&.dig(:test_count) || 0) +
          (@coverage_report[resource_name][:synthesis_spec]&.dig(:test_count) || 0)
      end
    end
  end
  
  def analyze_spec_file(file_path)
    content = File.read(file_path)
    
    {
      test_count: content.scan(/\bit\s+["']/).count,
      describe_blocks: content.scan(/describe\s+["']/).count,
      file_size: File.size(file_path)
    }
  end
  
  def analyze_synthesis_spec(file_path)
    content = File.read(file_path)
    
    # Look for specific synthesis patterns
    synthesis_patterns = {
      basic_synthesis: content.include?('synthesizes basic') || content.include?('synthesizes minimal'),
      tag_synthesis: content.include?('synthesizes tags'),
      conditional_synthesis: content.include?('conditional attributes') || content.include?('handles conditional'),
      output_validation: content.include?('terraform reference outputs') || content.include?('validates terraform'),
      complex_synthesis: content.scan(/synthesizes\s+\w+\s+with/).count,
      mock_synthesizer: content.include?('mock_synthesizer') || content.include?('MockSynthesizer')
    }
    
    {
      test_count: content.scan(/\bit\s+["']/).count,
      describe_blocks: content.scan(/describe\s+["']/).count,
      file_size: File.size(file_path),
      patterns: synthesis_patterns
    }
  end
  
  def extract_synthesis_coverage(file_path)
    content = File.read(file_path)
    coverage = []
    
    # Extract test descriptions
    content.scan(/it\s+["']([^"']+)["']/) do |match|
      test_name = match[0]
      if test_name.downcase.include?('synthesis') || test_name.downcase.include?('terraform')
        coverage << test_name
      end
    end
    
    coverage
  end
  
  def generate_report
    puts "\n=== Coverage Summary ===".colorize(:yellow)
    
    # Sort resources by name
    sorted_resources = @coverage_report.sort_by { |name, _| name }
    
    # Summary stats
    total_resources = @resources.size
    resources_with_tests = @coverage_report.count { |_, data| data[:has_spec_dir] }
    resources_with_synthesis = @coverage_report.count { |_, data| data[:synthesis_tests] > 0 }
    total_tests = @coverage_report.sum { |_, data| data[:total_tests] }
    total_synthesis_tests = @coverage_report.sum { |_, data| data[:synthesis_tests] }
    
    puts "Total Resources: #{total_resources}".colorize(:blue)
    puts "Resources with Tests: #{resources_with_tests} (#{(resources_with_tests.to_f / total_resources * 100).round(1)}%)".colorize(:green)
    puts "Resources with Synthesis Tests: #{resources_with_synthesis} (#{(resources_with_synthesis.to_f / total_resources * 100).round(1)}%)".colorize(:green)
    puts "Total Tests: #{total_tests}".colorize(:blue)
    puts "Total Synthesis Tests: #{total_synthesis_tests}".colorize(:blue)
    
    puts "\n=== Detailed Resource Coverage ===".colorize(:yellow)
    
    sorted_resources.each do |resource_name, data|
      puts "\n#{resource_name}:".colorize(:cyan)
      
      if !data[:has_spec_dir]
        puts "  ❌ No test directory found".colorize(:red)
      else
        if data[:resource_spec]
          puts "  ✅ Resource tests: #{data[:resource_spec][:test_count]} tests".colorize(:green)
        else
          puts "  ❌ No resource tests found".colorize(:red)
        end
        
        if data[:synthesis_spec]
          puts "  ✅ Synthesis tests: #{data[:synthesis_tests]} tests".colorize(:green)
          
          # Show synthesis patterns
          patterns = data[:synthesis_spec][:patterns]
          puts "    Synthesis coverage:".colorize(:light_blue)
          puts "      #{patterns[:basic_synthesis] ? '✓' : '✗'} Basic synthesis".colorize(patterns[:basic_synthesis] ? :green : :red)
          puts "      #{patterns[:tag_synthesis] ? '✓' : '✗'} Tag synthesis".colorize(patterns[:tag_synthesis] ? :green : :red)
          puts "      #{patterns[:conditional_synthesis] ? '✓' : '✗'} Conditional attributes".colorize(patterns[:conditional_synthesis] ? :green : :red)
          puts "      #{patterns[:output_validation] ? '✓' : '✗'} Output validation".colorize(patterns[:output_validation] ? :green : :red)
          puts "      #{patterns[:mock_synthesizer] ? '✓' : '✗'} Mock synthesizer usage".colorize(patterns[:mock_synthesizer] ? :green : :red)
          
          if patterns[:complex_synthesis] > 0
            puts "      ✓ Complex synthesis tests: #{patterns[:complex_synthesis]}".colorize(:green)
          end
        else
          puts "  ❌ No synthesis tests found".colorize(:red)
        end
        
        puts "  Total: #{data[:total_tests]} tests"
      end
    end
    
    # Recommendations
    puts "\n=== Recommendations ===".colorize(:yellow)
    
    missing_synthesis = sorted_resources.select { |_, data| data[:has_spec_dir] && data[:synthesis_tests] == 0 }
    if missing_synthesis.any?
      puts "\nResources missing synthesis tests:".colorize(:red)
      missing_synthesis.each do |name, _|
        puts "  - #{name}"
      end
    end
    
    low_synthesis_coverage = sorted_resources.select do |_, data| 
      data[:synthesis_tests] > 0 && data[:synthesis_tests] < 10
    end
    
    if low_synthesis_coverage.any?
      puts "\nResources with low synthesis test coverage (<10 tests):".colorize(:yellow)
      low_synthesis_coverage.each do |name, data|
        puts "  - #{name}: #{data[:synthesis_tests]} tests"
      end
    end
    
    # Missing critical patterns
    puts "\nResources missing critical synthesis patterns:".colorize(:yellow)
    sorted_resources.each do |name, data|
      next unless data[:synthesis_spec]
      
      patterns = data[:synthesis_spec][:patterns]
      missing = []
      
      missing << "basic synthesis" unless patterns[:basic_synthesis]
      missing << "tag synthesis" unless patterns[:tag_synthesis]
      missing << "output validation" unless patterns[:output_validation]
      
      if missing.any?
        puts "  - #{name}: missing #{missing.join(', ')}"
      end
    end
    
    # Export detailed report
    export_json_report
  end
  
  def export_json_report
    report_file = File.join(__dir__, 'synthesis_coverage_report.json')
    
    report_data = {
      generated_at: Time.now.utc.strftime('%Y-%m-%dT%H:%M:%SZ'),
      summary: {
        total_resources: @resources.size,
        resources_with_tests: @coverage_report.count { |_, data| data[:has_spec_dir] },
        resources_with_synthesis: @coverage_report.count { |_, data| data[:synthesis_tests] > 0 },
        total_tests: @coverage_report.sum { |_, data| data[:total_tests] },
        total_synthesis_tests: @coverage_report.sum { |_, data| data[:synthesis_tests] }
      },
      resources: @coverage_report
    }
    
    File.write(report_file, JSON.pretty_generate(report_data))
    puts "\n💾 Detailed report saved to: #{report_file}".colorize(:green)
  end
end

# Run the analyzer
SynthesisCoverageAnalyzer.new.run