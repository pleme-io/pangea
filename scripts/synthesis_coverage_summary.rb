#!/usr/bin/env ruby
# Copyright 2025 The Pangea Authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


require 'json'

# Script to summarize synthesis test coverage for the 15 tested resources
class SynthesisCoverageSummary
  TESTED_RESOURCES = %w[
    aws_vpc
    aws_subnet
    aws_security_group
    aws_instance
    aws_internet_gateway
    aws_route_table
    aws_nat_gateway
    aws_launch_template
    aws_autoscaling_group
    aws_lb_target_group
    aws_lb
    aws_s3_bucket
    aws_iam_role
    aws_db_instance
    aws_eip
  ].freeze
  
  def run
    puts "=== Synthesis Coverage Summary for Tested Resources ==="
    puts
    
    analyze_coverage
    generate_enhancement_tasks
  end
  
  private
  
  def analyze_coverage
    puts "Resource Coverage Status:"
    puts "=" * 80
    
    total_resource_tests = 0
    total_synthesis_tests = 0
    missing_patterns = {}
    
    TESTED_RESOURCES.each do |resource|
      spec_dir = File.join(__dir__, '..', 'spec', 'resources', resource)
      
      if Dir.exist?(spec_dir)
        resource_spec = File.join(spec_dir, 'complete_resource_spec.rb')
        synthesis_spec = File.join(spec_dir, 'complete_synthesis_spec.rb')
        
        resource_tests = 0
        synthesis_tests = 0
        patterns = []
        
        if File.exist?(resource_spec)
          content = File.read(resource_spec)
          resource_tests = content.scan(/\bit\s+["']/).count
          total_resource_tests += resource_tests
        end
        
        if File.exist?(synthesis_spec)
          content = File.read(synthesis_spec)
          synthesis_tests = content.scan(/\bit\s+["']/).count
          total_synthesis_tests += synthesis_tests
          
          # Check for specific patterns
          missing = []
          missing << "tag synthesis" unless content.include?('synthesizes tags') || content.include?('synthesizes a') && content.include?('with tags')
          missing << "conditional attributes" unless content.include?('conditional attributes') || content.include?('handles conditional')
          missing << "complex scenarios" unless content.scan(/synthesizes\s+\w+\s+with/).count > 3
          
          missing_patterns[resource] = missing if missing.any?
        end
        
        status = if synthesis_tests >= 10
          "✅ GOOD"
        elsif synthesis_tests > 0
          "⚠️  LOW"
        else
          "❌ NONE"
        end
        
        puts "#{resource.ljust(25)} | Resource: #{resource_tests.to_s.rjust(2)} | Synthesis: #{synthesis_tests.to_s.rjust(2)} | #{status}"
      else
        puts "#{resource.ljust(25)} | ❌ No test directory"
      end
    end
    
    puts "=" * 80
    puts "Total Resource Tests: #{total_resource_tests}"
    puts "Total Synthesis Tests: #{total_synthesis_tests}"
    puts "Average Synthesis Tests per Resource: #{(total_synthesis_tests.to_f / TESTED_RESOURCES.size).round(1)}"
    
    if missing_patterns.any?
      puts "\nResources Missing Key Synthesis Patterns:"
      puts "=" * 80
      missing_patterns.each do |resource, patterns|
        puts "#{resource}: #{patterns.join(', ')}"
      end
    end
  end
  
  def generate_enhancement_tasks
    puts "\n=== Synthesis Enhancement Tasks ==="
    puts "=" * 80
    
    tasks = []
    
    # Task 1: Add missing tag synthesis tests
    needs_tag_tests = %w[
      aws_vpc
      aws_subnet
      aws_security_group
      aws_instance
      aws_internet_gateway
      aws_route_table
      aws_nat_gateway
      aws_launch_template
      aws_autoscaling_group
      aws_lb_target_group
      aws_lb
    ]
    
    tasks << {
      id: "SYNTH-ENHANCE-001",
      priority: "high",
      title: "Add tag synthesis tests for resources missing them",
      resources: needs_tag_tests,
      description: "Add explicit tag synthesis tests to ensure tag blocks are properly generated"
    }
    
    # Task 2: Add conditional attribute tests
    needs_conditional_tests = %w[
      aws_subnet
      aws_security_group
      aws_instance
      aws_internet_gateway
      aws_nat_gateway
      aws_route_table
    ]
    
    tasks << {
      id: "SYNTH-ENHANCE-002", 
      priority: "medium",
      title: "Add conditional attribute synthesis tests",
      resources: needs_conditional_tests,
      description: "Test that optional attributes are only synthesized when present"
    }
    
    # Task 3: Increase synthesis coverage for low-coverage resources
    low_coverage = %w[
      aws_vpc
      aws_subnet
      aws_security_group
      aws_instance
      aws_internet_gateway
    ]
    
    tasks << {
      id: "SYNTH-ENHANCE-003",
      priority: "medium", 
      title: "Increase synthesis test coverage to 10+ tests",
      resources: low_coverage,
      description: "Add more synthesis scenarios to reach minimum 10 tests per resource"
    }
    
    # Task 4: Add complex synthesis scenarios
    needs_complex = %w[
      aws_vpc
      aws_subnet
      aws_security_group
      aws_route_table
      aws_nat_gateway
    ]
    
    tasks << {
      id: "SYNTH-ENHANCE-004",
      priority: "low",
      title: "Add complex synthesis scenarios",
      resources: needs_complex,
      description: "Add tests for resources with multiple complex attributes set"
    }
    
    # Task 5: Add cross-reference synthesis tests
    tasks << {
      id: "SYNTH-ENHANCE-005",
      priority: "low",
      title: "Add cross-reference synthesis tests",
      resources: ["all"],
      description: "Test synthesis with terraform variable and resource references"
    }
    
    # Print tasks
    tasks.each do |task|
      puts "\n#{task[:id]} - #{task[:title]} [#{task[:priority].upcase}]"
      puts "-" * 60
      puts "Description: #{task[:description]}"
      puts "Resources: #{task[:resources].join(', ')}"
    end
    
    # Export tasks to JSON
    export_tasks(tasks)
  end
  
  def export_tasks(tasks)
    report_file = File.join(__dir__, 'synthesis_enhancement_tasks.json')
    
    task_data = {
      generated_at: Time.now.utc.strftime('%Y-%m-%dT%H:%M:%SZ'),
      total_tasks: tasks.size,
      tasks: tasks
    }
    
    File.write(report_file, JSON.pretty_generate(task_data))
    puts "\n\n💾 Enhancement tasks saved to: #{report_file}"
  end
end

# Run the summary
SynthesisCoverageSummary.new.run